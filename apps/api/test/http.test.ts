import { afterAll, beforeAll, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(() => t?.stop());

test("GET /health", async () => {
  const res = await t.request("GET", "/health");
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ status: "ok" });
});

test("GET /health says which version is running, when the build named one", async () => {
  const versioned = await createTestApp({ LUKITAS_VERSION: "0.0.0-dev.abc1234" });
  try {
    const res = await versioned.request("GET", "/health");
    expect(await res.json()).toEqual({ status: "ok", version: "0.0.0-dev.abc1234" });
  } finally {
    await versioned.stop();
  }
});

test("protected routes return a problem+json 401 without a session", async () => {
  const res = await t.request("GET", "/v1/me");
  expect(res.status).toBe(401);
  expect(res.headers.get("content-type")).toContain("application/problem+json");
  expect(await res.json()).toMatchObject({ status: 401, code: "unauthenticated" });
});

test("GET /openapi.json describes the API", async () => {
  const res = await t.request("GET", "/openapi.json");
  expect(res.status).toBe(200);
  expect(((await res.json()) as { openapi: string }).openapi).toMatch(/^3\./);
});

test("the OpenAPI document is titled Lukitas API", async () => {
  const res = await t.request("GET", "/openapi.json");
  const doc = (await res.json()) as { info: { title: string } };
  expect(doc.info.title).toBe("Lukitas API");
});

test("unknown routes return a problem+json 404", async () => {
  const res = await t.request("GET", "/nope");
  expect(res.status).toBe(404);
  expect(await res.json()).toMatchObject({ code: "not_found" });
});
