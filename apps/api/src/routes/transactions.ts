import { createRoute, z } from "@hono/zod-openapi";
import {
  createTransactionSchema,
  firstDay,
  lastDay,
  monthSchema,
  transactionDto,
  updateTransactionSchema,
} from "@lukas/core";
import { type Tx, transactions, withUser } from "@lukas/db";
import { and, desc, eq, gte, isNotNull, isNull, lte, type SQL, sql } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import { idempotent } from "../http/idempotency.ts";
import { jsonBody, jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import { materializeRecurrences } from "../services/materialize.ts";
import { currentMonth } from "../services/time.ts";
import {
  defaultAccount,
  requireActiveCategory,
  type TransactionRow,
  toTransactionDto,
} from "../services/transactions.ts";

const idParam = z.object({ id: z.uuid() });
const listQuery = z.object({
  month: monthSchema.optional(),
  category: z.uuid().optional(),
  status: z.enum(["paid", "pending"]).optional(),
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

const encodeCursor = (row: TransactionRow) =>
  Buffer.from(`${row.date}|${row.id}`).toString("base64url");
function decodeCursor(cursor: string): { date: string; id: string } {
  const [date, id] = Buffer.from(cursor, "base64url").toString().split("|");
  if (!date || !id || !z.uuid().safeParse(id).success) {
    throw new ApiError(422, "validation_failed", "Invalid cursor", [
      { path: "cursor", message: "Invalid cursor" },
    ]);
  }
  return { date, id };
}

async function findLive(tx: Tx, id: string): Promise<TransactionRow> {
  const [row] = await tx
    .select()
    .from(transactions)
    .where(and(eq(transactions.id, id), isNull(transactions.deletedAt)));
  if (!row) throw new ApiError(404, "not_found", "Transaction not found");
  return row;
}

export function transactionRoutes(deps: AppDeps) {
  const app = router();

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/transactions",
      request: { query: listQuery },
      responses: {
        200: jsonResponse(
          z.object({ items: z.array(transactionDto), nextCursor: z.string().nullable() }),
          "A page of transactions, newest first",
        ),
        ...problems(422),
      },
    }),
    async (c) => {
      const q = c.req.valid("query");
      const user = c.get("user");
      const filters: (SQL | undefined)[] = [isNull(transactions.deletedAt)];
      if (q.month)
        filters.push(
          gte(transactions.date, firstDay(q.month)),
          lte(transactions.date, lastDay(q.month)),
        );
      if (q.category) filters.push(eq(transactions.categoryId, q.category));
      if (q.status) filters.push(eq(transactions.status, q.status));
      if (q.cursor) {
        const { date, id } = decodeCursor(q.cursor);
        filters.push(
          sql`(${transactions.date}, ${transactions.id}) < (${date}::date, ${id}::uuid)`,
        );
      }
      const rows = await withUser(deps.db, user.id, async (tx) => {
        if (q.month) await materializeRecurrences(tx, user.id, q.month, currentMonth(user));
        return tx
          .select()
          .from(transactions)
          .where(and(...filters))
          .orderBy(desc(transactions.date), desc(transactions.id))
          .limit(q.limit + 1);
      });
      const items = rows.slice(0, q.limit);
      const last = items.at(-1);
      return c.json(
        {
          items: items.map(toTransactionDto),
          nextCursor: rows.length > q.limit && last ? encodeCursor(last) : null,
        },
        200,
      );
    },
  );

  app.use("/v1/transactions", async (c, next) =>
    c.req.method === "POST" ? idempotent(deps.db)(c, next) : next(),
  );
  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/transactions",
      request: { body: jsonBody(createTransactionSchema) },
      responses: { 201: jsonResponse(transactionDto, "Created"), ...problems(422) },
    }),
    async (c) => {
      const input = c.req.valid("json");
      const userId = c.get("userId");
      const row = await withUser(deps.db, userId, async (tx) => {
        await requireActiveCategory(tx, input.categoryId);
        const account = await defaultAccount(tx);
        const [created] = await tx
          .insert(transactions)
          .values({ ...input, userId, accountId: account.id, currency: account.currency })
          .returning();
        return created as TransactionRow;
      });
      return c.json(toTransactionDto(row), 201);
    },
  );

  app.openapi(
    createRoute({
      method: "patch",
      path: "/v1/transactions/{id}",
      request: { params: idParam, body: jsonBody(updateTransactionSchema) },
      responses: { 200: jsonResponse(transactionDto, "Updated"), ...problems(404, 422) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      const input = c.req.valid("json");
      const row = await withUser(deps.db, c.get("userId"), async (tx) => {
        await findLive(tx, id);
        if (input.categoryId) await requireActiveCategory(tx, input.categoryId);
        const [updated] = await tx
          .update(transactions)
          .set(input)
          .where(eq(transactions.id, id))
          .returning();
        return updated as TransactionRow;
      });
      return c.json(toTransactionDto(row), 200);
    },
  );

  app.openapi(
    createRoute({
      method: "delete",
      path: "/v1/transactions/{id}",
      request: { params: idParam },
      responses: { 204: { description: "Deleted (restorable)" }, ...problems(404) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      await withUser(deps.db, c.get("userId"), async (tx) => {
        await findLive(tx, id);
        await tx.update(transactions).set({ deletedAt: new Date() }).where(eq(transactions.id, id));
      });
      return c.body(null, 204);
    },
  );

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/transactions/{id}/restore",
      request: { params: idParam },
      responses: { 200: jsonResponse(transactionDto, "Restored"), ...problems(404) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      const row = await withUser(deps.db, c.get("userId"), async (tx) => {
        const [restored] = await tx
          .update(transactions)
          .set({ deletedAt: null })
          .where(and(eq(transactions.id, id), isNotNull(transactions.deletedAt)))
          .returning();
        if (restored) return restored;
        return findLive(tx, id);
      });
      return c.json(toTransactionDto(row), 200);
    },
  );

  return app;
}
