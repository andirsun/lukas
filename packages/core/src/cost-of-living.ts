import type { CategoryKind } from "./budget.ts";
import { type IsoDate, type Month, monthOf } from "./dates.ts";

export interface CostOfLivingInput {
  /** The complete months to average over. */
  months: Month[];
  categories: { id: string; kind: CategoryKind }[];
  /** Expense categories that recur (subscriptions, rent...); every other expense is variable. */
  fixedCategoryIds: string[];
  /** Non-deleted transactions; the ones outside `months` are ignored. */
  transactions: { categoryId: string; amount: number; date: IsoDate }[];
}

export interface CostOfLivingCategory {
  categoryId: string;
  /** Average net spent per month, in positive cents. */
  average: number;
  type: "fixed" | "variable";
}

export interface CostOfLiving {
  months: number;
  total: number;
  fixed: number;
  variable: number;
  categories: CostOfLivingCategory[];
}

export function costOfLiving(input: CostOfLivingInput): CostOfLiving {
  const window = new Set(input.months);
  const fixedIds = new Set(input.fixedCategoryIds);
  const spent = new Map<string, number>();
  for (const tx of input.transactions) {
    if (!window.has(monthOf(tx.date))) continue;
    spent.set(tx.categoryId, (spent.get(tx.categoryId) ?? 0) - tx.amount);
  }

  const categories: CostOfLivingCategory[] = [];
  let fixed = 0;
  let variable = 0;
  if (input.months.length > 0) {
    for (const category of input.categories) {
      if (category.kind !== "expense") continue;
      const average = Math.round((spent.get(category.id) ?? 0) / input.months.length);
      if (average === 0) continue;
      const type = fixedIds.has(category.id) ? "fixed" : "variable";
      if (type === "fixed") fixed += average;
      else variable += average;
      categories.push({ categoryId: category.id, average, type });
    }
  }
  categories.sort((x, y) => y.average - x.average);

  return { months: input.months.length, total: fixed + variable, fixed, variable, categories };
}
