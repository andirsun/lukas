import { createRoute, z } from "@hono/zod-openapi";
import { formatMinorAsDecimal, todayIn, updateProfileSchema } from "@lukas/core";
import {
  accounts,
  categories,
  categoryBudgets,
  recurrences,
  type Tx,
  transactions,
  user,
  withUser,
} from "@lukas/db";
import { and, asc, eq, isNull, sql } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import { jsonBody, jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import { defaultAccount, toTransactionDto } from "../services/transactions.ts";

const profileDto = z.object({
  id: z.string(),
  email: z.string(),
  timezone: z.string(),
  locale: z.string(),
  onboardingCompletedAt: z.string().nullable(),
  currency: z.string(),
});

const csvField = (value: string) =>
  /[",\n\r]/.test(value) ? `"${value.replaceAll('"', '""')}"` : value;

async function profile(deps: AppDeps, userId: string) {
  const [row] = await deps.db
    .select({
      id: user.id,
      email: user.email,
      timezone: user.timezone,
      locale: user.locale,
      onboardingCompletedAt: user.onboardingCompletedAt,
    })
    .from(user)
    .where(eq(user.id, userId));
  if (!row) throw new ApiError(401, "unauthenticated", "Sign in to continue");
  const [account] = await withUser(deps.db, userId, (tx) =>
    tx.select({ currency: accounts.currency }).from(accounts).where(eq(accounts.isDefault, true)),
  );
  return {
    ...row,
    onboardingCompletedAt: row.onboardingCompletedAt?.toISOString() ?? null,
    currency: account?.currency ?? "EUR",
  };
}

/**
 * Sets the default account's currency, only while it has no transactions (soft-deleted ones
 * count: they carry the old currency and can be restored). The check is part of the UPDATE
 * itself; it runs in the caller's transaction, so a 409 rolls back the whole PATCH.
 */
async function setCurrency(tx: Tx, currency: string) {
  // Wait for any import or new transaction holding the account's lock. Taken in its own statement:
  // the UPDATE below then reads a fresh snapshot, so its `not exists` sees rows those writers just
  // committed. (Left to the UPDATE alone, Postgres would re-check the row after the wait but run
  // the subquery against the old snapshot, and switch an account that now has transactions.)
  await defaultAccount(tx, { lock: true });
  const changed = await tx
    .update(accounts)
    .set({ currency })
    .where(
      and(
        eq(accounts.isDefault, true),
        // Written out: Drizzle renders columns unqualified inside UPDATE, so `id` would be ambiguous.
        sql`not exists (select 1 from transactions t where t.account_id = accounts.id)`,
      ),
    )
    .returning({ id: accounts.id });
  if (changed.length > 0) return;
  // Nothing changed: fine if the account already has that currency, locked otherwise.
  const [account] = await tx
    .select({ currency: accounts.currency })
    .from(accounts)
    .where(eq(accounts.isDefault, true));
  if (account?.currency !== currency) {
    throw new ApiError(
      409,
      "currency_locked",
      "The currency cannot change once the account has transactions",
    );
  }
}

export function meRoutes(deps: AppDeps) {
  const app = router();

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/me",
      responses: { 200: jsonResponse(profileDto, "Profile") },
    }),
    async (c) => c.json(await profile(deps, c.get("userId")), 200),
  );

  app.openapi(
    createRoute({
      method: "patch",
      path: "/v1/me",
      request: { body: jsonBody(updateProfileSchema) },
      responses: { 200: jsonResponse(profileDto, "Updated profile"), ...problems(409, 422) },
    }),
    async (c) => {
      const { onboardingCompleted, currency, ...fields } = c.req.valid("json");
      const userId = c.get("userId");
      const set = {
        ...fields,
        // Stamp completion once; later calls keep the first timestamp.
        ...(onboardingCompleted
          ? { onboardingCompletedAt: sql`coalesce(${user.onboardingCompletedAt}, now())` }
          : {}),
      };
      // One transaction: a locked currency (409) leaves every other field untouched.
      await withUser(deps.db, userId, async (tx) => {
        if (currency) await setCurrency(tx, currency);
        if (Object.keys(set).length > 0) {
          await tx.update(user).set(set).where(eq(user.id, userId));
        }
      });
      return c.json(await profile(deps, c.get("userId")), 200);
    },
  );

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/me/export",
      request: { query: z.object({ format: z.enum(["json", "csv"]).default("json") }) },
      responses: {
        200: {
          description: "All of the user's data (JSON) or their transactions (CSV)",
          content: { "application/json": { schema: z.any() }, "text/csv": { schema: z.string() } },
        },
      },
    }),
    async (c) => {
      const { format } = c.req.valid("query");
      const userId = c.get("userId");
      const me = await profile(deps, userId);
      const data = await withUser(deps.db, userId, async (tx) => ({
        accounts: await tx.select().from(accounts),
        categories: await tx.select().from(categories).orderBy(asc(categories.createdAt)),
        budgets: await tx.select().from(categoryBudgets),
        transactions: await tx
          .select()
          .from(transactions)
          .where(isNull(transactions.deletedAt))
          .orderBy(asc(transactions.date), asc(transactions.id)),
        recurrences: await tx.select().from(recurrences),
      }));
      const stamp = todayIn(me.timezone);

      if (format === "csv") {
        const names = new Map(data.categories.map((cat) => [cat.id, cat.name]));
        const lines = data.transactions.map((t) =>
          [
            t.date,
            t.name,
            formatMinorAsDecimal(t.amount),
            t.currency,
            names.get(t.categoryId) ?? "",
            t.status,
            t.note ?? "",
          ]
            .map(csvField)
            .join(","),
        );
        return c.body(
          ["date,name,amount,currency,category,status,note", ...lines].join("\n"),
          200,
          {
            "content-type": "text/csv; charset=utf-8",
            "content-disposition": `attachment; filename="lukas-export-${stamp}.csv"`,
          },
        );
      }

      const body = {
        exportedAt: new Date().toISOString(),
        user: me,
        ...data,
        transactions: data.transactions.map(toTransactionDto),
      };
      return c.body(JSON.stringify(body), 200, {
        "content-type": "application/json",
        "content-disposition": `attachment; filename="lukas-export-${stamp}.json"`,
      });
    },
  );

  app.openapi(
    createRoute({
      method: "delete",
      path: "/v1/me",
      responses: { 204: { description: "Account and all data permanently deleted" } },
    }),
    async (c) => {
      // Every user-owned row (domain data, sessions, passkeys, OAuth grants) cascades from `user`.
      await deps.db.delete(user).where(eq(user.id, c.get("userId")));
      return c.body(null, 204);
    },
  );

  return app;
}
