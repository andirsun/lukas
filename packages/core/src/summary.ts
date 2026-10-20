import { type BudgetEntry, type CategoryKind, effectiveBudget } from "./budget.ts";
import type { Month } from "./dates.ts";

export const NEAR_LIMIT_RATIO = 0.8;

export interface SummaryInput {
  month: Month;
  categories: { id: string; kind: CategoryKind }[];
  budgets: BudgetEntry[];
  /** That month's non-deleted transactions, paid and pending. */
  transactions: { categoryId: string; amount: number }[];
}

export interface CategorySummary {
  categoryId: string;
  budget: number | null;
  spent: number;
  remaining: number | null;
  ratio: number | null;
  state: "ok" | "near" | "over";
}

export interface MonthSummary {
  month: Month;
  budgetTotal: number;
  spent: number;
  remaining: number;
  income: number;
  balance: number;
  categories: CategorySummary[];
}

function categorySummary(
  categoryId: string,
  budget: number | null,
  spent: number,
): CategorySummary {
  if (budget === null) {
    return { categoryId, budget, spent, remaining: null, ratio: null, state: "ok" };
  }
  if (budget === 0) {
    return {
      categoryId,
      budget,
      spent,
      remaining: -spent,
      ratio: null,
      state: spent > 0 ? "over" : "ok",
    };
  }
  const ratio = spent / budget;
  const state = ratio > 1 ? "over" : ratio >= NEAR_LIMIT_RATIO ? "near" : "ok";
  return { categoryId, budget, spent, remaining: budget - spent, ratio, state };
}

export function monthSummary(input: SummaryInput): MonthSummary {
  const totals = new Map<string, number>();
  for (const tx of input.transactions) {
    totals.set(tx.categoryId, (totals.get(tx.categoryId) ?? 0) + tx.amount);
  }

  let budgetTotal = 0;
  let spent = 0;
  let income = 0;
  const categories: CategorySummary[] = [];

  for (const category of input.categories) {
    const total = totals.get(category.id) ?? 0;
    if (category.kind === "income") {
      income += total;
      continue;
    }
    const budget = effectiveBudget(input.budgets, category.id, input.month);
    budgetTotal += budget ?? 0;
    spent -= total;
    // `0 - total` rather than `-total` so an empty category reports 0, not -0.
    categories.push(categorySummary(category.id, budget, 0 - total));
  }

  return {
    month: input.month,
    budgetTotal,
    spent,
    remaining: budgetTotal - spent,
    income,
    balance: income - spent,
    categories,
  };
}
