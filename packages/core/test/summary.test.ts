import { describe, expect, test } from "vitest";
import {
  type BudgetEntry,
  effectiveBudget,
  monthSummary,
  type SummaryInput,
} from "../src/index.ts";
import { OCTOBER_2026 } from "./fixtures/october-2026.ts";

function october(): SummaryInput {
  return {
    month: OCTOBER_2026.month,
    categories: [
      ...OCTOBER_2026.expense.map((c) => ({ id: c.key, kind: "expense" as const })),
      ...OCTOBER_2026.income.map((c) => ({ id: c.key, kind: "income" as const })),
    ],
    budgets: OCTOBER_2026.expense.map((c) => ({
      categoryId: c.key,
      amount: c.budget,
      effectiveFrom: "2026-01",
    })),
    transactions: [
      ...OCTOBER_2026.expense
        .filter((c) => c.spent > 0)
        .map((c) => ({ categoryId: c.key, amount: -c.spent })),
      ...OCTOBER_2026.income.map((c) => ({ categoryId: c.key, amount: c.received })),
    ],
  };
}

const byId = (s: ReturnType<typeof monthSummary>) =>
  Object.fromEntries(s.categories.map((c) => [c.categoryId, c]));

describe("monthSummary", () => {
  test("reproduces the October 2026 figures", () => {
    const s = monthSummary(october());
    expect(s.month).toBe("2026-10");
    expect(s.budgetTotal).toBe(280000);
    expect(s.spent).toBe(223708);
    expect(s.remaining).toBe(56292);
    expect(s.income).toBe(620000);
    expect(s.balance).toBe(396292);
  });

  test("classifies categories by how much of the budget is spent", () => {
    const by = byId(monthSummary(october()));
    expect(by.supermercado).toMatchObject({ spent: 19412, remaining: -1412, state: "over" });
    expect(by.casa?.state).toBe("near");
    expect(by.restaurante?.state).toBe("near");
    expect(by.ocio?.state).toBe("ok");
    expect(by.transporte).toMatchObject({ spent: 0, remaining: 9000, ratio: 0, state: "ok" });
  });

  test("lists expense categories only, in input order", () => {
    const s = monthSummary(october());
    expect(s.categories.map((c) => c.categoryId)).toEqual(OCTOBER_2026.expense.map((c) => c.key));
  });

  test("a refund in an expense category reduces its spending", () => {
    const input = october();
    input.transactions.push({ categoryId: "ocio", amount: 500 });
    const s = monthSummary(input);
    expect(byId(s).ocio?.spent).toBe(26280 - 500);
    expect(s.remaining).toBe(56292 + 500);
  });

  test("a category without budget still reduces what is left", () => {
    const input = october();
    input.categories.push({ id: "things", kind: "expense" });
    input.transactions.push({ categoryId: "things", amount: -1000 });
    const s = monthSummary(input);
    expect(byId(s).things).toEqual({
      categoryId: "things",
      budget: null,
      spent: 1000,
      remaining: null,
      ratio: null,
      state: "ok",
    });
    expect(s.remaining).toBe(56292 - 1000);
  });

  test("a zero budget with spending is over", () => {
    const s = monthSummary({
      month: "2026-10",
      categories: [{ id: "x", kind: "expense" }],
      budgets: [{ categoryId: "x", amount: 0, effectiveFrom: "2026-10" }],
      transactions: [{ categoryId: "x", amount: -100 }],
    });
    expect(s.categories[0]).toMatchObject({ budget: 0, ratio: null, state: "over" });
  });
});

describe("effectiveBudget", () => {
  const entries: BudgetEntry[] = [
    { categoryId: "ocio", amount: 65000, effectiveFrom: "2026-01" },
    { categoryId: "ocio", amount: 70000, effectiveFrom: "2026-11" },
    { categoryId: "casa", amount: 1, effectiveFrom: "2020-01" },
  ];

  test("picks the latest entry that started on or before the month", () => {
    expect(effectiveBudget(entries, "ocio", "2026-10")).toBe(65000);
    expect(effectiveBudget(entries, "ocio", "2026-11")).toBe(70000);
    expect(effectiveBudget(entries, "ocio", "2027-03")).toBe(70000);
  });

  test("is null before the first entry", () => {
    expect(effectiveBudget(entries, "ocio", "2025-12")).toBeNull();
  });
});
