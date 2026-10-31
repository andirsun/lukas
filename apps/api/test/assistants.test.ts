import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
beforeAll(async () => {
  t = await createTestApp();
});
afterAll(() => t?.stop());

interface Assistant {
  clientId: string;
  name: string;
  domain: string | null;
  scopes: string[];
  connectedAt: string;
  lastUsedAt: string | null;
}
const list = async (headers: { authorization: string }) => {
  const res = await t.request("GET", "/v1/me/assistants", { headers });
  expect(res.status).toBe(200);
  return ((await res.json()) as { items: Assistant[] }).items;
};

describe("connected assistants", () => {
  test("lists the assistants the person let in, with their domain and scopes", async () => {
    const { headers } = await t.signIn("list@lukas.test");
    expect(await list(headers)).toEqual([]);
    const { clientId } = await t.authorize("list@lukas.test", { headers });
    const [assistant, ...rest] = await list(headers);
    expect(rest).toEqual([]);
    expect(assistant).toMatchObject({
      clientId,
      name: "Claude",
      domain: "claude.ai",
      scopes: ["finance:read", "finance:write", "offline_access"],
    });
    expect(assistant?.lastUsedAt).not.toBeNull();
  });

  test("someone else's assistants are not listed", async () => {
    await t.authorize("owner@lukas.test");
    const { headers } = await t.signIn("stranger@lukas.test");
    expect(await list(headers)).toEqual([]);
  });

  test("revoking deletes the consent and its refresh tokens", async () => {
    const { headers } = await t.signIn("revoke@lukas.test");
    const tokens = await t.authorize("revoke@lukas.test", { headers });
    const res = await t.request("DELETE", `/v1/me/assistants/${tokens.clientId}`, { headers });
    expect(res.status).toBe(204);
    expect(await list(headers)).toEqual([]);
    const refresh = await t.tokenRequest({
      grant_type: "refresh_token",
      refresh_token: tokens.refreshToken,
      client_id: tokens.clientId,
    });
    expect(refresh.status).toBe(400);
    expect(((await refresh.json()) as { error: string }).error).toBe("invalid_grant");
  });

  test("revoking someone else's assistant is a 404 and leaves it", async () => {
    const theirs = await t.authorize("victim@lukas.test");
    const { headers } = await t.signIn("attacker@lukas.test");
    const res = await t.request("DELETE", `/v1/me/assistants/${theirs.clientId}`, { headers });
    expect(res.status).toBe(404);
    const refresh = await t.tokenRequest({
      grant_type: "refresh_token",
      refresh_token: theirs.refreshToken,
      client_id: theirs.clientId,
    });
    expect(refresh.status).toBe(200);
  });

  test("a client_id that is a URL (CIMD) reaches the route, encoded", async () => {
    const { headers } = await t.signIn("cimd-revoke@lukas.test");
    const id = encodeURIComponent("https://claude.ai/oauth/mcp-oauth-client-metadata");
    const res = await t.request("DELETE", `/v1/me/assistants/${id}`, { headers });
    expect(res.status).toBe(404);
    expect(((await res.json()) as { detail?: string }).detail).toBe("Assistant not found");
  });
});
