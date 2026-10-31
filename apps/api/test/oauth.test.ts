import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from "vitest";
import { ACCESS_TOKEN_TTL_SECONDS } from "../src/auth.ts";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(() => t?.stop());
afterEach(() => {
  vi.useRealTimers();
});

const bearer = (token: string) => ({ authorization: `Bearer ${token}` });
const payloadOf = (jwt: string) =>
  JSON.parse(Buffer.from(jwt.split(".")[1] ?? "", "base64url").toString()) as Record<
    string,
    unknown
  >;

async function newCategory(headers: { authorization: string }, name = "Comida") {
  const res = await t.request("POST", "/v1/categories", {
    headers,
    body: { name, kind: "expense", icon: "food", color: "orange" },
  });
  expect(res.status).toBe(201);
  return ((await res.json()) as { id: string }).id;
}

describe("assistant access tokens", () => {
  test("an access token for the MCP opens the person's finances", async () => {
    const { accessToken } = await t.authorize("open@lukas.test");
    const res = await t.request("GET", "/v1/categories", { headers: bearer(accessToken) });
    expect(res.status).toBe(200);
  });

  test("the access token lives 15 minutes and is for the MCP", async () => {
    const { accessToken } = await t.authorize("ttl@lukas.test");
    const payload = payloadOf(accessToken);
    expect(Number(payload.exp) - Number(payload.iat)).toBe(ACCESS_TOKEN_TTL_SECONDS);
    expect(ACCESS_TOKEN_TTL_SECONDS).toBe(900);
    expect(payload.aud).toBe(t.config.MCP_URL);
  });

  test("a JWT of ours for another audience is refused", async () => {
    const { headers } = await t.signIn("aud@lukas.test");
    const res = await t.request("GET", "/auth/token", { headers });
    expect(res.status).toBe(200);
    const { token } = (await res.json()) as { token: string };
    expect(payloadOf(token).aud).not.toBe(t.config.MCP_URL);
    const denied = await t.request("GET", "/v1/categories", { headers: bearer(token) });
    expect(denied.status).toBe(401);
  });

  test("a token asked for without the MCP resource is refused", async () => {
    const { accessToken } = await t.authorize("nores@lukas.test", { resource: "" });
    const res = await t.request("GET", "/v1/categories", { headers: bearer(accessToken) });
    expect(res.status).toBe(401);
  });

  test("an expired token is refused", async () => {
    const { accessToken } = await t.authorize("expired@lukas.test");
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(Date.now() + (ACCESS_TOKEN_TTL_SECONDS + 60) * 1000);
    const res = await t.request("GET", "/v1/categories", { headers: bearer(accessToken) });
    expect(res.status).toBe(401);
  });

  test("a tampered token is refused", async () => {
    const { accessToken } = await t.authorize("tamper@lukas.test");
    const [h, p, s] = accessToken.split(".");
    const forged = { ...payloadOf(accessToken), sub: "someone-else" };
    const token = `${h}.${Buffer.from(JSON.stringify(forged)).toString("base64url")}.${s}`;
    void p;
    const res = await t.request("GET", "/v1/categories", { headers: bearer(token) });
    expect(res.status).toBe(401);
  });
});

describe("scopes", () => {
  test("finance:read reads but cannot write", async () => {
    const { headers } = await t.signIn("read@lukas.test");
    const categoryId = await newCategory(headers);
    const { accessToken } = await t.authorize("read@lukas.test", {
      scope: "finance:read",
      headers,
    });
    expect((await t.request("GET", "/v1/summary", { headers: bearer(accessToken) })).status).toBe(
      200,
    );
    const res = await t.request("POST", "/v1/transactions", {
      headers: bearer(accessToken),
      body: { name: "Almuerzo", amount: -1800000, categoryId, date: "2026-10-30" },
    });
    expect(res.status).toBe(403);
    expect(((await res.json()) as { code: string }).code).toBe("insufficient_scope");
  });

  test("an assistant never reaches the account itself", async () => {
    const { accessToken } = await t.authorize("account@lukas.test");
    const headers = bearer(accessToken);
    expect((await t.request("GET", "/v1/me", { headers })).status).toBe(200);
    for (const [method, path] of [
      ["DELETE", "/v1/me"],
      ["PATCH", "/v1/me"],
      ["GET", "/v1/me/export"],
      ["POST", "/v1/imports"],
      ["POST", "/v1/me/claim-email/send"],
      ["GET", "/v1/me/assistants"],
    ] as const) {
      const res = await t.request(method, path, {
        headers,
        body: method === "GET" ? undefined : {},
      });
      expect(res.status, `${method} ${path}`).toBe(403);
    }
  });

  test("a session keeps full access", async () => {
    const { headers } = await t.signIn("session@lukas.test");
    expect((await t.request("GET", "/v1/me/export", { headers })).status).toBe(200);
  });
});

describe("what an assistant saves", () => {
  test("a transaction saved with an assistant's token has source mcp, whatever it sent", async () => {
    const { headers } = await t.signIn("source@lukas.test");
    const categoryId = await newCategory(headers);
    const { accessToken } = await t.authorize("source@lukas.test", { headers });
    const one = await t.request("POST", "/v1/transactions", {
      headers: bearer(accessToken),
      body: { name: "Almuerzo", amount: -1800000, categoryId, date: "2026-10-30", source: "app" },
    });
    expect(one.status).toBe(201);
    expect(((await one.json()) as { source: string }).source).toBe("mcp");
    const batch = await t.request("POST", "/v1/transactions/batch", {
      headers: { ...bearer(accessToken), "idempotency-key": "k1" },
      body: { items: [{ name: "Taxi", amount: -1200000, categoryId, date: "2026-10-30" }] },
    });
    expect(batch.status).toBe(201);
    const { items } = (await batch.json()) as { items: { source: string }[] };
    expect(items.map((i) => i.source)).toEqual(["mcp"]);
    // The person's own save keeps its source.
    const mine = await t.request("POST", "/v1/transactions", {
      headers,
      body: { name: "Bus", amount: -300000, categoryId, date: "2026-10-30", source: "web" },
    });
    expect(((await mine.json()) as { source: string }).source).toBe("web");
  });
});

describe("authorization server", () => {
  test("a guest cannot authorize an assistant", async () => {
    const guest = await t.request("POST", "/auth/sign-in/anonymous", { body: {} });
    expect(guest.status).toBe(200);
    const headers = { authorization: `Bearer ${guest.headers.get("set-auth-token")}` };
    await expect(t.authorize("unused@lukas.test", { headers })).rejects.toThrow(
      /consent failed: 403/,
    );
  });

  test("the authorization response names its issuer (RFC 9207)", async () => {
    const { headers } = await t.signIn("iss@lukas.test");
    const clientId = await t.registerAssistant();
    const q = new URLSearchParams({
      response_type: "code",
      client_id: clientId,
      redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scope: "finance:read",
      state: "s",
      code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
      code_challenge_method: "S256",
      resource: t.config.MCP_URL ?? "",
    });
    const auth = await t.request("GET", `/auth/oauth2/authorize?${q}`, { headers });
    const consent = await t.request("POST", "/auth/oauth2/consent", {
      headers,
      body: {
        accept: true,
        oauth_query: new URL(auth.headers.get("location") ?? "").search.slice(1),
      },
    });
    const back = new URL(((await consent.json()) as { url: string }).url);
    expect(back.searchParams.get("iss")).toBe(`${t.config.API_URL}/auth`);
  });

  test("the metadata is at the issuer's well-known path and offers CIMD", async () => {
    for (const path of [
      "/.well-known/oauth-authorization-server",
      "/.well-known/oauth-authorization-server/auth",
    ]) {
      const res = await t.request("GET", path);
      expect(res.status, path).toBe(200);
      const metadata = (await res.json()) as Record<string, unknown>;
      expect(metadata.issuer).toBe(`${t.config.API_URL}/auth`);
      expect(metadata.client_id_metadata_document_supported).toBe(true);
      expect(metadata.authorization_response_iss_parameter_supported).toBe(true);
      expect(metadata.code_challenge_methods_supported).toEqual(["S256"]);
    }
  });
});
