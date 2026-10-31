import { Client, StreamableHTTPClientTransport } from "@modelcontextprotocol/client";
import { createLocalJWKSet, type JSONWebKeySet } from "jose";
import { afterAll, beforeAll, expect, test } from "vitest";
import { createTestApp, type TestApp } from "../../api/test/harness.ts";
import { apiLukitas } from "../src/api-lukitas.ts";
import { createMcpApp } from "../src/app.ts";
import { jwtVerifier } from "../src/verifier.ts";

// Everything real but the network: the API and its database, an assistant's token from the OAuth
// flow, the MCP's own token check against the API's keys, and the SDK's client.
let t: TestApp;
let mcp: ReturnType<typeof createMcpApp>;
let headers: { authorization: string };
beforeAll(async () => {
  t = await createTestApp();
  const MCP_URL = t.config.MCP_URL ?? "";
  const fetchApi = (async (input: string | URL | Request, init?: RequestInit) =>
    t.app.request(input instanceof Request ? input : String(input), init)) as typeof fetch;
  const jwks = (await (await t.app.request("/auth/jwks")).json()) as JSONWebKeySet;
  const config = {
    MCP_URL,
    AUTH_ISSUER: `${t.config.API_URL}/auth`,
    MCP_API_URL: t.config.API_URL,
    RATE_LIMIT_PER_MINUTE: 120,
  };
  mcp = createMcpApp({
    config,
    verifier: jwtVerifier(config, createLocalJWKSet(jwks)),
    lukitasFor: (token) => apiLukitas(t.config.API_URL, token, fetchApi),
  });
  ({ headers } = await t.signIn("e2e@lukas.test"));
  await t.request("POST", "/v1/categories", {
    headers,
    body: { name: "Almuerzos", kind: "expense", icon: "food", color: "orange" },
  });
});
afterAll(() => t?.stop());

async function connect(token: string) {
  const client = new Client(
    { name: "e2e", version: "1.0.0" },
    { versionNegotiation: { mode: { pin: "2026-07-28" } } },
  );
  await client.connect(
    new StreamableHTTPClientTransport(new URL(t.config.MCP_URL ?? ""), {
      fetch: (async (url: string | URL, init?: RequestInit) =>
        mcp.request(String(url), init)) as typeof fetch,
      requestInit: { headers: { authorization: `Bearer ${token}` } },
    }),
  );
  return client;
}

test("an assistant notes an expense that the person then sees, saved as mcp", async () => {
  const { accessToken } = await t.authorize("e2e@lukas.test", { headers });
  const client = await connect(accessToken);
  const result = await client.callTool({
    name: "add_transactions",
    arguments: {
      items: [{ name: "Almuerzo", amount: 18000, kind: "expense", category: "almuerzos" }],
    },
  });
  expect(result.isError).toBeFalsy();
  await client.close();
  const res = await t.request("GET", "/v1/transactions?q=almuerzo", { headers });
  const { items } = (await res.json()) as { items: { amount: number; source: string }[] };
  expect(items).toEqual([expect.objectContaining({ amount: -1800000, source: "mcp" })]);
});

test("a token for another audience never gets past the MCP", async () => {
  const jwt = (await (await t.request("GET", "/auth/token", { headers })).json()) as {
    token: string;
  };
  const res = await mcp.request(t.config.MCP_URL ?? "", {
    method: "POST",
    headers: { "content-type": "application/json", authorization: `Bearer ${jwt.token}` },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "ping" }),
  });
  expect(res.status).toBe(401);
});
