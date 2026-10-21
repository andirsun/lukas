import { readFileSync } from "node:fs";
import { accounts, imports, type Tx, transactions, withUser } from "@lukas/db";
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
    averageWindow?: { from: string; to: string; months: number } | null;
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

  test("the preview reports it; an empty account's preview counts the file's rows in it", async () => {
    expect((await setCurrency("COP")).status).toBe(200);
    const preview = (await (await upload(c, FIXTURE)).json()) as Preview & {
      stats: { adoptsCurrency: boolean };
    };
    expect(preview.stats).toMatchObject({
      currency: "EUR",
      transactions: 22,
      adoptsCurrency: true,
    });
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
      return ((await (await upload(headers, FIXTURE)).json()) as Preview).stats;
    } finally {
      vi.useRealTimers();
    }
  }
  const amountOf = (averages: { category: string; amount: number }[], category: string) =>
    averages.find((a) => a.category === category)?.amount;

  test("cover the last complete months the file has, up to 3", async () => {
    // In November the window would be Aug–Oct; the sample starts in September, so Sep–Oct, over 2.
    const stats = await previewAt("2026-11-15T12:00:00Z", "avg-nov@lukas.test");
    expect(stats.averageWindow).toEqual({ from: "2026-09", to: "2026-10", months: 2 });
    const averages = stats.averageMonthlySpending;
    // Ocio: 9,50 − 5 (a refund) + 120 = 124,50 € over 2 months.
    expect(averages[0]).toEqual({ category: "Ocio", amount: 6225 });
    expect(amountOf(averages, "Restaurante")).toBe(2490);
    expect(amountOf(averages, "Salário")).toBeUndefined();
  });

  test("leave out the month still running", async () => {
    // On 21 October only September is complete. The 120 € flight in October doesn't count yet.
    const stats = await previewAt("2026-10-21T12:00:00Z", "avg-oct@lukas.test");
    expect(stats.averageWindow).toEqual({ from: "2026-09", to: "2026-09", months: 1 });
    expect(amountOf(stats.averageMonthlySpending, "Ocio")).toBe(450);
    expect(amountOf(stats.averageMonthlySpending, "Taxes")).toBeUndefined();
  });
});

describe("two confirms of the same preview at once", () => {
  test("the second finds it confirmed and changes nothing", async () => {
    const { userId, headers } = await t.signIn("double-confirm@lukas.test");
    const preview = (await (await upload(headers, FIXTURE)).json()) as Preview;
    let both: Promise<Response[]> | undefined;
    await withUser(t.db, userId, async (tx) => {
      // Both requests start while the account is locked, so both read the preview before the lock.
      await tx.select().from(accounts).where(eq(accounts.isDefault, true)).for("update");
      both = Promise.all([
        t.request("POST", `/v1/imports/${preview.id}/confirm`, { headers }),
        t.request("POST", `/v1/imports/${preview.id}/confirm`, { headers }),
      ]);
      await new Promise((resolve) => setTimeout(resolve, 300));
    });
    const results = await (both as Promise<Response[]>);
    const statuses = results.map((r) => r.status).sort();
    expect(statuses).toEqual([200, 409]);
    const won = results.find((r) => r.status === 200) as Response;
    expect(await won.json()).toMatchObject({ stats: { inserted: 22 } });
    const lost = results.find((r) => r.status === 409) as Response;
    expect(await lost.json()).toMatchObject({ code: "import_not_in_preview" });
    const [row] = await withUser(t.db, userId, (tx) =>
      tx.select().from(imports).where(eq(imports.id, preview.id)),
    );
    expect((row?.stats as { inserted?: number }).inserted).toBe(22);
    expect(await countTransactions(headers)).toBe(22);
  });
});

describe("archived categories on import", () => {
  const categoriesOf = async (headers: { authorization: string }) =>
    (await (await t.request("GET", "/v1/categories?includeArchived=true", { headers })).json()) as {
      id: string;
      name: string;
      archived: boolean;
    }[];
  const create = async (headers: { authorization: string }, name: string) =>
    (
      (await (
        await t.request("POST", "/v1/categories", {
          headers,
          body: { name, kind: "expense", icon: "⭐", color: "#a66bff" },
        })
      ).json()) as { id: string }
    ).id;
  const archive = (headers: { authorization: string }, id: string) =>
    t.request("PATCH", `/v1/categories/${id}`, { headers, body: { archived: true } });
  const rowsIn = async (headers: { authorization: string }, categoryId: string) =>
    (
      (await (
        await t.request("GET", `/v1/transactions?category=${categoryId}&limit=200`, { headers })
      ).json()) as { items: unknown[] }
    ).items.length;

  test("a category that exists only archived is brought back and used", async () => {
    const { headers } = await t.signIn("archived-only@lukas.test");
    const ocio = await create(headers, "Ocio");
    await archive(headers, ocio);
    const preview = (await (await upload(headers, FIXTURE)).json()) as Preview;
    expect(preview.stats.newCategories).not.toContain("Ocio");
    expect((await t.request("POST", `/v1/imports/${preview.id}/confirm`, { headers })).status).toBe(
      200,
    );
    const after = await categoriesOf(headers);
    expect(after.filter((c) => c.name.toLowerCase() === "ocio")).toEqual([
      expect.objectContaining({ id: ocio, archived: false }),
    ]);
    expect(await rowsIn(headers, ocio)).toBe(3);
  });

  test("an active match wins over an archived twin", async () => {
    const { headers } = await t.signIn("archived-twin@lukas.test");
    const old = await create(headers, "ocio");
    await archive(headers, old);
    const active = await create(headers, "Ocio");
    const preview = (await (await upload(headers, FIXTURE)).json()) as Preview;
    await t.request("POST", `/v1/imports/${preview.id}/confirm`, { headers });
    expect(await rowsIn(headers, active)).toBe(3);
    const twin = (await categoriesOf(headers)).find((c) => c.id === old);
    expect(twin?.archived).toBe(true);
  });
});

describe("adopting the file's currency on confirm", () => {
  test("the preview of an empty account anticipates the file's currency, and confirm adopts it", async () => {
    const { headers } = await t.signIn("adopt@lukas.test");
    await t.request("PATCH", "/v1/me", { headers, body: { currency: "COP" } });
    const groceries = (await (
      await t.request("POST", "/v1/categories", {
        headers,
        body: { name: "Supermercado", kind: "expense", icon: "🛒", color: "#ff9f1c" },
      })
    ).json()) as { id: string };
    await t.request("PUT", `/v1/categories/${groceries.id}/budget`, {
      headers,
      body: { amount: 30_000_000, effectiveFrom: "2026-10" },
    });
    const preview = (await (await upload(headers, FIXTURE)).json()) as Preview & {
      stats: { adoptsCurrency: boolean; dropsBudgets: boolean };
    };
    expect(preview.stats).toMatchObject({
      currency: "EUR",
      transactions: 22,
      adoptsCurrency: true,
      dropsBudgets: true,
    });

    // Without consent the currencies don't match: nothing happens.
    const refused = await t.request("POST", `/v1/imports/${preview.id}/confirm`, { headers });
    expect(refused.status).toBe(409);
    expect(await refused.json()).toMatchObject({ code: "import_currency_changed" });
    const meBefore = (await (await t.request("GET", "/v1/me", { headers })).json()) as {
      currency: string;
    };
    expect(meBefore.currency).toBe("COP");

    const res = await t.request("POST", `/v1/imports/${preview.id}/confirm`, {
      headers,
      body: { adoptFileCurrency: true },
    });
    expect(res.status).toBe(200);
    const me = (await (await t.request("GET", "/v1/me", { headers })).json()) as {
      currency: string;
    };
    expect(me.currency).toBe("EUR");
    expect(await countTransactions(headers)).toBe(22);
    // The budget in pesos is gone with the switch.
    const cats = (await (await t.request("GET", "/v1/categories", { headers })).json()) as {
      id: string;
      currentBudget: number | null;
    }[];
    expect(cats.find((c) => c.id === groceries.id)?.currentBudget).toBeNull();
  });

  test("an account that got transactions since can't adopt: currency_locked, nothing imported", async () => {
    const { headers } = await t.signIn("adopt-locked@lukas.test");
    await t.request("PATCH", "/v1/me", { headers, body: { currency: "COP" } });
    const preview = (await (await upload(headers, FIXTURE)).json()) as Preview & {
      stats: { adoptsCurrency: boolean };
    };
    expect(preview.stats.adoptsCurrency).toBe(true);
    const cat = (await (
      await t.request("POST", "/v1/categories", {
        headers,
        body: { name: "Varios", kind: "expense", icon: "🏷️", color: "#8e87b8" },
      })
    ).json()) as { id: string };
    await t.request("POST", "/v1/transactions", {
      headers,
      body: { name: "algo", amount: -100_000, categoryId: cat.id, date: "2026-10-01" },
    });
    const res = await t.request("POST", `/v1/imports/${preview.id}/confirm`, {
      headers,
      body: { adoptFileCurrency: true },
    });
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "currency_locked" });
    expect(await countTransactions(headers)).toBe(1);
  });

  test("an account with transactions previews in its own currency (rows rejected)", async () => {
    const { headers } = await t.signIn("adopt-has-tx@lukas.test");
    await t.request("PATCH", "/v1/me", { headers, body: { currency: "COP" } });
    const cat = (await (
      await t.request("POST", "/v1/categories", {
        headers,
        body: { name: "Varios", kind: "expense", icon: "🏷️", color: "#8e87b8" },
      })
    ).json()) as { id: string };
    await t.request("POST", "/v1/transactions", {
      headers,
      body: { name: "algo", amount: -100_000, categoryId: cat.id, date: "2026-10-01" },
    });
    const preview = (await (await upload(headers, FIXTURE)).json()) as Preview & {
      stats: { adoptsCurrency: boolean };
    };
    expect(preview.stats).toMatchObject({
      currency: "EUR",
      transactions: 0,
      adoptsCurrency: false,
    });
  });
});
