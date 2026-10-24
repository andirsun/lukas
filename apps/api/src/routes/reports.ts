import { createRoute, z } from "@hono/zod-openapi";
import {
  addMonths,
  costOfLiving,
  effectiveBudget,
  firstDay,
  lastDay,
  type Month,
  monthSchema,
  monthsBetween,
} from "@lukas/core";
import {
  categories,
  categoryBudgets,
  recurrences,
  type Tx,
  transactions,
  withUser,
} from "@lukas/db";
import { and, eq, gte, isNull, lte, or, sql } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import type { SessionUser } from "../env.ts";
import { jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import { materializeRecurrences } from "../services/materialize.ts";
import { currentMonth } from "../services/time.ts";

const MAX_MONTHS = 36;

const rangeFields = z.object({ from: monthSchema, to: monthSchema });
const fromBeforeTo = (q: { from: Month; to: Month }) => q.from <= q.to;
const FROM_AFTER_TO = { message: "from must not be after to", path: ["from"] };
const rangeQuery = rangeFields.refine(fromBeforeTo, FROM_AFTER_TO);

function checkRange(from: Month, to: Month): Month[] {
  const months = monthsBetween(from, to);
  if (months.length > MAX_MONTHS) {
    throw new ApiError(422, "range_too_large", `Ranges are limited to ${MAX_MONTHS} months`);
  }
  return months;
}

const inRange = (from: Month, to: Month) =>
  and(
    isNull(transactions.deletedAt),
    gte(transactions.date, firstDay(from)),
    lte(transactions.date, lastDay(to)),
  );

/**
 * Pending occurrences are created when a month is read (see materializeRecurrences). A report
 * reads its months the same way, so it counts the same rows as the home screen whether or not
 * that screen opened those months first.
 */
async function materializeMonths(tx: Tx, user: SessionUser, months: Month[], current: Month) {
  for (const month of months) await materializeRecurrences(tx, user.id, month, current);
}

export function reportRoutes(deps: AppDeps) {
  const app = router();

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/reports/by-category",
      operationId: "getCategoryReport",
      request: {
        query: rangeFields
          .extend({
            kind: z.enum(["expense", "income"]).default("expense"),
            status: z.enum(["paid", "pending"]).optional(),
          })
          .refine(fromBeforeTo, FROM_AFTER_TO),
      },
      responses: {
        200: jsonResponse(
          z
            .object({
              total: z.number().int(),
              items: z.array(
                z.object({
                  categoryId: z.uuid(),
                  name: z.string(),
                  icon: z.string(),
                  color: z.string(),
                  total: z.number().int(),
                  share: z.number(),
                }),
              ),
            })
            .openapi("CategoryReport"),
          "Totals per category; expense totals are positive amounts spent",
        ),
        ...problems(422),
      },
    }),
    async (c) => {
      const { from, to, kind, status } = c.req.valid("query");
      const months = checkRange(from, to);
      const user = c.get("user");
      const rows = await withUser(deps.db, user.id, async (tx) => {
        await materializeMonths(tx, user, months, currentMonth(deps, user));
        return tx
          .select({
            categoryId: categories.id,
            name: categories.name,
            icon: categories.icon,
            color: categories.color,
            sum: sql<string>`sum(${transactions.amount})`,
          })
          .from(transactions)
          .innerJoin(categories, eq(categories.id, transactions.categoryId))
          .where(
            and(
              inRange(from, to),
              eq(categories.kind, kind),
              status ? eq(transactions.status, status) : undefined,
            ),
          )
          .groupBy(categories.id);
      });
      const sign = kind === "expense" ? -1 : 1;
      const items = rows
        .map(({ sum, ...category }) => ({ ...category, total: sign * Number(sum) }))
        .filter((i) => i.total !== 0)
        .sort((x, y) => y.total - x.total);
      const total = items.reduce((acc, i) => acc + i.total, 0);
      return c.json(
        {
          total,
          items: items.map((i) => ({
            ...i,
            share: total === 0 ? 0 : Math.round((i.total / total) * 10_000) / 10_000,
          })),
        },
        200,
      );
    },
  );

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/reports/trend",
      operationId: "getTrendReport",
      request: { query: rangeQuery },
      responses: {
        200: jsonResponse(
          z
            .object({
              months: z.array(
                z.object({
                  month: z.string(),
                  income: z.number().int(),
                  expenses: z.number().int(),
                  budget: z.number().int(),
                }),
              ),
            })
            .openapi("TrendReport"),
          "Income, expenses and budget per month",
        ),
        ...problems(422),
      },
    }),
    async (c) => {
      const { from, to } = c.req.valid("query");
      const months = checkRange(from, to);
      const user = c.get("user");
      const { totals, cats, budgets } = await withUser(deps.db, user.id, async (tx) => {
        await materializeMonths(tx, user, months, currentMonth(deps, user));
        return {
          totals: await tx
            .select({
              month: sql<string>`to_char(${transactions.date}, 'YYYY-MM')`,
              categoryId: transactions.categoryId,
              sum: sql<string>`sum(${transactions.amount})`,
            })
            .from(transactions)
            .where(inRange(from, to))
            .groupBy(sql`1`, transactions.categoryId),
          cats: await tx.select().from(categories),
          budgets: (await tx.select().from(categoryBudgets)).map((b) => ({
            categoryId: b.categoryId,
            amount: b.amount,
            effectiveFrom: b.effectiveFrom.slice(0, 7),
          })),
        };
      });
      const kindOf = new Map(cats.map((cat) => [cat.id, cat.kind]));
      const result = months.map((month) => {
        const rows = totals.filter((r) => r.month === month);
        const used = new Set(rows.map((r) => r.categoryId));
        let income = 0;
        let expenses = 0;
        for (const r of rows) {
          if (kindOf.get(r.categoryId) === "income") income += Number(r.sum);
          else expenses -= Number(r.sum);
        }
        // Same rule as the month summary: archived categories count only with spending that month.
        const budget = cats
          .filter((cat) => cat.kind === "expense" && (cat.archivedAt === null || used.has(cat.id)))
          .reduce((acc, cat) => acc + (effectiveBudget(budgets, cat.id, month) ?? 0), 0);
        return { month, income, expenses, budget };
      });
      return c.json({ months: result }, 200);
    },
  );

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/reports/cost-of-living",
      operationId: "getCostOfLivingReport",
      request: {
        query: z.object({ months: z.coerce.number().int().min(1).max(24).default(6) }),
      },
      responses: {
        200: jsonResponse(
          z
            .object({
              months: z.number().int(),
              total: z.number().int(),
              fixed: z.number().int(),
              variable: z.number().int(),
              categories: z.array(
                z.object({
                  categoryId: z.uuid(),
                  average: z.number().int(),
                  type: z.enum(["fixed", "variable"]),
                }),
              ),
            })
            .openapi("CostOfLivingReport"),
          "Average monthly expenses over the last complete months, split into fixed and variable",
        ),
        ...problems(422),
      },
    }),
    async (c) => {
      const { months: count } = c.req.valid("query");
      const user = c.get("user");
      const to = addMonths(currentMonth(deps, user), -1);
      const from = addMonths(to, 1 - count);
      const { cats, txs, recurring } = await withUser(deps.db, user.id, async (tx) => {
        await materializeMonths(tx, user, monthsBetween(from, to), currentMonth(deps, user));
        return {
          cats: await tx.select({ id: categories.id, kind: categories.kind }).from(categories),
          txs: await tx
            .select({
              categoryId: transactions.categoryId,
              amount: transactions.amount,
              date: transactions.date,
            })
            .from(transactions)
            .where(inRange(from, to)),
          // Recurrences still running at the start of the window (or later) make a category fixed.
          recurring: await tx
            .selectDistinct({ categoryId: recurrences.categoryId })
            .from(recurrences)
            .where(or(isNull(recurrences.endDate), gte(recurrences.endDate, firstDay(from)))),
        };
      });
      return c.json(
        costOfLiving({
          months: monthsBetween(from, to),
          categories: cats,
          fixedCategoryIds: recurring.map((r) => r.categoryId),
          transactions: txs,
        }),
        200,
      );
    },
  );

  return app;
}
