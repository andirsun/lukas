import { type Db, session, user } from "@lukas/db";
import { and, eq, inArray, sql } from "@lukas/db/orm";

/** A guest idle for longer than this is deleted (spec §4.4). */
export const GUEST_INACTIVE_DAYS = 60;
const DAY_MS = 24 * 60 * 60 * 1000;

/** Postgres advisory lock key of the cleanup ("luka"): one run at a time, across API instances. */
export const GUEST_CLEANUP_LOCK = 0x6c756b61;

/** Guests deleted per transaction: a spike of sign-ups never makes one huge delete or lock hold. */
export const GUEST_CLEANUP_BATCH = 500;

/**
 * Deletes the guests (anonymous users) whose latest session activity (`session.updatedAt`) is more
 * than 60 days before `now`, and returns how many it deleted. A guest with no session at all,
 * which should not happen, counts as inactive since it was created. A user with an email is never
 * touched: `isAnonymous` turns false the moment a guest claims one.
 *
 * Deleting the user cascades to all of its data, as `DELETE /v1/me` does (sessions, accounts,
 * categories, transactions...). That needs no privilege beyond the API's own role: `user` and
 * `session` are not under row-level security, and foreign-key cascades bypass it.
 *
 * It deletes in batches of 500, one transaction each, until a batch deletes fewer than that. Every
 * batch first takes a transaction-level advisory lock; one that cannot get it, because another run
 * is going, deletes nothing and ends this run. (A session-level lock would belong to whichever
 * pooled connection took it; this one is released with the transaction.)
 */
export async function cleanupInactiveGuests(db: Db, now: Date): Promise<number> {
  let total = 0;
  for (;;) {
    const deleted = await deleteBatch(db, now);
    total += deleted;
    if (deleted < GUEST_CLEANUP_BATCH) return total;
  }
}

async function deleteBatch(db: Db, now: Date): Promise<number> {
  const cutoff = new Date(now.getTime() - GUEST_INACTIVE_DAYS * DAY_MS);
  return db.transaction(async (tx) => {
    const [lock] = await tx.execute<{ locked: boolean }>(
      sql`select pg_try_advisory_xact_lock(${GUEST_CLEANUP_LOCK}) as locked`,
    );
    if (!lock?.locked) return 0;

    const lastActive = sql`coalesce(
      (select max(${session.updatedAt}) from ${session} where ${session.userId} = ${user.id}),
      ${user.createdAt}
    )`;
    const inactive = tx
      .select({ id: user.id })
      .from(user)
      .where(
        and(eq(user.isAnonymous, true), sql`${lastActive} < ${cutoff.toISOString()}::timestamp`),
      )
      .limit(GUEST_CLEANUP_BATCH);
    const deleted = await tx
      .delete(user)
      .where(inArray(user.id, inactive))
      .returning({ id: user.id });
    return deleted.length;
  });
}

export interface GuestCleanupDeps {
  db: Db;
  /** Replaces `cleanupInactiveGuests`; for tests. */
  cleanup?: (db: Db, now: Date) => Promise<number>;
  log?: (message: string) => void;
  logError?: (message: string, error: unknown) => void;
}

/**
 * Runs the cleanup now and then once a day, until the returned function is called. A failure is
 * logged and the next day's run goes on. The timer does not keep the process alive.
 */
export function scheduleGuestCleanup(deps: GuestCleanupDeps): () => void {
  const cleanup = deps.cleanup ?? cleanupInactiveGuests;
  const log = deps.log ?? ((message) => console.log(message));
  const logError = deps.logError ?? ((message, error) => console.error(message, error));

  const run = async () => {
    try {
      const count = await cleanup(deps.db, new Date());
      if (count > 0)
        log(
          `Guest cleanup: deleted ${count} guest(s) inactive for over ${GUEST_INACTIVE_DAYS} days`,
        );
    } catch (error) {
      logError("Guest cleanup failed", error);
    }
  };

  const timer = setInterval(run, DAY_MS);
  timer.unref();
  void run();
  return () => clearInterval(timer);
}
