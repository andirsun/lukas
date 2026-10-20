import { afterAll, afterEach, beforeAll, expect, test, vi } from "vitest";
import { idempotent } from "../src/http/idempotency.ts";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let b: { authorization: string };
let calls = 0;

beforeAll(async () => {
  t = await createTestApp();
  t.app.post("/v1/test/idempotent", idempotent(t.db), async (c) => {
    calls++;
    return c.json({ call: calls, echo: await c.req.json() }, 201);
  });
  a = (await t.signIn("a@lukas.test")).headers;
  b = (await t.signIn("b@lukas.test")).headers;
}, 120_000);
afterAll(() => t?.stop());
afterEach(() => vi.useRealTimers());

const post = (headers: object, key: string | null, body: object) =>
  t.request("POST", "/v1/test/idempotent", {
    headers: { ...headers, ...(key ? { "idempotency-key": key } : {}) },
    body,
  });

test("the same key and body replays the first response without running the handler again", async () => {
  const before = calls;
  const first = await post(a, "k1", { x: 1 });
  const second = await post(a, "k1", { x: 1 });
  expect(calls - before).toBe(1);
  expect(second.status).toBe(201);
  expect(await second.json()).toEqual(await first.json());
});

test("reusing a key with a different body is rejected", async () => {
  await post(a, "k2", { x: 1 });
  const res = await post(a, "k2", { x: 2 });
  expect(res.status).toBe(422);
  expect(await res.json()).toMatchObject({ code: "idempotency_key_reused" });
});

test("keys are per user", async () => {
  const before = calls;
  await post(a, "k3", { x: 1 });
  await post(b, "k3", { x: 1 });
  expect(calls - before).toBe(2);
});

test("requests without a key always run", async () => {
  const before = calls;
  await post(a, null, { x: 1 });
  await post(a, null, { x: 1 });
  expect(calls - before).toBe(2);
});

test("keys expire after 24 hours", async () => {
  vi.useFakeTimers({ toFake: ["Date"] });
  vi.setSystemTime(new Date("2026-10-20T10:00:00Z"));
  const before = calls;
  await post(a, "k4", { x: 1 });
  vi.setSystemTime(new Date("2026-10-21T11:00:00Z"));
  await post(a, "k4", { x: 1 });
  expect(calls - before).toBe(2);
});
