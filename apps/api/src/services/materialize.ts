import { addMonths, firstDay, type Month, occurrences } from "@lukas/core";
import { accounts, categories, recurrences, type Tx, transactions } from "@lukas/db";
import { eq, isNull } from "@lukas/db/orm";

/**
 * Inserts the missing pending occurrences of the user's recurrences for `month`. Existing rows
 * (including edited, moved or soft-deleted ones) win thanks to the unique
 * (recurrence_id, occurrence_month) index, so this is idempotent. Months more than one ahead of `current` are left alone.
 * Rules in an archived category are skipped: archiving ends them (and drops what they had pending
 * from that day on), so nothing reappears in a category that is out of sight.
 */
export async function materializeRecurrences(
  tx: Tx,
  userId: string,
  month: Month,
  current: Month,
): Promise<number> {
  if (month > addMonths(current, 1)) return 0;
  const rules = (
    await tx
      .select({ rule: recurrences })
      .from(recurrences)
      .innerJoin(categories, eq(categories.id, recurrences.categoryId))
      .where(isNull(categories.archivedAt))
  ).map((r) => r.rule);
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
      occurrenceMonth: firstDay(month),
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
