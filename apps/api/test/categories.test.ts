import { addMonths, monthOf, todayIn } from "@lukas/core";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { createTestApp, type TestApp } from "./harness.ts";

let t: TestApp;
let a: { authorization: string };
let b: { authorization: string };
const thisMonth = monthOf(todayIn("UTC"));

beforeAll(async () => {
  t = await createTestApp();
  a = (await t.signIn("a@lukas.test")).headers;
  b = (await t.signIn("b@lukas.test")).headers;
});
afterAll(() => t?.stop());

const create = (headers: typeof a, body: object) =>
  t.request("POST", "/v1/categories", { headers, body });
const list = async (headers: typeof a, query = "") =>
  (await (await t.request("GET", `/v1/categories${query}`, { headers })).json()) as {
    id: string;
    name: string;
    currentBudget: number | null;
    archived: boolean;
  }[];

const ocio = { name: "Ocio", kind: "expense", icon: "star", color: "purple" };

describe("categories", () => {
  let ocioId: string;

  test("create and list", async () => {
    const res = await create(a, ocio);
    expect(res.status).toBe(201);
    const created = (await res.json()) as { id: string };
    ocioId = created.id;
    expect(created).toMatchObject({ ...ocio, archived: false, currentBudget: null, sortOrder: 0 });
    expect((await list(a)).map((c) => c.name)).toEqual(["Ocio"]);
  });

  test("names are unique per user, case-insensitively", async () => {
    const res = await create(a, { ...ocio, name: "ocio" });
    expect(res.status).toBe(409);
    expect(await res.json()).toMatchObject({ code: "category_name_taken" });
    expect((await create(b, ocio)).status).toBe(201);
  });

  test("set the budget for the current month and upsert it", async () => {
    const put = (amount: number, effectiveFrom: string) =>
      t.request("PUT", `/v1/categories/${ocioId}/budget`, {
        headers: a,
        body: { amount, effectiveFrom },
      });
    let res = await put(65000, thisMonth);
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ currentBudget: 65000 });
    res = await put(70000, thisMonth);
    expect(await res.json()).toMatchObject({ currentBudget: 70000 });
    res = await put(99000, addMonths(thisMonth, 1));
    expect(await res.json()).toMatchObject({ currentBudget: 70000 });
  });

  test("income categories cannot have a budget", async () => {
    const salary = (await (
      await create(a, { name: "Salário", kind: "income", icon: "salary", color: "green" })
    ).json()) as { id: string };
    const res = await t.request("PUT", `/v1/categories/${salary.id}/budget`, {
      headers: a,
      body: { amount: 100, effectiveFrom: thisMonth },
    });
    expect(res.status).toBe(422);
    expect(await res.json()).toMatchObject({ code: "budget_category_not_expense" });
  });

  test("archived categories are hidden unless requested", async () => {
    const res = await t.request("PATCH", `/v1/categories/${ocioId}`, {
      headers: a,
      body: { archived: true },
    });
    expect(res.status).toBe(200);
    expect((await list(a)).map((c) => c.name)).not.toContain("Ocio");
    const all = await list(a, "?includeArchived=true");
    expect(all.find((c) => c.id === ocioId)?.archived).toBe(true);
  });

  test("other users' categories are not found", async () => {
    const res = await t.request("PATCH", `/v1/categories/${ocioId}`, {
      headers: b,
      body: { name: "Mine" },
    });
    expect(res.status).toBe(404);
    const budget = await t.request("PUT", `/v1/categories/${ocioId}/budget`, {
      headers: b,
      body: { amount: 1, effectiveFrom: thisMonth },
    });
    expect(budget.status).toBe(404);
  });

  test("invalid input is a 422 validation problem", async () => {
    const res = await create(a, { name: "", kind: "nope" });
    expect(res.status).toBe(422);
    expect(await res.json()).toMatchObject({ code: "validation_failed" });
  });
});

describe("changing a category's kind", () => {
  let c: { authorization: string };
  beforeAll(async () => {
    c = (await t.signIn("kind@lukas.test")).headers;
  });
  const patch = (id: string, body: object) =>
    t.request("PATCH", `/v1/categories/${id}`, { headers: c, body });

  test("works without transactions, keeping the category (same id, same name)", async () => {
    const created = (await (
      await create(c, { name: "Salario", kind: "income", icon: "💰", color: "#2fd388" })
    ).json()) as { id: string };
    const res = await patch(created.id, { kind: "expense" });
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ id: created.id, name: "Salario", kind: "expense" });
    expect(
      (await list(c, "?includeArchived=true")).filter((x) => x.name === "Salario"),
    ).toHaveLength(1);
  });

  test("is refused while the category has transactions, soft-deleted ones included", async () => {
    const created = (await (
      await create(c, { name: "Casa", kind: "expense", icon: "🏠", color: "#6d6bff" })
    ).json()) as { id: string };
    const tx = (await (
      await t.request("POST", "/v1/transactions", {
        headers: c,
        body: { name: "rent", amount: -50_000, categoryId: created.id, date: `${thisMonth}-01` },
      })
    ).json()) as { id: string };
    const refused = await patch(created.id, { kind: "income" });
    expect(refused.status).toBe(409);
    expect(await refused.json()).toMatchObject({ code: "category_has_transactions" });
    // Renaming is still fine.
    expect((await patch(created.id, { name: "Hogar" })).status).toBe(200);
    // A soft-deleted transaction still counts: restoring it would leave a mis-signed row under
    // the other kind.
    await t.request("DELETE", `/v1/transactions/${tx.id}`, { headers: c });
    const stillRefused = await patch(created.id, { kind: "income" });
    expect(stillRefused.status).toBe(409);
    expect(await stillRefused.json()).toMatchObject({ code: "category_has_transactions" });
    expect(
      (await t.request("POST", `/v1/transactions/${tx.id}/restore`, { headers: c })).status,
    ).toBe(200);
    const restored = (await list(c)).find((x) => x.id === created.id) as unknown as {
      kind: string;
    };
    expect(restored.kind).toBe("expense");
  });
});
