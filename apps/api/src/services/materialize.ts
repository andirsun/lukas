import { addMonths, type Month, occurrences } from "@lukas/core";
import { accounts, recurrences, type Tx, transactions } from "@lukas/db";

/**
 * Inserts the missing pending occurrences of the user's recurrences for `month`. Existing rows
 * (including edited or soft-deleted ones) win thanks to the unique (recurrence_id, date) index,
 * so this is idempotent. Months more than one ahead of `current` are left alone.
 */
export async function materializeRecurrences(
  tx: Tx,
  userId: string,
  month: Month,
  current: Month,
): Promise<number> {
  if (month > addMonths(current, 1)) return 0;
  const rules = await tx.select().from(recurrences);
  if (rules.length === 0) return 0;
  const currencyByAccount = new Map(
    (await tx.select().from(accounts)).map((acc) => [acc.id, acc.currency]),
  );
  const rows = rules.flatMap((rule) =>
    occurrences(rule, month).map((date) => ({
      userId,
      accountId: rule.accountId,
      categoryId: rule.categoryId,
      recurrenceId: rule.id,
      name: rule.name,
      amount: rule.amount,
      currency: currencyByAccount.get(rule.accountId) ?? "EUR",
      date,
      status: "pending" as const,
      source: "recurrence" as const,
    })),
  );
  if (rows.length === 0) return 0;
  const inserted = await tx
    .insert(transactions)
    .values(rows)
    .onConflictDoNothing()
    .returning({ id: transactions.id });
  return inserted.length;
}
