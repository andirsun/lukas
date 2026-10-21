import type { Month } from "./dates.ts";

export type CategoryKind = "expense" | "income";
export type TxStatus = "paid" | "pending";

export interface BudgetEntry {
  categoryId: string;
  amount: number;
  effectiveFrom: Month;
}

/** The budget in force for a category in a month: the latest entry starting on or before it. */
export function effectiveBudget(
  entries: BudgetEntry[],
  categoryId: string,
  month: Month,
): number | null {
  let best: BudgetEntry | null = null;
  for (const entry of entries) {
    if (entry.categoryId !== categoryId || entry.effectiveFrom > month) continue;
    if (!best || entry.effectiveFrom > best.effectiveFrom) best = entry;
  }
  return best ? best.amount : null;
}
