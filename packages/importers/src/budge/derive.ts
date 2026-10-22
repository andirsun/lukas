import { createHash } from "node:crypto";
import { addMonths, type CategoryKind, type Month, monthOf, monthsBetween } from "@lukas/core";
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

export interface AverageWindow {
  /** How many complete months to average over, ending with the latest one. */
  months: number;
  /**
   * The first month that does not count, usually the current one (still running). The window ends
   * earlier when the rows do: an old export is averaged over its own last months.
   */
  until?: Month;
}

/**
 * The months a windowed average covers: the last `months` complete months, ending before `until`
 * (or after the file's last month, for an old export) and starting no earlier than the file's
 * first month, so a short history is divided by the months it really has. Null when no complete
 * month is left (a file of the running month alone).
 */
export function averageWindow(
  rows: BudgeRow[],
  window: AverageWindow,
): { from: Month; to: Month; months: number } | null {
  if (rows.length === 0) return null;
  const months = rows.map((r) => monthOf(r.date)).sort();
  const first = months[0] ?? "";
  const afterLast = addMonths(months.at(-1) ?? "", 1);
  const end = window.until && window.until < afterLast ? window.until : afterLast;
  const wanted = addMonths(end, -window.months);
  const from = wanted > first ? wanted : first;
  const to = addMonths(end, -1);
  if (from > to) return null;
  return { from, to, months: monthsBetween(from, to).length };
}

/**
 * Average net monthly spending per expense category, largest first. Without a window, over every
 * month the rows span. With one, over `averageWindow`'s months only, divided by how many there are
 * even if some have no rows: a category with no spending there is left out, so a dropped gym or a
 * one-off payment years ago doesn't become a budget. Kinds come from all rows.
 */
export function averageMonthlySpending(
  rows: BudgeRow[],
  window?: AverageWindow,
): { category: string; amount: number }[] {
  if (rows.length === 0) return [];
  let counted = rows;
  let span: number;
  if (window) {
    const covered = averageWindow(rows, window);
    if (!covered) return [];
    counted = rows.filter((r) => {
      const month = monthOf(r.date);
      return month >= covered.from && month <= covered.to;
    });
    span = covered.months;
  } else {
    const months = rows.map((r) => monthOf(r.date)).sort();
    span = monthsBetween(months[0] ?? "", months.at(-1) ?? "").length;
  }
  const kinds = inferCategoryKinds(rows);
  const spent = new Map<string, { category: string; total: number }>();
  for (const row of counted) {
    const key = normalizeName(row.category);
    if (kinds.get(key) !== "expense") continue;
    const entry = spent.get(key) ?? { category: row.category, total: 0 };
    entry.total -= row.amount;
    spent.set(key, entry);
  }
  return [...spent.values()]
    .map(({ category, total }) => ({ category, amount: Math.round(total / span) }))
    .filter((a) => !window || a.amount > 0)
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
