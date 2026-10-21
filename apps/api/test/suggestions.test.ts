import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let b: { authorization: string };
let supermercado: string;
let restaurante: string;

interface Suggestion {
  name: string;
  categoryId: string;
}

async function category(headers: typeof a, name: string) {
  const res = await t.request("POST", "/v1/categories", {
    headers,
    body: { name, kind: "expense", icon: "star", color: "purple" },
  });
  return ((await res.json()) as { id: string }).id;
}

async function seed(headers: typeof a, categoryId: string, name: string, date: string) {
  const res = await t.request("POST", "/v1/transactions", {
    headers,
    body: { categoryId, name, amount: -500, date },
  });
  expect(res.status).toBe(201);
  return ((await res.json()) as { id: string }).id;
}

const suggest = async (query = "", headers = a) => {
  const res = await t.request("GET", `/v1/transactions/suggestions${query}`, { headers });
  expect(res.status).toBe(200);
  return (await res.json()) as { items: Suggestion[] };
};
const names = async (query = "", headers = a) =>
  (await suggest(query, headers)).items.map((i) => i.name);

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  b = (await t.signIn("b@lukas.test")).headers;
  supermercado = await category(a, "Supermercado");
  restaurante = await category(a, "Restaurante");
  const old = await category(a, "Old");

  // Oldest -> newest: continente x3, Continente, pingo doce, café x2.
  await seed(a, supermercado, "continente", "2026-10-01");
  await seed(a, supermercado, "continente", "2026-10-02");
  await seed(a, supermercado, "continente", "2026-10-03");
  await seed(a, supermercado, "Continente", "2026-10-04");
  await seed(a, supermercado, "pingo doce", "2026-10-05");
  await seed(a, restaurante, "café", "2026-10-06");
  await seed(a, restaurante, "café", "2026-10-07");

  // Never suggested: soft-deleted, named like its category, or in an archived category.
  const secret = await seed(a, supermercado, "secret", "2026-10-08");
  await t.request("DELETE", `/v1/transactions/${secret}`, { headers: a });
  await seed(a, restaurante, "restaurante", "2026-10-09");
  await seed(a, old, "forgotten", "2026-10-10");
  await t.request("PATCH", `/v1/categories/${old}`, { headers: a, body: { archived: true } });
});
afterAll(() => t?.stop());

describe("transaction name suggestions", () => {
  test("distinct by lowercase name, most recent spelling, most recent first", async () => {
    const { items } = await suggest();
    expect(items.map((i) => i.name)).toEqual(["café", "pingo doce", "Continente"]);
    expect(items.find((i) => i.name.toLowerCase() === "continente")?.categoryId).toBe(supermercado);
    expect(items.find((i) => i.name === "café")?.categoryId).toBe(restaurante);
  });

  test("q matches by prefix first, then by substring, then by recency", async () => {
    expect(await names("?q=pin")).toEqual(["pingo doce"]);
    expect(await names("?q=doce")).toEqual(["pingo doce"]);
    expect(await names("?q=CONT")).toEqual(["Continente"]);
    // "pingo doce" only contains a "c", so it trails the two prefix matches.
    expect(await names("?q=c")).toEqual(["café", "Continente", "pingo doce"]);
  });

  test("excludes deleted transactions, names equal to their category and archived categories", async () => {
    expect(await names("?q=secret")).toEqual([]);
    expect(await names("?q=restaurante")).toEqual([]);
    expect(await names("?q=forgotten")).toEqual([]);
  });

  test("limit caps the list and is validated", async () => {
    expect(await names("?limit=2")).toEqual(["café", "pingo doce"]);
    for (const limit of ["0", "21"]) {
      const res = await t.request("GET", `/v1/transactions/suggestions?limit=${limit}`, {
        headers: a,
      });
      expect(res.status).toBe(422);
    }
  });

  test("a name used with several categories suggests the most frequent, ties the most recent", async () => {
    await seed(a, restaurante, "lidl", "2026-11-01");
    await seed(a, supermercado, "lidl", "2026-11-02");
    await seed(a, supermercado, "lidl", "2026-11-03");
    await seed(a, restaurante, "lidl", "2026-11-04");
    // 2 vs 2: the tie goes to the category used most recently.
    expect((await suggest("?q=lidl")).items).toEqual([{ name: "lidl", categoryId: restaurante }]);
    await seed(a, supermercado, "lidl", "2026-11-05");
    expect((await suggest("?q=lidl")).items).toEqual([{ name: "lidl", categoryId: supermercado }]);
  });

  test("the most used category wins over a more recent one", async () => {
    await seed(a, restaurante, "padaria", "2026-12-01");
    await seed(a, restaurante, "padaria", "2026-12-02");
    await seed(a, restaurante, "padaria", "2026-12-03");
    await seed(a, supermercado, "padaria", "2026-12-04"); // newest, but used only once
    expect((await suggest("?q=padaria")).items).toEqual([
      { name: "padaria", categoryId: restaurante },
    ]);
  });

  test("users never see each other's names", async () => {
    expect(await names("", b)).toEqual([]);
    const mine = await category(b, "Casa");
    await seed(b, mine, "ikea", "2026-10-01");
    expect(await names("", b)).toEqual(["ikea"]);
    expect(await names("?q=ikea", a)).toEqual([]);
    expect(await names("", a)).not.toContain("ikea");
  });

  test("requires authentication", async () => {
    const res = await t.request("GET", "/v1/transactions/suggestions");
    expect(res.status).toBe(401);
  });
});
