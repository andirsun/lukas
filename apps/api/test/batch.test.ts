import { accounts, withUser } from "@lukas/db";
import { eq } from "@lukas/db/orm";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let b: { authorization: string };
let ocio: string;
let casa: string;
let bOcio: string;

interface Tx {
  id: string;
  name: string;
  amount: number;
  currency: string;
  source: string;
}
interface Page {
  items: Tx[];
}

async function category(headers: typeof a, name: string) {
  const res = await t.request("POST", "/v1/categories", {
    headers,
    body: { name, kind: "expense", icon: "star", color: "purple" },
  });
  return ((await res.json()) as { id: string }).id;
}

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  b = (await t.signIn("b@lukas.test")).headers;
  ocio = await category(a, "Ocio");
  casa = await category(a, "Casa");
  bOcio = await category(b, "Ocio");
});
afterAll(() => t?.stop());

let keyCounter = 0;
const nextKey = () => `batch-key-${++keyCounter}`;
const item = (categoryId: string, name: string, amount: number, extra: object = {}) => ({
  categoryId,
  name,
  amount,
  date: "2026-10-05",
  ...extra,
});
const batch = (
  items: object[],
  { headers = a, key = nextKey() as string | null } = {},
): Promise<Response> =>
  t.request("POST", "/v1/transactions/batch", {
    headers: { ...headers, ...(key ? { "idempotency-key": key } : {}) },
    body: { items },
  });
const batchDelete = (ids: string[], headers = a) =>
  t.request("POST", "/v1/transactions/batch-delete", { headers, body: { ids } });
const list = async (headers = a, query = "") =>
  (
    (await (
      await t.request("GET", `/v1/transactions?limit=200${query}`, { headers })
    ).json()) as Page
  ).items;
const spent = async (headers = a) =>
  (
    (await (await t.request("GET", "/v1/summary?month=2026-10", { headers })).json()) as {
      spent: number;
    }
  ).spent;

describe("batch create", () => {
  test("saves 2 items in one call; the month summary counts both", async () => {
    const before = await spent();
    const res = await batch([
      item(ocio, "cinema", -950),
      item(casa, "rent", -4000, { source: "widget" }),
    ]);
    expect(res.status).toBe(201);
    const body = (await res.json()) as { items: Tx[] };
    expect(body.items).toHaveLength(2);
    expect(body.items[0]).toMatchObject({
      name: "cinema",
      amount: -950,
      currency: "EUR",
      source: "app",
    });
    expect(body.items[1]).toMatchObject({ name: "rent", amount: -4000, source: "widget" });
    expect(await spent()).toBe(before + 950 + 4000);
  });

  test("all or nothing: an unknown category in item 2 saves neither", async () => {
    const before = (await list()).length;
    const res = await batch([
      item(ocio, "first", -100),
      item("00000000-0000-4000-8000-000000000000", "second", -200),
    ]);
    expect(res.status).toBe(422);
    expect(await res.json()).toMatchObject({ code: "category_not_found" });
    expect(await list()).toHaveLength(before);
  });

  test("a category that belongs to another user is refused the same way", async () => {
    const before = (await list()).length;
    const res = await batch([item(ocio, "mine", -100), item(bOcio, "theirs", -200)]);
    expect(res.status).toBe(422);
    expect(await list()).toHaveLength(before);
  });

  test("replaying the same Idempotency-Key returns the same items and creates nothing", async () => {
    const key = nextKey();
    const items = [item(ocio, "replayed one", -111), item(casa, "replayed two", -222)];
    const first = await batch(items, { key });
    expect(first.status).toBe(201);
    const firstBody = (await first.json()) as { items: Tx[] };
    const countAfterFirst = (await list()).length;

    const second = await batch(items, { key });
    expect(second.status).toBe(201);
    expect(await second.json()).toEqual(firstBody);
    expect(await list()).toHaveLength(countAfterFirst);
    expect((await list()).filter((x) => x.name.startsWith("replayed"))).toHaveLength(2);

    // The same key with other items is not a replay.
    const other = await batch([item(ocio, "different", -1)], { key });
    expect(other.status).toBe(422);
    expect(await other.json()).toMatchObject({ code: "idempotency_key_reused" });
  });

  test("a batch without an Idempotency-Key is refused", async () => {
    const before = (await list()).length;
    const res = await batch([item(ocio, "no key", -100)], { key: null });
    expect(res.status).toBe(400);
    expect(res.headers.get("content-type")).toContain("application/problem+json");
    expect(await res.json()).toMatchObject({ status: 400, code: "idempotency_key_required" });
    expect(await list()).toHaveLength(before);
  });

  test("21 items are refused, and so is an empty list", async () => {
    const before = (await list()).length;
    const many = Array.from({ length: 21 }, (_, i) => item(ocio, `bulk ${i}`, -1));
    expect((await batch(many)).status).toBe(422);
    expect((await batch([])).status).toBe(422);
    expect(await list()).toHaveLength(before);
    expect((await batch(many.slice(0, 20))).status).toBe(201);
  });
});

describe("batch delete", () => {
  test("soft-deletes exactly those ids; another user's ids are untouched", async () => {
    const mine = (await (
      await batch([item(ocio, "del 1", -1), item(ocio, "del 2", -2), item(ocio, "keep", -3)])
    ).json()) as { items: Tx[] };
    const theirs = (await (await batch([item(bOcio, "b's", -5)], { headers: b })).json()) as {
      items: Tx[];
    };
    const [d1, d2, keep] = mine.items as [Tx, Tx, Tx];
    const [bTx] = theirs.items as [Tx];

    // a asks to delete two of its own and one of b's; b's is silently ignored.
    const res = await batchDelete([d1.id, d2.id, bTx.id]);
    expect(res.status).toBe(204);

    const live = (await list()).map((x) => x.id);
    expect(live).not.toContain(d1.id);
    expect(live).not.toContain(d2.id);
    expect(live).toContain(keep.id);
    expect((await list(b)).map((x) => x.id)).toContain(bTx.id);

    // Soft: the single restore brings one back.
    const restored = await t.request("POST", `/v1/transactions/${d1.id}/restore`, { headers: a });
    expect(restored.status).toBe(200);
    expect((await list()).map((x) => x.id)).toContain(d1.id);
  });

  test("unknown ids and ids already deleted are not an error", async () => {
    const res = await batchDelete(["00000000-0000-4000-8000-000000000000"]);
    expect(res.status).toBe(204);
  });

  test("0 or 21 ids are refused", async () => {
    expect((await batchDelete([])).status).toBe(422);
    const ids = Array.from(
      { length: 21 },
      (_, i) => `00000000-0000-4000-8000-${String(i).padStart(12, "0")}`,
    );
    expect((await batchDelete(ids)).status).toBe(422);
  });
});

describe("batch and the default-account lock", () => {
  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  test("batch takes the default-account lock like a single create", async () => {
    const { userId, headers } = await t.signIn("batch-lock@lukas.test");
    const cat = await category(headers, "Ocio");
    let pending: Promise<Response> | undefined;
    let settled = false;
    await withUser(t.db, userId, async (tx) => {
      // The currency change's side: lock the account, then switch the (still empty) account.
      await tx.select().from(accounts).where(eq(accounts.isDefault, true)).for("update");
      pending = batch([item(cat, "locked one", -10), item(cat, "locked two", -20)], { headers });
      void pending.finally(() => {
        settled = true;
      });
      await sleep(300);
      // Without the lock the batch would have finished by now.
      expect(settled).toBe(false);
      await tx.update(accounts).set({ currency: "COP" }).where(eq(accounts.isDefault, true));
    });
    const res = await (pending as Promise<Response>);
    expect(res.status).toBe(201);
    // It read the currency after the lock was released: both rows are in COP.
    const body = (await res.json()) as { items: Tx[] };
    expect(body.items.map((x) => x.currency)).toEqual(["COP", "COP"]);
  });
});
