import { addMonths, type MonthSummary, monthOf, type TransactionDto, todayIn } from "@lukas/core";
import { describe, expect, it } from "vitest";
import { type ApiClient, createApiClient } from "../api/client.ts";
import type { ApiProblem } from "../api/errors.ts";
import type { Locale } from "../i18n/format.ts";
import { createDemoBackend } from "./demo-backend.ts";
import { DEMO_SEED } from "./demo-data.ts";

/** Mid-afternoon in Bogotá and Lisbon on 21 October 2026. */
const OCT_21 = new Date("2026-10-21T18:00:00Z");

const clock = (at: Date) => () => new Date(at);

function demo(locale: Locale = "es", at: Date = OCT_21) {
  const backend = createDemoBackend(DEMO_SEED[locale], clock(at));
  const api = createApiClient({
    fetch: backend.fetch,
    baseUrl: "http://demo.test/api",
    onUnauthorized: () => {
      throw new Error("the demo is always signed in");
    },
  });
  return { backend, api };
}

async function summary(api: ApiClient, month?: string): Promise<MonthSummary> {
  const { data } = await api.GET("/v1/summary", { params: { query: month ? { month } : {} } });
  return data as MonthSummary;
}

async function list(api: ApiClient, month: string): Promise<TransactionDto[]> {
  const { data } = await api.GET("/v1/transactions", { params: { query: { month, limit: 200 } } });
  return data?.items ?? [];
}

async function firstExpenseCategory(api: ApiClient): Promise<string> {
  const { data } = await api.GET("/v1/categories");
  const category = data?.find((c) => c.kind === "expense");
  if (!category) throw new Error("the seed has expense categories");
  return category.id;
}

/** Everything the screens read, for comparing two backends. */
async function snapshot(api: ApiClient, current: string) {
  const months = [addMonths(current, -2), addMonths(current, -1), current, addMonths(current, 1)];
  const perMonth = [];
  for (const month of months) {
    perMonth.push({ summary: await summary(api, month), items: await list(api, month) });
  }
  return {
    me: (await api.GET("/v1/me")).data,
    categories: (
      await api.GET("/v1/categories", { params: { query: { includeArchived: "true" } } })
    ).data,
    recurrences: (await api.GET("/v1/recurrences")).data,
    months: perMonth,
    trend: (
      await api.GET("/v1/reports/trend", {
        params: { query: { from: addMonths(current, -5), to: current } },
      })
    ).data,
    living: (await api.GET("/v1/reports/cost-of-living", { params: { query: { months: 2 } } }))
      .data,
    suggestions: (await api.GET("/v1/transactions/suggestions", { params: { query: { q: "" } } }))
      .data,
  };
}

describe("the demo's invented user", () => {
  it("is Valentina in pesos and Bogotá in Spanish, in euros and Lisbon in English", async () => {
    const es = (await demo("es").api.GET("/v1/me")).data;
    expect(es).toMatchObject({
      email: "valentina@demo.lukas.app",
      locale: "es",
      timezone: "America/Bogota",
      currency: "COP",
    });
    expect(es?.onboardingCompletedAt).not.toBeNull();
    const en = (await demo("en").api.GET("/v1/me")).data;
    expect(en).toMatchObject({
      email: "valentina@demo.lukas.app",
      locale: "en",
      timezone: "Europe/Lisbon",
      currency: "EUR",
    });
    expect(DEMO_SEED.es.profile.name).toBe("Valentina (demo)");
  });

  it("has 8 spending categories and a salary, with budgets, and rent, Spotify and salary recurring", async () => {
    for (const locale of ["es", "en"] as const) {
      const { api } = demo(locale);
      const categories = (await api.GET("/v1/categories")).data ?? [];
      expect(categories.filter((c) => c.kind === "expense")).toHaveLength(8);
      expect(categories.filter((c) => c.kind === "income")).toHaveLength(1);
      expect(categories.filter((c) => c.currentBudget !== null).length).toBeGreaterThan(0);
      const recurrences = (await api.GET("/v1/recurrences")).data ?? [];
      expect(recurrences.map((r) => r.name)).toEqual(
        locale === "es" ? ["Arriendo", "Spotify", "Salario"] : ["Rent", "Spotify", "Salary"],
      );
    }
  });

  it("spends on a Colombian scale in Spanish: rent around 1.800.000, a coffee around 8.000", async () => {
    const { api } = demo("es");
    const items = await list(api, "2026-10");
    const rent = items.find((t) => t.name === "Arriendo");
    expect(rent?.amount).toBe(-1_800_000_00);
    const coffees = items.filter((t) => t.amount > -20_000_00 && t.amount <= -5_000_00);
    expect(coffees.length).toBeGreaterThan(3);
    expect(items.every((t) => t.currency === "COP")).toBe(true);
  });

  it("has the last 3 months of transactions, and none after today", async () => {
    const { api } = demo();
    for (const month of ["2026-08", "2026-09", "2026-10"]) {
      expect((await list(api, month)).length).toBeGreaterThan(10);
    }
    expect(await list(api, "2026-07")).toEqual([]);
    const paid = (await list(api, "2026-10")).filter((t) => t.status === "paid");
    expect(paid.every((t) => t.date <= "2026-10-21")).toBe(true);
  });
});

describe("GET /api/v1/summary", () => {
  it("has a category over its budget and one near it this month, whatever the day", async () => {
    for (const locale of ["es", "en"] as const) {
      for (const at of ["2026-10-01T15:00:00Z", OCT_21.toISOString(), "2026-12-31T15:00:00Z"]) {
        const { api } = demo(locale, new Date(at));
        const s = await summary(api);
        expect(s.month).toBe(monthOf(todayIn(DEMO_SEED[locale].profile.timezone, new Date(at))));
        expect(s.categories.filter((c) => c.state === "over").length).toBeGreaterThanOrEqual(1);
        expect(s.categories.filter((c) => c.state === "near").length).toBeGreaterThanOrEqual(1);
        // Something is left to spend: home's "Te quedan" is not zero.
        expect(s.remaining).toBeGreaterThan(0);
      }
    }
  });
});

describe("writes", () => {
  it("POST /api/v1/transactions raises the month's spending by its amount", async () => {
    const { api } = demo();
    const before = await summary(api, "2026-10");
    const categoryId = await firstExpenseCategory(api);
    const created = await api.POST("/v1/transactions", {
      body: { name: "Empanadas", amount: -5_000_00, categoryId, date: "2026-10-21" },
    });
    expect(created.response.status).toBe(201);
    expect(created.data).toMatchObject({ name: "Empanadas", currency: "COP", status: "paid" });
    const after = await summary(api, "2026-10");
    expect(after.spent).toBe(before.spent + 5_000_00);
    expect(after.remaining).toBe(before.remaining - 5_000_00);
  });

  it("DELETE then POST …/restore brings the same transaction back", async () => {
    const { api } = demo();
    const first = (await list(api, "2026-10")).find((t) => t.amount < 0 && t.status === "paid");
    if (!first) throw new Error("the seed has paid expenses this month");
    const before = await summary(api, "2026-10");

    const deleted = await api.DELETE("/v1/transactions/{id}", {
      params: { path: { id: first.id } },
    });
    expect(deleted.response.status).toBe(204);
    expect((await list(api, "2026-10")).some((t) => t.id === first.id)).toBe(false);
    expect((await summary(api, "2026-10")).spent).not.toBe(before.spent);

    const restored = await api.POST("/v1/transactions/{id}/restore", {
      params: { path: { id: first.id } },
    });
    expect(restored.data).toEqual(first);
    expect(await list(api, "2026-10")).toContainEqual(first);
    expect(await summary(api, "2026-10")).toEqual(before);
  });

  it("answers an invalid body with 422 validation_failed, as the API does", async () => {
    const { api } = demo();
    const categoryId = await firstExpenseCategory(api);
    const attempt = api.POST("/v1/transactions", {
      body: { name: "", amount: 0, categoryId, date: "2026-13-01" },
    });
    await expect(attempt).rejects.toMatchObject({ status: 422, code: "validation_failed" });
    const problem = (await attempt.catch((error: unknown) => error)) as ApiProblem;
    expect(problem.errors.map((e) => e.path)).toEqual(
      expect.arrayContaining(["name", "amount", "date"]),
    );
  });

  it("answers an unknown or archived category with 422 category_not_found", async () => {
    const { api } = demo();
    await expect(
      api.POST("/v1/transactions", {
        body: {
          name: "Taxi",
          amount: -1_000,
          categoryId: "11111111-1111-4111-8111-111111111111",
          date: "2026-10-21",
        },
      }),
    ).rejects.toMatchObject({ status: 422, code: "category_not_found" });
  });

  it("keeps the currency once there are transactions: 409 currency_locked", async () => {
    const { api } = demo();
    await expect(api.PATCH("/v1/me", { body: { currency: "EUR" } })).rejects.toMatchObject({
      status: 409,
      code: "currency_locked",
    });
    const me = await api.PATCH("/v1/me", { body: { locale: "en" } });
    expect(me.data).toMatchObject({ locale: "en", currency: "COP" });
  });

  it("reset() goes back to the seed", async () => {
    const { api, backend } = demo();
    const seeded = await snapshot(api, "2026-10");
    const categoryId = await firstExpenseCategory(api);
    await api.POST("/v1/transactions", {
      body: { name: "Empanadas", amount: -5_000_00, categoryId, date: "2026-10-21" },
    });
    await api.PATCH("/v1/me", { body: { locale: "en" } });
    expect(await snapshot(api, "2026-10")).not.toEqual(seeded);
    backend.reset();
    expect(await snapshot(api, "2026-10")).toEqual(seeded);
  });

  it("is deterministic: two backends from the same seed and clock answer the same", async () => {
    for (const locale of ["es", "en"] as const) {
      const one = demo(locale);
      const two = demo(locale);
      expect(await snapshot(two.api, "2026-10")).toEqual(await snapshot(one.api, "2026-10"));
    }
  });
});
