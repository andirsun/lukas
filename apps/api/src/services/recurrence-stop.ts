import { firstDay, type IsoDate, type Month } from "@lukas/core";
import { recurrences, type Tx, transactions } from "@lukas/db";
import { and, eq, gte, inArray, isNull, or, sql } from "@lukas/db/orm";

/**
 * Hard-deletes the unpaid pending rows these rules generated: those from `fromMonth` on (by the
 * month they were generated for), or those dated `fromDate` or later. Paid rows and soft-deleted
 * (dismissed) ones stay.
 */
export async function dropPendingOccurrences(
  tx: Tx,
  recurrenceIds: string[],
  from: { fromMonth: Month } | { fromDate: IsoDate },
): Promise<void> {
  if (recurrenceIds.length === 0) return;
  await tx
    .delete(transactions)
    .where(
      and(
        inArray(transactions.recurrenceId, recurrenceIds),
        eq(transactions.status, "pending"),
        isNull(transactions.deletedAt),
        "fromMonth" in from
          ? gte(transactions.occurrenceMonth, firstDay(from.fromMonth))
          : gte(transactions.date, from.fromDate),
      ),
    );
}

/**
 * Ends a category's active recurrences today, when the category is archived: their end date
 * becomes today (and a start still to come becomes today too, so the rule stays valid), and their
 * unpaid pending rows from today on are removed. Rules already ended stay as they are. Returns how
 * many were stopped. The caller holds the default account's lock, like any recurrence write.
 */
export async function stopCategoryRecurrences(
  tx: Tx,
  categoryId: string,
  today: IsoDate,
): Promise<number> {
  const stopped = await tx
    .update(recurrences)
    .set({
      endDate: today,
      startDate: sql`least(${recurrences.startDate}, ${today}::date)`,
    })
    .where(
      and(
        eq(recurrences.categoryId, categoryId),
        or(isNull(recurrences.endDate), gte(recurrences.endDate, today)),
      ),
    )
    .returning({ id: recurrences.id });
  await dropPendingOccurrences(
    tx,
    stopped.map((r) => r.id),
    { fromDate: today },
  );
  return stopped.length;
}
