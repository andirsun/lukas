import { ToolError } from "@lukas/ai-assistant-tools";
import { afterAll, beforeAll, expect, test } from "vitest";
import { createTestApp, type TestApp } from "../../api/test/harness.ts";
import { apiLukitas } from "../src/api-lukitas.ts";

// The real API (and a real database), reached in-process with an assistant's real access token.
let t: TestApp;
let lukitas: ReturnType<typeof apiLukitas>;
let categoryId: string;
beforeAll(async () => {
  t = await createTestApp();
  const { headers } = await t.signIn("mcp@lukas.test");
  const res = await t.request("POST", "/v1/categories", {
    headers,
    body: { name: "Comida", kind: "expense", icon: "food", color: "orange" },
  });
  categoryId = ((await res.json()) as { id: string }).id;
  const { accessToken } = await t.authorize("mcp@lukas.test", { headers });
  const fetchApi = (async (input: string | URL | Request, init?: RequestInit) =>
    t.app.request(input instanceof Request ? input : String(input), init)) as typeof fetch;
  lukitas = apiLukitas(t.config.API_URL, accessToken, fetchApi);
});
afterAll(() => t?.stop());

const item = { name: "Almuerzo", amount: -1800000, date: "2026-10-30" };

test("the profile and categories come from the API", async () => {
  expect(await lukitas.profile()).toMatchObject({
    locale: expect.any(String),
    currency: expect.any(String),
  });
  expect((await lukitas.listCategories()).map((c) => c.name)).toEqual(["Comida"]);
});

test("add, list, delete and restore round-trip, saved as mcp", async () => {
  const saved = await lukitas.addTransactions(
    [{ ...item, categoryId, status: "paid", source: "mcp" }],
    "key-1",
  );
  expect(saved.replayed).toBe(false);
  expect(saved.items[0]).toMatchObject({ name: "Almuerzo", source: "mcp" });
  const id = saved.items[0]?.id ?? "";
  expect((await lukitas.listTransactions({ q: "almu", limit: 10 })).items.map((i) => i.id)).toEqual(
    [id],
  );
  await lukitas.deleteTransactions([id]);
  expect((await lukitas.listTransactions({ month: "2026-10", limit: 10 })).items).toEqual([]);
  await lukitas.restoreTransaction(id);
  expect((await lukitas.listTransactions({ month: "2026-10", limit: 10 })).items).toHaveLength(1);
});

test("the same batch with the same key is a replay and saves nothing", async () => {
  const batch = [
    { ...item, name: "Taxi", categoryId, status: "paid" as const, source: "mcp" as const },
  ];
  await lukitas.addTransactions(batch, "key-2");
  const again = await lukitas.addTransactions(batch, "key-2");
  expect(again.replayed).toBe(true);
  expect((await lukitas.listTransactions({ q: "taxi", limit: 10 })).items).toHaveLength(1);
});

test("an API problem becomes a ToolError with its code", async () => {
  const error = await lukitas
    .updateTransaction("00000000-0000-4000-8000-000000000000", { name: "x" })
    .catch((e: unknown) => e);
  expect(error).toBeInstanceOf(ToolError);
  expect((error as ToolError).code).toBe("not_found");
});
