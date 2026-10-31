import { createHash } from "node:crypto";
import { type Db, idempotencyKeys, withUser } from "@lukas/db";
import { and, eq, lt } from "@lukas/db/orm";
import { createMiddleware } from "hono/factory";
import type { ContentfulStatusCode } from "hono/utils/http-status";
import type { AppEnv } from "../env.ts";
import { ApiError } from "./problem.ts";

const TTL_MS = 24 * 60 * 60 * 1000;
/** Status stored while the first request with a key is still running. */
const IN_PROGRESS = 0;
/** Marks a replayed response, so a client can tell "saved now" from "already saved". */
export const REPLAYED_HEADER = "Idempotent-Replayed";

/**
 * Honors `Idempotency-Key` on authenticated POSTs: a retry with the same key and body replays the
 * stored 2xx response (with `Idempotent-Replayed: true`); the same key with a different body is rejected. The key is reserved before
 * the handler runs, so concurrent retries get 409 instead of running twice. Failed requests
 * release their key. Keys live for 24 hours.
 *
 * With `required`, a request without a key is refused (400 `idempotency_key_required`) instead of
 * running unprotected: for calls whose retry would save everything twice.
 */
export function idempotent(db: Db, { required = false }: { required?: boolean } = {}) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const key = c.req.header("idempotency-key");
    if (!key) {
      if (required) {
        throw new ApiError(
          400,
          "idempotency_key_required",
          "Send an Idempotency-Key header with this request",
        );
      }
      return next();
    }
    const userId = c.get("userId");
    const requestHash = createHash("sha256")
      .update(await c.req.raw.clone().text())
      .digest("hex");
    const now = new Date();
    const cutoff = new Date(now.getTime() - TTL_MS);
    const thisKey = and(eq(idempotencyKeys.userId, userId), eq(idempotencyKeys.key, key));
    const reservation = { userId, key, requestHash, status: IN_PROGRESS, body: {}, createdAt: now };

    // Reserve the key (or take over an expired one) in its own committed transaction.
    const reserved = await withUser(db, userId, async (tx) => {
      await tx.delete(idempotencyKeys).where(and(thisKey, lt(idempotencyKeys.createdAt, cutoff)));
      const rows = await tx
        .insert(idempotencyKeys)
        .values(reservation)
        .onConflictDoNothing()
        .returning();
      return rows.length > 0;
    });

    if (!reserved) {
      const [existing] = await withUser(db, userId, (tx) =>
        tx.select().from(idempotencyKeys).where(thisKey),
      );
      if (!existing)
        throw new ApiError(409, "idempotency_in_progress", "Retry this request in a moment");
      if (existing.requestHash !== requestHash) {
        throw new ApiError(
          422,
          "idempotency_key_reused",
          "This Idempotency-Key was used with a different request",
        );
      }
      if (existing.status === IN_PROGRESS) {
        throw new ApiError(
          409,
          "idempotency_in_progress",
          "The first request with this key is still running",
        );
      }
      return c.json(existing.body, existing.status as ContentfulStatusCode, {
        [REPLAYED_HEADER]: "true",
      });
    }

    let stored = false;
    try {
      await next();
      if (c.res.status >= 200 && c.res.status < 300) {
        const body = await c.res.clone().json();
        await withUser(db, userId, (tx) =>
          tx.update(idempotencyKeys).set({ status: c.res.status, body }).where(thisKey),
        );
        stored = true;
      }
    } finally {
      if (!stored) await withUser(db, userId, (tx) => tx.delete(idempotencyKeys).where(thisKey));
    }
  });
}
