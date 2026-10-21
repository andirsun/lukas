import type { TransactionDto } from "@lukas/core";
import { accounts, categories, type Tx, transactions } from "@lukas/db";
import { and, eq, isNull } from "@lukas/db/orm";
import { ApiError } from "../http/problem.ts";

export type TransactionRow = typeof transactions.$inferSelect;

export function toTransactionDto(row: TransactionRow): TransactionDto {
  return {
    id: row.id,
    name: row.name,
    amount: row.amount,
    currency: row.currency,
    date: row.date,
    status: row.status,
    note: row.note,
    categoryId: row.categoryId,
    recurrenceId: row.recurrenceId,
    importId: row.importId,
    source: row.source,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

/**
 * The user's default account. With `lock`, its row stays locked (`FOR UPDATE`) until the
 * transaction ends. Everything that writes transactions in the account's currency, and the
 * currency change itself, takes that lock, so they run one after the other: a change cannot slip
 * between an import's currency check and its inserts.
 */
export async function defaultAccount(tx: Tx, { lock = false }: { lock?: boolean } = {}) {
  const query = tx.select().from(accounts).where(eq(accounts.isDefault, true));
  const [row] = await (lock ? query.for("update") : query);
  if (!row) throw new Error("User has no default account");
  return row;
}

/** The user's non-archived category, or 422 `category_not_found`. */
export async function requireActiveCategory(tx: Tx, id: string) {
  const [row] = await tx
    .select()
    .from(categories)
    .where(and(eq(categories.id, id), isNull(categories.archivedAt)));
  if (!row) throw new ApiError(422, "category_not_found", "Pick one of your active categories");
  return row;
}
