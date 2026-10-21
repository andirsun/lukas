import { afterAll, beforeAll, expect, test } from "vitest";
import { seedOctober2026 } from "./fixtures.ts";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let ids: Record<string, string>;

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  ids = await seedOctober2026(t, a);
  await t.request("POST", "/v1/transactions", {
    headers: a,
    body: {
      categoryId: ids.ocio,
      name: "festival",
      amount: -5000,
      date: "2026-10-30",
      status: "pending",
    },
  });
}, 120_000);
afterAll(() => t?.stop());

interface ByCategory {
  total: number;
  items: { categoryId: string; name: string; total: number; share: number }[];
}
const get = async <T>(path: string) => {
  const res = await t.request("GET", path, { headers: a });
  return { status: res.status, body: (await res.json()) as T };
};

test("expenses by category for a month", async () => {
  const { body } = await get<ByCategory>(
    "/v1/reports/by-category?from=2026-10&to=2026-10&status=paid",
  );
  expect(body.total).toBe(223708);
  expect(body.items[0]).toMatchObject({
    categoryId: ids.casa,
    name: "Casa",
    total: 132978,
    share: 0.5944,
  });
  expect(body.items.map((i) => i.categoryId)).not.toContain(ids.transporte);
});

test("status filters and kind=income", async () => {
  const pending = await get<ByCategory>(
    "/v1/reports/by-category?from=2026-10&to=2026-10&status=pending",
  );
  expect(pending.body).toMatchObject({ total: 5000, items: [{ categoryId: ids.ocio, share: 1 }] });
  const income = await get<ByCategory>(
    "/v1/reports/by-category?from=2026-10&to=2026-10&kind=income",
  );
  expect(income.body.items).toEqual([
    expect.objectContaining({ name: "Salário", total: 620000, share: 1 }),
  ]);
  const both = await get<ByCategory>("/v1/reports/by-category?from=2026-10&to=2026-10");
  expect(both.body.total).toBe(228708);
});

test("trend includes empty months", async () => {
  const { body } = await get<{
    months: { month: string; income: number; expenses: number; budget: number }[];
  }>("/v1/reports/trend?from=2026-09&to=2026-11");
  expect(body.months).toEqual([
    { month: "2026-09", income: 0, expenses: 0, budget: 280000 },
    { month: "2026-10", income: 620000, expenses: 228708, budget: 280000 },
    { month: "2026-11", income: 0, expenses: 0, budget: 280000 },
  ]);
});

test("ranges are validated", async () => {
  const reversed = await get<{ code: string }>("/v1/reports/trend?from=2026-11&to=2026-09");
  expect(reversed).toMatchObject({ status: 422, body: { code: "validation_failed" } });
  const tooLong = await get<{ code: string }>("/v1/reports/by-category?from=2023-01&to=2026-01");
  expect(tooLong).toMatchObject({ status: 422, body: { code: "range_too_large" } });
});
