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

export async function defaultAccount(tx: Tx) {
  const [row] = await tx.select().from(accounts).where(eq(accounts.isDefault, true));
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
