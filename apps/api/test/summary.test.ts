import { user } from "@lukas/db";
import { eq } from "@lukas/db/orm";
import { afterAll, afterEach, beforeAll, expect, test, vi } from "vitest";
import { seedOctober2026 } from "./fixtures.ts";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let b: { authorization: string };
let ids: Record<string, string>;

interface Summary {
  month: string;
  remaining: number;
  balance: number;
  spent: number;
  categories: { categoryId: string; state: string }[];
}
const summary = async (query: string, headers: { authorization: string } = a) =>
  (await (await t.request("GET", `/v1/summary${query}`, { headers })).json()) as Summary;

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  b = (await t.signIn("b@lukas.test")).headers;
  ids = await seedOctober2026(t, a);
});
afterAll(() => t?.stop());
afterEach(() => vi.useRealTimers());

test("October 2026 matches the figures from Budge", async () => {
  const s = await summary("?month=2026-10");
  expect(s).toMatchObject({ month: "2026-10", remaining: 56292, balance: 396292 });
  expect(s.categories.find((c) => c.categoryId === ids.supermercado)?.state).toBe("over");
});

test("archiving a category keeps its spending in what is left", async () => {
  await t.request("PATCH", `/v1/categories/${ids.ocio}`, { headers: a, body: { archived: true } });
  const s = await summary("?month=2026-10");
  expect(s.remaining).toBe(56292);
  expect(s.categories.map((c) => c.categoryId)).toContain(ids.ocio);
});

test("the default month follows the user's time zone", async () => {
  vi.useFakeTimers({ toFake: ["Date"] });
  vi.setSystemTime(new Date("2026-11-01T03:00:00Z"));
  // Sign in under the fake clock so the session is not expired relative to it.
  const bogota = await t.signIn("bogota@lukas.test");
  await t.admin.update(user).set({ timezone: "America/Bogota" }).where(eq(user.id, bogota.userId));
  expect((await summary("", bogota.headers)).month).toBe("2026-10");
});

test("other users see their own empty month", async () => {
  expect((await summary("?month=2026-10", b)).spent).toBe(0);
});

test("an invalid month is a validation problem", async () => {
  const res = await t.request("GET", "/v1/summary?month=2026-13", { headers: a });
  expect(res.status).toBe(422);
});
