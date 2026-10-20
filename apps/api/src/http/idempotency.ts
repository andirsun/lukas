import { createHash } from "node:crypto";
import { type Db, idempotencyKeys, withUser } from "@lukas/db";
import { and, eq, lt } from "@lukas/db/orm";
import { createMiddleware } from "hono/factory";
import type { ContentfulStatusCode } from "hono/utils/http-status";
import type { AppEnv } from "../env.ts";
import { ApiError } from "./problem.ts";

const TTL_MS = 24 * 60 * 60 * 1000;

/**
 * Honors `Idempotency-Key` on authenticated POSTs: a retry with the same key and body replays the
 * stored 2xx response; the same key with a different body is rejected. Keys live for 24 hours.
 */
export function idempotent(db: Db) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const key = c.req.header("idempotency-key");
    if (!key) return next();
    const userId = c.get("userId");
    const requestHash = createHash("sha256")
      .update(await c.req.raw.clone().text())
      .digest("hex");
    const now = new Date();
    const cutoff = new Date(now.getTime() - TTL_MS);

    const [existing] = await withUser(db, userId, (tx) =>
      tx
        .select()
        .from(idempotencyKeys)
        .where(and(eq(idempotencyKeys.userId, userId), eq(idempotencyKeys.key, key))),
    );
    if (existing && existing.createdAt > cutoff) {
      if (existing.requestHash !== requestHash) {
        throw new ApiError(
          422,
          "idempotency_key_reused",
          "This Idempotency-Key was used with a different request",
        );
      }
      return c.json(existing.body, existing.status as ContentfulStatusCode);
    }

    await next();

    if (c.res.status < 200 || c.res.status >= 300) return;
    const body = await c.res.clone().json();
    const row = { userId, key, requestHash, status: c.res.status, body, createdAt: now };
    await withUser(db, userId, async (tx) => {
      await tx
        .insert(idempotencyKeys)
        .values(row)
        .onConflictDoUpdate({ target: [idempotencyKeys.userId, idempotencyKeys.key], set: row });
      await tx.delete(idempotencyKeys).where(lt(idempotencyKeys.createdAt, cutoff));
    });
  });
}
