import { createRoute, z } from "@hono/zod-openapi";
import {
  type CategoryDto,
  categoryDto,
  createCategorySchema,
  effectiveBudget,
  firstDay,
  type Month,
  setBudgetSchema,
  updateCategorySchema,
} from "@lukas/core";
import { categories, categoryBudgets, type Tx, transactions, withUser } from "@lukas/db";
import { asc, eq, isNull } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import { isUniqueViolation } from "../http/db-errors.ts";
import { jsonBody, jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import { currentMonth } from "../services/time.ts";

type CategoryRow = typeof categories.$inferSelect;
const idParam = z.object({ id: z.uuid() });

async function budgetsFor(tx: Tx) {
  const rows = await tx.select().from(categoryBudgets);
  return rows.map((r) => ({
    categoryId: r.categoryId,
    amount: r.amount,
    effectiveFrom: r.effectiveFrom.slice(0, 7),
  }));
}

function toDto(
  row: CategoryRow,
  budgets: Awaited<ReturnType<typeof budgetsFor>>,
  month: Month,
): CategoryDto {
  return {
    id: row.id,
    name: row.name,
    kind: row.kind,
    icon: row.icon,
    color: row.color,
    sortOrder: row.sortOrder,
    archived: row.archivedAt !== null,
    currentBudget: row.kind === "expense" ? effectiveBudget(budgets, row.id, month) : null,
  };
}

export async function findCategory(tx: Tx, id: string): Promise<CategoryRow> {
  const [row] = await tx.select().from(categories).where(eq(categories.id, id));
  if (!row) throw new ApiError(404, "not_found", "Category not found");
  return row;
}

function nameTaken(error: unknown): never {
  if (isUniqueViolation(error)) {
    throw new ApiError(409, "category_name_taken", "You already have a category with that name");
  }
  throw error;
}

export function categoryRoutes(deps: AppDeps) {
  const app = router();

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/categories",
      request: { query: z.object({ includeArchived: z.enum(["true", "false"]).optional() }) },
      responses: { 200: jsonResponse(z.array(categoryDto), "Categories") },
    }),
    async (c) => {
      const includeArchived = c.req.valid("query").includeArchived === "true";
      const month = currentMonth(c.get("user"));
      const result = await withUser(deps.db, c.get("userId"), async (tx) => {
        const rows = await tx
          .select()
          .from(categories)
          .where(includeArchived ? undefined : isNull(categories.archivedAt))
          .orderBy(asc(categories.sortOrder), asc(categories.createdAt));
        const budgets = await budgetsFor(tx);
        return rows.map((r) => toDto(r, budgets, month));
      });
      return c.json(result, 200);
    },
  );

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/categories",
      request: { body: jsonBody(createCategorySchema) },
      responses: { 201: jsonResponse(categoryDto, "Created"), ...problems(409, 422) },
    }),
    async (c) => {
      const input = c.req.valid("json");
      const userId = c.get("userId");
      const row = await withUser(deps.db, userId, async (tx) => {
        const [created] = await tx
          .insert(categories)
          .values({ ...input, userId })
          .returning();
        return created as CategoryRow;
      }).catch(nameTaken);
      return c.json(toDto(row, [], currentMonth(c.get("user"))), 201);
    },
  );

  app.openapi(
    createRoute({
      method: "patch",
      path: "/v1/categories/{id}",
      request: { params: idParam, body: jsonBody(updateCategorySchema) },
      responses: { 200: jsonResponse(categoryDto, "Updated"), ...problems(404, 409, 422) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      const { archived, ...fields } = c.req.valid("json");
      const month = currentMonth(c.get("user"));
      const dto = await withUser(deps.db, c.get("userId"), async (tx) => {
        const existing = await findCategory(tx, id);
        // Spending ↔ income only while nothing was ever booked under it: its transactions' signs
        // would no longer mean what they meant. Soft-deleted ones count, as for the currency lock:
        // they can be restored.
        if (fields.kind && fields.kind !== existing.kind) {
          const [booked] = await tx
            .select({ id: transactions.id })
            .from(transactions)
            .where(eq(transactions.categoryId, id))
            .limit(1);
          if (booked) {
            throw new ApiError(
              409,
              "category_has_transactions",
              "A category with transactions cannot change its kind",
            );
          }
        }
        const archivedAt =
          archived === undefined
            ? existing.archivedAt
            : archived
              ? (existing.archivedAt ?? new Date())
              : null;
        const [row] = await tx
          .update(categories)
          .set({ ...fields, archivedAt })
          .where(eq(categories.id, id))
          .returning();
        return toDto(row as CategoryRow, await budgetsFor(tx), month);
      }).catch(nameTaken);
      return c.json(dto, 200);
    },
  );

  app.openapi(
    createRoute({
      method: "put",
      path: "/v1/categories/{id}/budget",
      request: { params: idParam, body: jsonBody(setBudgetSchema) },
      responses: { 200: jsonResponse(categoryDto, "Budget set"), ...problems(404, 422) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      const { amount, effectiveFrom } = c.req.valid("json");
      const userId = c.get("userId");
      const month = currentMonth(c.get("user"));
      const dto = await withUser(deps.db, userId, async (tx) => {
        const category = await findCategory(tx, id);
        if (category.kind !== "expense") {
          throw new ApiError(
            422,
            "budget_category_not_expense",
            "Only expense categories have budgets",
          );
        }
        await tx
          .insert(categoryBudgets)
          .values({ userId, categoryId: id, amount, effectiveFrom: firstDay(effectiveFrom) })
          .onConflictDoUpdate({
            target: [categoryBudgets.categoryId, categoryBudgets.effectiveFrom],
            set: { amount },
          });
        return toDto(category, await budgetsFor(tx), month);
      });
      return c.json(dto, 200);
    },
  );

  return app;
}
