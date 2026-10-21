import { createHash } from "node:crypto";
import { type CategoryKind, monthOf, monthsBetween } from "@lukas/core";
import { normalizeName } from "../category-style.ts";
import type { BudgeRow } from "./parse.ts";

/** Category kind by majority sign of its rows (ties count as expense), keyed by normalized name. */
export function inferCategoryKinds(rows: BudgeRow[]): Map<string, CategoryKind> {
  const balance = new Map<string, number>();
  for (const row of rows) {
    const key = normalizeName(row.category);
    balance.set(key, (balance.get(key) ?? 0) + (row.amount > 0 ? 1 : -1));
  }
  return new Map([...balance].map(([key, b]) => [key, b > 0 ? "income" : "expense"]));
}

/**
 * Stable per-row hashes for deduplication. Identical rows (same date, name, amount and category)
 * are told apart by their ordinal, so overlapping exports produce the same hashes.
 */
export function rowHashes(rows: BudgeRow[]): string[] {
  const seen = new Map<string, number>();
  return rows.map((row) => {
    const identity = [row.date, row.name, row.amount, normalizeName(row.category)].join("|");
    const ordinal = seen.get(identity) ?? 0;
    seen.set(identity, ordinal + 1);
    return createHash("sha256").update(`${identity}|${ordinal}`).digest("hex");
  });
}

/** Average net monthly spending per expense category over the months the rows span. */
export function averageMonthlySpending(rows: BudgeRow[]): { category: string; amount: number }[] {
  if (rows.length === 0) return [];
  const months = rows.map((r) => monthOf(r.date)).sort();
  const span = monthsBetween(months[0] ?? "", months.at(-1) ?? "").length;
  const kinds = inferCategoryKinds(rows);
  const spent = new Map<string, { category: string; total: number }>();
  for (const row of rows) {
    const key = normalizeName(row.category);
    if (kinds.get(key) !== "expense") continue;
    const entry = spent.get(key) ?? { category: row.category, total: 0 };
    entry.total -= row.amount;
    spent.set(key, entry);
  }
  return [...spent.values()]
    .map(({ category, total }) => ({ category, amount: Math.round(total / span) }))
    .sort((a, b) => b.amount - a.amount);
}

/**
 * The currency of an export: the one most of its rows use (a tie goes to the one seen first), or
 * null without rows. Budge exports one account at a time, so in practice every row agrees.
 */
export function fileCurrency(rows: BudgeRow[]): string | null {
  const counts = new Map<string, number>();
  for (const row of rows) counts.set(row.currency, (counts.get(row.currency) ?? 0) + 1);
  let best: string | null = null;
  let bestCount = 0;
  for (const [currency, count] of counts) {
    if (count > bestCount) {
      best = currency;
      bestCount = count;
    }
  }
  return best;
}
