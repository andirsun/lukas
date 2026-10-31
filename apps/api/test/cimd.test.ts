import { fetchClientMetadataResource } from "@better-auth/cimd/node";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { ASSISTANT_REDIRECT, createTestApp, type TestApp } from "./harness.ts";

const CLIENT_ID = "https://claude.ai/oauth/mcp-oauth-client-metadata";
const document = {
  client_id: CLIENT_ID,
  client_name: "Claude",
  client_uri: "https://claude.ai",
  logo_uri: "https://claude.ai/logo.png",
  redirect_uris: [ASSISTANT_REDIRECT],
  token_endpoint_auth_method: "none",
  grant_types: ["authorization_code", "refresh_token"],
  response_types: ["code"],
};

/** What the stub answers for each client_id URL, and which URLs it was asked for. */
const answers = new Map<string, () => Response>();
const asked: string[] = [];
const stubFetch = async (input: string | URL | Request) => {
  const url = String(input instanceof Request ? input.url : input);
  asked.push(url);
  const answer = answers.get(url);
  return answer ? answer() : new Response("not found", { status: 404 });
};

let t: TestApp;
beforeAll(async () => {
  t = await createTestApp({}, { fetchClientMetadata: stubFetch });
});
afterAll(() => t?.stop());

const authorizeQuery = (clientId: string) =>
  new URLSearchParams({
    response_type: "code",
    client_id: clientId,
    redirect_uri: ASSISTANT_REDIRECT,
    scope: "finance:read finance:write",
    state: "s",
    code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM",
    code_challenge_method: "S256",
    resource: "http://localhost:3001/mcp",
  });

describe("Client ID Metadata Documents", () => {
  test("a client_id URL is resolved from its document and asks for consent", async () => {
    answers.set(CLIENT_ID, () =>
      Response.json(document, { headers: { "cache-control": "max-age=60" } }),
    );
    const { headers } = await t.signIn("cimd@lukas.test");
    const res = await t.request("GET", `/auth/oauth2/authorize?${authorizeQuery(CLIENT_ID)}`, {
      headers,
    });
    expect(res.headers.get("location") ?? "").toContain("/oauth/consent?");
    expect(asked).toContain(CLIENT_ID);
  });

  test("a document behind a redirect is refused", async () => {
    const moved = "https://evil.example/oauth/client.json";
    answers.set(
      moved,
      () => new Response(null, { status: 302, headers: { location: "https://claude.ai/x" } }),
    );
    const { headers } = await t.signIn("redirect@lukas.test");
    const res = await t.request("GET", `/auth/oauth2/authorize?${authorizeQuery(moved)}`, {
      headers,
    });
    expect(res.headers.get("location") ?? "").not.toContain("/oauth/consent?");
  });

  test("a document whose client_id is another URL is refused", async () => {
    const other = "https://other.example/client.json";
    answers.set(other, () => Response.json(document));
    const { headers } = await t.signIn("mismatch@lukas.test");
    const res = await t.request("GET", `/auth/oauth2/authorize?${authorizeQuery(other)}`, {
      headers,
    });
    expect(res.headers.get("location") ?? "").not.toContain("/oauth/consent?");
  });

  test("the default fetch refuses private and special-use addresses", async () => {
    for (const url of [
      "https://127.0.0.1/client.json",
      "https://10.0.0.5/client.json",
      "https://169.254.169.254/latest/meta-data",
      "https://[::1]/client.json",
      "https://localhost/client.json",
    ]) {
      await expect(fetchClientMetadataResource(url), url).rejects.toThrow();
    }
  });
});
