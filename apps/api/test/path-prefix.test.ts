import { afterAll, beforeAll, expect, test } from "vitest";
import { codeFrom, createTestApp, type TestApp } from "./harness.ts";

// Behind the web's /api proxy, API_URL carries a path and every route lives under it.
const API_URL = "http://localhost:5173/api";

let t: TestApp;
beforeAll(async () => {
  t = await createTestApp({ API_URL });
}, 120_000);
afterAll(() => t?.stop());

test("GET /api/health answers under the API_URL path", async () => {
  const res = await t.request("GET", "/api/health");
  expect(res.status).toBe(200);
  expect(await res.json()).toEqual({ status: "ok" });
});

test("routes outside the API_URL path are not served", async () => {
  expect((await t.request("GET", "/health")).status).toBe(404);
  expect((await t.request("GET", "/auth/get-session")).status).toBe(404);
});

test("an email code sent and verified under /api/auth signs in", async () => {
  const sent = await t.request("POST", "/api/auth/email-otp/send-verification-otp", {
    body: { email: "prefix@lukas.test", type: "sign-in" },
  });
  expect(sent.status).toBe(200);
  const code = codeFrom(t.mailer.lastTo("prefix@lukas.test")?.subject ?? "");

  const res = await t.request("POST", "/api/auth/sign-in/email-otp", {
    body: { email: "prefix@lukas.test", otp: code },
  });
  expect(res.status).toBe(200);
  const token = res.headers.get("set-auth-token");
  expect(token).toBeTruthy();

  const me = await t.request("GET", "/api/v1/me", {
    headers: { authorization: `Bearer ${token}` },
  });
  expect(me.status).toBe(200);
  expect(await me.json()).toMatchObject({ email: "prefix@lukas.test" });
});

test("Better Auth publishes its endpoints under API_URL/auth", async () => {
  const res = await t.request("GET", "/api/.well-known/oauth-authorization-server");
  expect(res.status).toBe(200);
  const metadata = (await res.json()) as { authorization_endpoint: string; token_endpoint: string };
  expect(metadata.authorization_endpoint).toMatch(/^http:\/\/localhost:5173\/api\/auth\//);
  expect(metadata.token_endpoint).toMatch(/^http:\/\/localhost:5173\/api\/auth\//);
});

test("the OpenAPI document keeps prefix-free paths and names API_URL as its server", async () => {
  const res = await t.request("GET", "/api/openapi.json");
  expect(res.status).toBe(200);
  const doc = (await res.json()) as { paths: Record<string, unknown>; servers?: { url: string }[] };
  expect(Object.keys(doc.paths)).toContain("/v1/me");
  expect(doc.servers).toEqual([{ url: API_URL }]);
});
