import { MemoryLukitas, PROMPTS, TOOLS } from "@lukas/ai-assistant-tools";
import { Client, StreamableHTTPClientTransport } from "@modelcontextprotocol/client";
import { type AuthInfo, OAuthError, OAuthErrorCode } from "@modelcontextprotocol/server";
import { beforeEach, describe, expect, test } from "vitest";
import { createMcpApp } from "../src/app.ts";

const MCP_URL = "http://localhost:3001/mcp";
const CATEGORY = {
  id: "00000000-0000-4000-8000-000000000001",
  name: "Comida",
  kind: "expense" as const,
  icon: "🍔",
  color: "#f80",
  sortOrder: 0,
  archived: false,
  currentBudget: null,
};

/** Tokens the fake verifier knows: their scopes. */
const TOKENS: Record<string, string[]> = {
  write: ["finance:read", "finance:write", "offline_access"],
  read: ["finance:read"],
};

let lukitas: MemoryLukitas;
let app: ReturnType<typeof createMcpApp>;
beforeEach(() => {
  lukitas = new MemoryLukitas({ categories: [CATEGORY], profile: { locale: "en" } });
  app = createMcpApp({
    config: {
      MCP_URL,
      AUTH_ISSUER: "http://localhost:5173/api/auth",
      RATE_LIMIT_PER_MINUTE: 30,
    },
    verifier: {
      async verifyAccessToken(token): Promise<AuthInfo> {
        const scopes = TOKENS[token];
        if (!scopes) throw new OAuthError(OAuthErrorCode.InvalidToken, "unknown token");
        return {
          token,
          clientId: `client-${token}`,
          scopes,
          expiresAt: Math.floor(Date.now() / 1000) + 900,
          resource: new URL(MCP_URL),
          extra: { userId: "user-1" },
        };
      },
    },
    lukitasFor: () => lukitas,
  });
});

const fetchApp = (async (url: string | URL, init?: RequestInit) =>
  app.request(String(url), init)) as typeof fetch;

async function connect(token: string, mode: "modern" | "legacy") {
  const client = new Client(
    { name: "test", version: "1.0.0" },
    mode === "modern" ? { versionNegotiation: { mode: { pin: "2026-07-28" } } } : {},
  );
  const transport = new StreamableHTTPClientTransport(new URL(MCP_URL), {
    fetch: fetchApp,
    requestInit: { headers: { authorization: `Bearer ${token}` } },
  });
  await client.connect(transport);
  return client;
}

describe("OAuth discovery", () => {
  test("no token is a 401 pointing to the protected resource metadata", async () => {
    const res = await app.request(MCP_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: "{}",
    });
    expect(res.status).toBe(401);
    expect(res.headers.get("www-authenticate")).toContain(
      'resource_metadata="http://localhost:3001/.well-known/oauth-protected-resource/mcp"',
    );
  });

  test("an unknown token is a 401 too", async () => {
    const res = await app.request(MCP_URL, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: "Bearer nope" },
      body: "{}",
    });
    expect(res.status).toBe(401);
  });

  test("the metadata names the API's authorization server", async () => {
    for (const path of [
      "/.well-known/oauth-protected-resource/mcp",
      "/.well-known/oauth-protected-resource",
    ]) {
      const res = await app.request(path);
      expect(res.status).toBe(200);
      expect(await res.json()).toMatchObject({
        resource: MCP_URL,
        authorization_servers: ["http://localhost:5173/api/auth"],
        scopes_supported: ["finance:read", "finance:write", "offline_access"],
      });
    }
  });
});

describe.each(["modern", "legacy"] as const)("the %s protocol", (mode) => {
  test("speaks the expected revision", async () => {
    const client = await connect("write", mode);
    expect(client.getNegotiatedProtocolVersion()).toBe(
      mode === "modern" ? "2026-07-28" : "2025-11-25",
    );
    expect(client.getInstructions()).toContain("18 lukas");
    await client.close();
  });

  test("lists every tool in the fixed order, with annotations and an output schema", async () => {
    const client = await connect("write", mode);
    const { tools } = await client.listTools();
    expect(tools.map((t) => t.name)).toEqual(TOOLS.map((t) => t.name));
    const overview = tools.find((t) => t.name === "get_month_overview");
    expect(overview?.annotations).toMatchObject({ readOnlyHint: true, destructiveHint: false });
    expect(overview?.outputSchema).toBeDefined();
    expect(tools.find((t) => t.name === "delete_transactions")?.annotations?.destructiveHint).toBe(
      true,
    );
    await client.close();
  });

  test("add_transactions saves, with structured content and a text summary", async () => {
    const client = await connect("write", mode);
    const result = await client.callTool({
      name: "add_transactions",
      arguments: {
        items: [{ name: "Almuerzo", amount: 18000, kind: "expense", category: "comida" }],
      },
    });
    expect(result.isError).toBeFalsy();
    expect(result.structuredContent).toMatchObject({ alreadySaved: false });
    expect((result.content as { type: string; text: string }[])[0]?.text).toContain("Almuerzo");
    const { items } = await lukitas.listTransactions({ limit: 10 });
    expect(items.map((i) => [i.name, i.amount])).toEqual([["Almuerzo", -1800000]]);
    await client.close();
  });

  test("a problem the model can fix is a tool error, not a crash", async () => {
    const client = await connect("write", mode);
    const result = await client.callTool({
      name: "add_transactions",
      arguments: { items: [{ name: "Cine", amount: 20000, kind: "expense", category: "ocio" }] },
    });
    expect(result.isError).toBe(true);
    expect((result.content as { text: string }[])[0]?.text).toContain("category_not_found");
    await client.close();
  });

  test("prompts are listed and written in the person's language", async () => {
    const client = await connect("write", mode);
    const { prompts } = await client.listPrompts();
    expect(prompts.map((p) => p.name)).toEqual(PROMPTS.map((p) => p.name));
    expect(prompts[0]?.title).toBe("Month review");
    const prompt = await client.getPrompt({ name: "como-voy", arguments: {} });
    expect(prompt.messages.length).toBeGreaterThan(0);
    await client.close();
  });
});

test("a finance:read token cannot write: the write tool asks for the scope", async () => {
  const client = await connect("read", "modern");
  const read = await client.callTool({ name: "list_categories", arguments: {} });
  expect(read.isError).toBeFalsy();
  await expect(
    client.callTool({
      name: "add_transactions",
      arguments: {
        items: [{ name: "Almuerzo", amount: 18000, kind: "expense", category: "comida" }],
      },
    }),
  ).rejects.toThrow();
  expect((await lukitas.listTransactions({ limit: 10 })).items).toEqual([]);
  await client.close();
});

test("one assistant past its budget per minute gets 429", async () => {
  const post = () =>
    app.request(MCP_URL, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: "Bearer read",
        accept: "application/json, text/event-stream",
      },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "ping" }),
    });
  for (let i = 0; i < 30; i++) expect((await post()).status).not.toBe(429);
  const over = await post();
  expect(over.status).toBe(429);
  expect(over.headers.get("retry-after")).toBe("60");
});
