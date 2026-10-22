import { addMonths, firstDay, type Month, occurrences } from "@lukas/core";
import { accounts, categories, recurrences, type Tx, transactions } from "@lukas/db";
import { asc, eq, isNull } from "@lukas/db/orm";
import { defaultAccount } from "./transactions.ts";

/**
 * Inserts the missing pending occurrences of the user's recurrences for `month`. Existing rows
 * (including edited, moved or soft-deleted ones) win thanks to the unique
 * (recurrence_id, occurrence_month) index, so this is idempotent. Months more than one ahead of `current` are left alone.
 * Rules in an archived category are skipped: archiving ends them (and drops what they had pending
 * from that day on), so nothing reappears in a category that is out of sight.
 *
 * It first takes the default account's lock in share mode, which every write to recurrences takes
 * in full (create, edit, delete, archiving their category): one of those in flight finishes before
 * the rules are read here, and one that comes later waits until this transaction (a report may
 * materialize 36 months) ends, then removes what it added. Without it, a rule deleted meanwhile
 * would leave its pending rows behind with no rule (counted as spent), and an archived category
 * would get rows back. Rules are read in a fixed order, so two reads inserting the same
 * occurrences at once wait on each other in the same order instead of deadlocking.
 */
export async function materializeRecurrences(
  tx: Tx,
  userId: string,
  month: Month,
  current: Month,
): Promise<number> {
  if (month > addMonths(current, 1)) return 0;
  await defaultAccount(tx, { lock: "share" });
  const rules = (
    await tx
      .select({ rule: recurrences })
      .from(recurrences)
      .innerJoin(categories, eq(categories.id, recurrences.categoryId))
      .where(isNull(categories.archivedAt))
      .orderBy(asc(recurrences.id))
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
