import {
  type CategoryDto,
  type MonthSummary,
  monthOf,
  monthSummary,
  type TransactionDto,
} from "@lukas/core";
import type { QueryClient, QueryKey } from "@tanstack/react-query";

/** The cached shape of `useTransactions(month)`. */
export interface TransactionList {
  items: TransactionDto[];
  nextCursor: string | null;
}

/** Undoes an optimistic change: puts back exactly what the caches held before it. */
export type Rollback = () => void;

export const summaryKey = (month: string) => ["summary", month] as const;
export const transactionsKey = (month: string) => ["transactions", month] as const;
export const categoriesKey = () => ["categories"] as const;

type Kind = "expense" | "income";

/** Stands in for every income category: the summary only keeps their total. */
const INCOME = "income";

/**
 * The month summary after adding (`direction` 1) or taking away (-1) one transaction, worked out by
 * the same `monthSummary` the API uses, so totals, remaining and the near/over state match what the
 * server will say. It is rebuilt from the summary itself: each expense category's budget and spending
 * become one budget entry and one transaction.
 */
export function patchSummary(
  summary: MonthSummary,
  tx: { categoryId: string; amount: number },
  kind: Kind,
  direction: 1 | -1,
): MonthSummary {
  const month = summary.month;
  const categories: { id: string; kind: Kind }[] = summary.categories.map((c) => ({
    id: c.categoryId,
    kind: "expense",
  }));
  const budgets = summary.categories.flatMap((c) =>
    c.budget === null ? [] : [{ categoryId: c.categoryId, amount: c.budget, effectiveFrom: month }],
  );
  const transactions = summary.categories.map((c) => ({
    categoryId: c.categoryId,
    amount: -c.spent,
  }));

  categories.push({ id: INCOME, kind: "income" });
  transactions.push({ categoryId: INCOME, amount: summary.income });

  const target = kind === "income" ? INCOME : tx.categoryId;
  if (!categories.some((c) => c.id === target)) {
    categories.splice(categories.length - 1, 0, { id: target, kind: "expense" });
  }
  transactions.push({ categoryId: target, amount: direction * tx.amount });

  return monthSummary({ month, categories, budgets, transactions });
}

/** Newest first, like the API: by date, then id. */
function byNewest(a: TransactionDto, b: TransactionDto): number {
  if (a.date !== b.date) return a.date < b.date ? 1 : -1;
  return a.id < b.id ? 1 : a.id > b.id ? -1 : 0;
}

function kindOf(qc: QueryClient, tx: Pick<TransactionDto, "categoryId" | "amount">): Kind {
  const known = qc
    .getQueryData<CategoryDto[]>(categoriesKey())
    ?.find((c) => c.id === tx.categoryId);
  // Expenses are stored negative and income positive.
  return known?.kind ?? (tx.amount < 0 ? "expense" : "income");
}

/** Edits one cached query, if it is cached, and returns how to put it back. */
function edit<T>(qc: QueryClient, key: QueryKey, change: (current: T) => T): Rollback {
  const before = qc.getQueryData<T>(key);
  if (before === undefined) return () => {};
  qc.setQueryData<T>(key, change(before));
  return () => qc.setQueryData<T>(key, before);
}

const together =
  (rollbacks: Rollback[]): Rollback =>
  () => {
    for (const rollback of rollbacks.toReversed()) rollback();
  };

function addToCaches(qc: QueryClient, tx: TransactionDto): Rollback {
  const month = monthOf(tx.date);
  return together([
    edit<TransactionList>(qc, transactionsKey(month), (list) => ({
      ...list,
      items: [...list.items.filter((t) => t.id !== tx.id), tx].sort(byNewest),
    })),
    edit<MonthSummary>(qc, summaryKey(month), (s) => patchSummary(s, tx, kindOf(qc, tx), 1)),
  ]);
}

function removeFromCaches(qc: QueryClient, month: string, tx: TransactionDto): Rollback {
  return together([
    edit<TransactionList>(qc, transactionsKey(month), (list) => ({
      ...list,
      items: list.items.filter((t) => t.id !== tx.id),
    })),
    edit<MonthSummary>(qc, summaryKey(month), (s) => patchSummary(s, tx, kindOf(qc, tx), -1)),
  ]);
}

function findCached(qc: QueryClient, month: string, id: string): TransactionDto | undefined {
  return qc.getQueryData<TransactionList>(transactionsKey(month))?.items.find((t) => t.id === id);
}

/** Shows a new transaction right away in its month's list and summary (when they are cached). */
export function optimisticAdd(qc: QueryClient, tx: TransactionDto): Rollback {
  return addToCaches(qc, tx);
}

/** Takes a transaction out of its month's list and summary. Does nothing if it is not cached. */
export function optimisticRemove(qc: QueryClient, month: string, id: string): Rollback {
  const tx = findCached(qc, month, id);
  return tx ? removeFromCaches(qc, month, tx) : () => {};
}

/**
 * Applies an edit to a cached transaction. A new date in another month moves it between that
 * month's caches. Does nothing if the transaction is not cached.
 */
export function optimisticUpdate(
  qc: QueryClient,
  month: string,
  id: string,
  patch: Partial<
    Pick<TransactionDto, "name" | "amount" | "categoryId" | "date" | "status" | "note">
  >,
): Rollback {
  const before = findCached(qc, month, id);
  if (!before) return () => {};
  const after: TransactionDto = { ...before, ...patch };
  return together([removeFromCaches(qc, month, before), addToCaches(qc, after)]);
}

/** The cache entries a change to these months touches; cancel their in-flight fetches first. */
export function keysFor(months: string[]): QueryKey[] {
  return months.flatMap((month) => [summaryKey(month), transactionsKey(month)]);
}
