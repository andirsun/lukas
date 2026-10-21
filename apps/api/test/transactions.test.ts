import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let b: { authorization: string };
let ocio: string;
let archived: string;

interface Tx {
  id: string;
  name: string;
  amount: number;
  date: string;
  status: string;
  currency: string;
  source: string;
}
interface Page {
  items: Tx[];
  nextCursor: string | null;
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
  archived = await category(a, "Old");
  await t.request("PATCH", `/v1/categories/${archived}`, { headers: a, body: { archived: true } });
}, 120_000);
afterAll(() => t?.stop());

const create = (body: object, headers: Record<string, string> = a) =>
  t.request("POST", "/v1/transactions", { headers, body: { categoryId: ocio, ...body } });
const page = async (query: string, headers = a) =>
  (await (await t.request("GET", `/v1/transactions${query}`, { headers })).json()) as Page;

describe("transactions", () => {
  let cinema: Tx;

  test("create copies the account currency and defaults the source", async () => {
    const res = await create({ name: "cinema", amount: -950, date: "2026-10-05" });
    expect(res.status).toBe(201);
    cinema = (await res.json()) as Tx;
    expect(cinema).toMatchObject({ currency: "EUR", source: "app", status: "paid", amount: -950 });
  });

  test("list filters by month and status", async () => {
    await create({ name: "concert", amount: -3000, date: "2026-11-02", status: "pending" });
    expect((await page("?month=2026-10")).items.map((i) => i.name)).toEqual(["cinema"]);
    expect((await page("?status=pending")).items.map((i) => i.name)).toEqual(["concert"]);
  });

  test("edit, delete and restore", async () => {
    let res = await t.request("PATCH", `/v1/transactions/${cinema.id}`, {
      headers: a,
      body: { amount: -1200 },
    });
    expect(res.status).toBe(200);
    expect(((await res.json()) as Tx).amount).toBe(-1200);

    res = await t.request("DELETE", `/v1/transactions/${cinema.id}`, { headers: a });
    expect(res.status).toBe(204);
    expect((await page("?month=2026-10")).items).toEqual([]);
    res = await t.request("PATCH", `/v1/transactions/${cinema.id}`, {
      headers: a,
      body: { amount: -1 },
    });
    expect(res.status).toBe(404);

    res = await t.request("POST", `/v1/transactions/${cinema.id}/restore`, { headers: a });
    expect(res.status).toBe(200);
    expect((await page("?month=2026-10")).items.map((i) => i.id)).toEqual([cinema.id]);
  });

  test("archived or foreign categories are rejected", async () => {
    let res = await create({ name: "x", amount: -1, date: "2026-10-01", categoryId: archived });
    expect(res.status).toBe(422);
    expect(await res.json()).toMatchObject({ code: "category_not_found" });
    const foreign = await category(b, "Theirs");
    res = await create({ name: "x", amount: -1, date: "2026-10-01", categoryId: foreign });
    expect(res.status).toBe(422);
  });

  test("users cannot see or touch each other's transactions", async () => {
    expect((await page("", b)).items).toEqual([]);
    for (const [method, path] of [
      ["PATCH", `/v1/transactions/${cinema.id}`],
      ["DELETE", `/v1/transactions/${cinema.id}`],
      ["POST", `/v1/transactions/${cinema.id}/restore`],
    ] as const) {
      const res = await t.request(method, path, {
        headers: b,
        body: method === "PATCH" ? { amount: -1 } : undefined,
      });
      expect(res.status).toBe(404);
    }
  });

  test("an Idempotency-Key reused with a different body is rejected", async () => {
    const headers = { ...a, "idempotency-key": "widget-123" };
    expect(
      (await create({ name: "coffee", amount: -120, date: "2026-10-06" }, headers)).status,
    ).toBe(201);
    const replay = await create({ name: "coffee", amount: -120, date: "2026-10-06" }, headers);
    expect(replay.status).toBe(201);
    const reused = await create({ name: "coffee", amount: -999, date: "2026-10-06" }, headers);
    expect(reused.status).toBe(422);
    expect(await reused.json()).toMatchObject({ code: "idempotency_key_reused" });
    expect((await page("?month=2026-10")).items.filter((i) => i.name === "coffee")).toHaveLength(1);
  });

  test("pagination over many same-day transactions returns each exactly once", async () => {
    for (let i = 0; i < 120; i++)
      await create({ name: `bulk ${i}`, amount: -1, date: "2026-12-15" });
    const ids: string[] = [];
    const sizes: number[] = [];
    let cursor: string | null = null;
    do {
      const query: string = `?month=2026-12&limit=50${cursor ? `&cursor=${cursor}` : ""}`;
      const p = await page(query);
      ids.push(...p.items.map((i) => i.id));
      sizes.push(p.items.length);
      cursor = p.nextCursor;
    } while (cursor);
    expect(sizes).toEqual([50, 50, 20]);
    expect(new Set(ids).size).toBe(120);
  });
});
