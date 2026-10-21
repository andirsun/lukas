import { readFileSync } from "node:fs";
import { accounts, type Tx, transactions, withUser } from "@lukas/db";
import { eq } from "@lukas/db/orm";
import { afterAll, beforeAll, describe, expect, test, vi } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

const FIXTURE = readFileSync(
  new URL("../../../packages/importers/test/fixtures/budge-sample.csv", import.meta.url),
  "utf8",
);
const lines = FIXTURE.split("\r\n");
const header = lines.findIndex((l) => l.startsWith("Date,Payment"));
/** First 10 transaction rows of the fixture plus 2 new ones: an overlapping export. */
const OVERLAP = [
  ...lines.slice(0, header + 11),
  "01-11-2026,new thing,true,-10,EUR,main,Ocio,,,",
  "02-11-2026,another,true,-20,EUR,main,Casa,,,",
].join("\r\n");

let t: TestApp;
let a: { authorization: string };
let b: { authorization: string };

interface Preview {
  id: string;
  status: string;
  stats: {
    transactions: number;
    duplicates: number;
    newCategories: string[];
    rejected: { line: number; reason: string }[];
    from: string;
    to: string;
    averageMonthlySpending: { category: string; amount: number }[];
    currency: string | null;
  };
}

const upload = (headers: object, text: string, name = "budge.csv") => {
  const form = new FormData();
  form.append("source", "budge");
  form.append("file", new File([text], name, { type: "text/csv" }));
  return t.request("POST", "/v1/imports", {
    headers: headers as Record<string, string>,
    body: form,
  });
};
const countTransactions = async (headers = a) => {
  let total = 0;
  let cursor: string | null = null;
  do {
    const res = await t.request(
      "GET",
      `/v1/transactions?limit=200${cursor ? `&cursor=${cursor}` : ""}`,
      { headers },
    );
    const page = (await res.json()) as {
      items: { name: string; status: string }[];
      nextCursor: string | null;
    };
    total += page.items.length;
    cursor = page.nextCursor;
  } while (cursor);
  return total;
};

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  b = (await t.signIn("b@lukas.test")).headers;
  // A category the user created by hand must be reused, not duplicated.
  await t.request("POST", "/v1/categories", {
    headers: a,
    body: { name: "ocio", kind: "expense", icon: "star", color: "purple" },
  });
});
afterAll(() => t?.stop());

describe("Budge import", () => {
  let first: Preview;

  test("preview reports what will be imported without writing transactions", async () => {
    const res = await upload(a, FIXTURE);
    expect(res.status).toBe(201);
    first = (await res.json()) as Preview;
    expect(first.status).toBe("preview");
    expect(first.stats).toMatchObject({
      transactions: 22,
      duplicates: 0,
      from: "2026-09-01",
      to: "2026-10-30",
    });
    expect(first.stats.rejected).toEqual([{ line: 19, reason: "invalid_date" }]);
    expect(first.stats.newCategories).toContain("Salário");
    expect(first.stats.newCategories).not.toContain("Ocio");
    expect(await countTransactions()).toBe(0);
  });

  test("other users cannot confirm someone else's import", async () => {
    expect(
      (await t.request("POST", `/v1/imports/${first.id}/confirm`, { headers: b })).status,
    ).toBe(404);
  });

  test("confirm creates categories and transactions", async () => {
    const res = await t.request("POST", `/v1/imports/${first.id}/confirm`, { headers: a });
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ status: "confirmed", stats: { inserted: 22 } });
    expect(await countTransactions()).toBe(22);
    const cats = (await (await t.request("GET", "/v1/categories", { headers: a })).json()) as {
      name: string;
      kind: string;
      icon: string;
    }[];
    expect(cats.filter((c) => c.name.toLowerCase() === "ocio")).toHaveLength(1);
    expect(cats.find((c) => c.name === "Salário")).toMatchObject({
      kind: "income",
      icon: "salary",
    });
    const pending = (await (
      await t.request("GET", "/v1/transactions?status=pending", { headers: a })
    ).json()) as {
      items: unknown[];
    };
    expect(pending.items).toHaveLength(2);
  });

  test("confirming twice is a conflict", async () => {
    const res = await t.request("POST", `/v1/imports/${first.id}/confirm`, { headers: a });
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "import_not_in_preview" });
  });

  test("the same file cannot be imported twice", async () => {
    const res = await upload(a, FIXTURE);
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "import_duplicate_file" });
  });

  let second: Preview;
  test("an overlapping export only adds the new rows", async () => {
    second = (await (await upload(a, OVERLAP)).json()) as Preview;
    expect(second.stats).toMatchObject({ transactions: 12, duplicates: 10 });
    const confirm = await t.request("POST", `/v1/imports/${second.id}/confirm`, { headers: a });
    expect(await confirm.json()).toMatchObject({ stats: { inserted: 2 } });
    expect(await countTransactions()).toBe(24);
  });

  test("revert removes only that import's transactions", async () => {
    const res = await t.request("DELETE", `/v1/imports/${first.id}`, { headers: a });
    expect(res.status).toBe(204);
    expect(await countTransactions()).toBe(2);
  });

  test("files that are not Budge exports are rejected", async () => {
    const res = await upload(a, "hello");
    expect(res.status).toBe(422);
    expect(await res.json()).toMatchObject({ code: "import_unrecognized_format" });
  });

  test("rows in another currency are rejected in the preview", async () => {
    const usd = FIXTURE.replace(
      "02-09-2026,groceries ,true,-30.70,EUR",
      "02-09-2026,groceries ,true,-30.70,USD",
    );
    const preview = (await (await upload(b, usd)).json()) as Preview;
    expect(preview.stats.rejected).toContainEqual({ line: 8, reason: "currency_mismatch" });
    expect(preview.stats.transactions).toBe(21);
  });
});

describe("the file's currency", () => {
  let c: { authorization: string };
  beforeAll(async () => {
    c = (await t.signIn("c@lukas.test")).headers;
  });
  const setCurrency = (currency: string) =>
    t.request("PATCH", "/v1/me", { headers: c, body: { currency } });

  test("the preview reports it, even when the account uses another one", async () => {
    expect((await setCurrency("COP")).status).toBe(200);
    const preview = (await (await upload(c, FIXTURE)).json()) as Preview;
    expect(preview.stats.currency).toBe("EUR");
    expect(preview.stats.transactions).toBe(0);
    expect(preview.stats.rejected).toContainEqual({ line: 7, reason: "currency_mismatch" });
  });

  test("a preview read before the account's currency changed cannot be confirmed", async () => {
    expect((await setCurrency("EUR")).status).toBe(200);
    const stale = (await (await upload(c, FIXTURE)).json()) as Preview;
    expect(stale.stats).toMatchObject({ currency: "EUR", transactions: 22 });
    expect((await setCurrency("COP")).status).toBe(200);
    const res = await t.request("POST", `/v1/imports/${stale.id}/confirm`, { headers: c });
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "import_currency_changed" });
    expect(await countTransactions(c)).toBe(0);
  });

  test("switching to the file's currency and reading it again imports it", async () => {
    expect((await setCurrency("EUR")).status).toBe(200);
    const fresh = (await (await upload(c, FIXTURE)).json()) as Preview;
    const res = await t.request("POST", `/v1/imports/${fresh.id}/confirm`, { headers: c });
    expect(res.status).toBe(200);
    expect(await countTransactions(c)).toBe(22);
  });
});

/**
 * Writing transactions in the account's currency and changing that currency must serialize: the
 * import confirm and the currency PATCH both take the default account's row lock. Each test holds
 * that lock in one transaction (as the other side would) while the request runs in parallel.
 */
describe("import confirm and currency change race", () => {
  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
  const lockAccount = (tx: Tx) =>
    tx.select().from(accounts).where(eq(accounts.isDefault, true)).for("update");
  const settledFlag = (promise: Promise<unknown>) => {
    const state = { settled: false };
    void promise.finally(() => {
      state.settled = true;
    });
    return state;
  };
  const currencies = async (headers: { authorization: string }) => {
    const res = await t.request("GET", "/v1/transactions?limit=200", { headers });
    const page = (await res.json()) as { items: { currency: string }[] };
    return new Set(page.items.map((i) => i.currency));
  };

  test("a currency change waits for an import in flight, then finds the account locked", async () => {
    const { userId, headers } = await t.signIn("race-patch@lukas.test");
    const category = (await (
      await t.request("POST", "/v1/categories", {
        headers,
        body: { name: "Ocio", kind: "expense", icon: "⭐", color: "#a66bff" },
      })
    ).json()) as { id: string };
    let patch: Promise<Response> | undefined;
    await withUser(t.db, userId, async (tx) => {
      // The confirm's side: lock, then insert in the account's currency.
      const [account] = await lockAccount(tx);
      patch = t.request("PATCH", "/v1/me", { headers, body: { currency: "COP" } });
      const flag = settledFlag(patch);
      await sleep(300);
      expect(flag.settled).toBe(false);
      await tx.insert(transactions).values({
        userId,
        accountId: account?.id as string,
        categoryId: category.id,
        name: "cinema",
        amount: -950,
        currency: account?.currency as string,
        date: "2026-10-05",
        source: "import",
      });
    });
    const res = await (patch as Promise<Response>);
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "currency_locked" });
    const me = (await (await t.request("GET", "/v1/me", { headers })).json()) as {
      currency: string;
    };
    expect(me.currency).toBe("EUR");
    expect(await currencies(headers)).toEqual(new Set(["EUR"]));
  });

  test("an import confirm waits for a currency change in flight, then refuses the stale preview", async () => {
    const { userId, headers } = await t.signIn("race-confirm@lukas.test");
    const preview = (await (await upload(headers, FIXTURE)).json()) as Preview;
    let confirm: Promise<Response> | undefined;
    await withUser(t.db, userId, async (tx) => {
      // The PATCH's side: lock, then switch the (still empty) account to COP.
      await lockAccount(tx);
      confirm = t.request("POST", `/v1/imports/${preview.id}/confirm`, { headers });
      const flag = settledFlag(confirm);
      await sleep(300);
      expect(flag.settled).toBe(false);
      await tx.update(accounts).set({ currency: "COP" }).where(eq(accounts.isDefault, true));
    });
    const res = await (confirm as Promise<Response>);
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "import_currency_changed" });
    expect(await countTransactions(headers)).toBe(0);
  });

  test("fired together, either the import or the currency change wins, never both", async () => {
    for (let i = 0; i < 4; i++) {
      const { headers } = await t.signIn(`race-both-${i}@lukas.test`);
      const preview = (await (await upload(headers, FIXTURE)).json()) as Preview;
      const [confirm, patch] = await Promise.all([
        t.request("POST", `/v1/imports/${preview.id}/confirm`, { headers }),
        t.request("PATCH", "/v1/me", { headers, body: { currency: "COP" } }),
      ]);
      const me = (await (await t.request("GET", "/v1/me", { headers })).json()) as {
        currency: string;
      };
      const seen = await currencies(headers);
      if (confirm.status === 200) {
        expect(patch.status).toBe(409);
        expect(me.currency).toBe("EUR");
        expect(seen).toEqual(new Set(["EUR"]));
      } else {
        expect(confirm.status).toBe(409);
        expect(patch.status).toBe(200);
        expect(me.currency).toBe("COP");
        expect(seen.size).toBe(0);
      }
    }
  });
});

describe("the preview's monthly averages", () => {
  /** A new user signed in at `now` (sessions and codes follow the faked clock), and their preview. */
  async function previewAt(now: string, email: string) {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date(now));
    try {
      const { headers } = await t.signIn(email);
      return ((await (await upload(headers, FIXTURE)).json()) as Preview).stats
        .averageMonthlySpending;
    } finally {
      vi.useRealTimers();
    }
  }
  const amountOf = (averages: { category: string; amount: number }[], category: string) =>
    averages.find((a) => a.category === category)?.amount;

  test("cover the last 3 complete months, not the file's whole span", async () => {
    // In November the sample's September and October count, plus an empty August: over 3.
    const averages = await previewAt("2026-11-15T12:00:00Z", "avg-nov@lukas.test");
    // Ocio: 9,50 − 5 (a refund) + 120 = 124,50 € over 3 months.
    expect(averages[0]).toEqual({ category: "Ocio", amount: 4150 });
    expect(amountOf(averages, "Restaurante")).toBe(1660);
    expect(amountOf(averages, "Salário")).toBeUndefined();
  });

  test("leave out the month still running", async () => {
    // On 21 October: July to September. The 120 € flight in October doesn't count yet.
    const averages = await previewAt("2026-10-21T12:00:00Z", "avg-oct@lukas.test");
    expect(amountOf(averages, "Ocio")).toBe(150);
    expect(amountOf(averages, "Taxes")).toBeUndefined();
  });
});
