import { afterAll, beforeAll, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

/**
 * The e2e suite pins the API's clock (E2E_NOW, passed to the app as `now`) so the months it reads
 * do not depend on the real date. Every "current month" the API works out comes from that clock.
 */
let t: TestApp;
let a: { authorization: string };
const NOW = new Date("2026-03-10T12:00:00Z");

beforeAll(async () => {
  t = await createTestApp({}, { now: () => NOW });
  a = (await t.signIn("clock@lukas.test")).headers;
});
afterAll(() => t?.stop());

test("the summary's month defaults to the pinned clock's", async () => {
  const res = await t.request("GET", "/v1/summary", { headers: a });
  expect(res.status).toBe(200);
  expect(((await res.json()) as { month: string }).month).toBe("2026-03");
});

test("health says the clock is pinned, and to when", async () => {
  const res = await t.request("GET", "/health");
  expect(await res.json()).toEqual({ status: "ok", now: "2026-03-10T12:00:00.000Z" });
});
