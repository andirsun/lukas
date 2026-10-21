import { createRoute, z } from "@hono/zod-openapi";
import { firstDay, lastDay, monthSchema, monthSummary, monthSummaryDto } from "@lukas/core";
import { categories, categoryBudgets, transactions, withUser } from "@lukas/db";
import { and, asc, gte, isNull, lte } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import { jsonResponse, problems } from "../http/openapi.ts";
import { router } from "../http/router.ts";
import { materializeRecurrences } from "../services/materialize.ts";
import { currentMonth } from "../services/time.ts";

export function summaryRoutes(deps: AppDeps) {
  const app = router();

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/summary",
      request: { query: z.object({ month: monthSchema.optional() }) },
      responses: { 200: jsonResponse(monthSummaryDto, "Month summary"), ...problems(422) },
    }),
    async (c) => {
      const user = c.get("user");
      const current = currentMonth(user);
      const month = c.req.valid("query").month ?? current;
      const summary = await withUser(deps.db, user.id, async (tx) => {
        await materializeRecurrences(tx, user.id, month, current);
        const txs = await tx
          .select({ categoryId: transactions.categoryId, amount: transactions.amount })
          .from(transactions)
          .where(
            and(
              isNull(transactions.deletedAt),
              gte(transactions.date, firstDay(month)),
              lte(transactions.date, lastDay(month)),
            ),
          );
        const used = new Set(txs.map((t) => t.categoryId));
        // Archived categories only appear when they still have spending that month.
        const cats = (
          await tx
            .select()
            .from(categories)
            .orderBy(asc(categories.sortOrder), asc(categories.createdAt))
        ).filter((cat) => cat.archivedAt === null || used.has(cat.id));
        const budgets = (await tx.select().from(categoryBudgets)).map((b) => ({
          categoryId: b.categoryId,
          amount: b.amount,
          effectiveFrom: b.effectiveFrom.slice(0, 7),
        }));
        return monthSummary({ month, categories: cats, budgets, transactions: txs });
      });
      return c.json(summary, 200);
    },
  );

  return app;
}
