import { createRoute, z } from "@hono/zod-openapi";
import { formatMinorAsDecimal, todayIn, updateProfileSchema } from "@lukas/core";
import {
  accounts,
  categories,
  categoryBudgets,
  recurrences,
  transactions,
  user,
  withUser,
} from "@lukas/db";
import { asc, eq, isNull } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import { jsonBody, jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import { toTransactionDto } from "../services/transactions.ts";

const profileDto = z.object({
  id: z.string(),
  email: z.string(),
  timezone: z.string(),
  locale: z.string(),
});

const csvField = (value: string) =>
  /[",\n\r]/.test(value) ? `"${value.replaceAll('"', '""')}"` : value;

async function profile(deps: AppDeps, userId: string) {
  const [row] = await deps.db
    .select({ id: user.id, email: user.email, timezone: user.timezone, locale: user.locale })
    .from(user)
    .where(eq(user.id, userId));
  if (!row) throw new ApiError(401, "unauthenticated", "Sign in to continue");
  return row;
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
      responses: { 200: jsonResponse(profileDto, "Updated profile"), ...problems(422) },
    }),
    async (c) => {
      await deps.db
        .update(user)
        .set(c.req.valid("json"))
        .where(eq(user.id, c.get("userId")));
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
