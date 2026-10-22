import { createRoute, z } from "@hono/zod-openapi";
import {
  firstDay,
  isIsoDate,
  lastDay,
  monthSchema,
  type CreateTransaction as NewTransaction,
} from "@lukas/core";
import { type Tx, transactions, withUser } from "@lukas/db";
import { and, desc, eq, gte, inArray, isNotNull, isNull, lte, type SQL, sql } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import { idempotent } from "../http/idempotency.ts";
import { jsonBody, jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import {
  CreateTransaction,
  CreateTransactionsBatch,
  DeleteTransactionsBatch,
  idempotencyKeyHeader,
  Transaction,
  UpdateTransaction,
} from "../http/schemas.ts";
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

const suggestionsQuery = z.object({
  q: z.string().trim().max(100).optional(),
  limit: z.coerce.number().int().min(1).max(20).default(8),
});
const TransactionSuggestion = z
  .object({ name: z.string(), categoryId: z.uuid() })
  .openapi("TransactionSuggestion");
const TransactionPage = z
  .object({ items: z.array(Transaction), nextCursor: z.string().nullable() })
  .openapi("TransactionPage");
const TransactionList = z.object({ items: z.array(Transaction) }).openapi("TransactionList");

const encodeCursor = (row: TransactionRow) =>
  Buffer.from(`${row.date}|${row.id}`).toString("base64url");
function decodeCursor(cursor: string): { date: string; id: string } {
  const [date, id] = Buffer.from(cursor, "base64url").toString().split("|");
  if (!date || !isIsoDate(date) || !id || !z.uuid().safeParse(id).success) {
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
      operationId: "listTransactions",
      request: { query: listQuery },
      responses: {
        200: jsonResponse(TransactionPage, "A page of transactions, newest first"),
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
        if (q.month) await materializeRecurrences(tx, user.id, q.month, currentMonth(deps, user));
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

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/transactions/suggestions",
      operationId: "listTransactionSuggestions",
      request: { query: suggestionsQuery },
      responses: {
        200: jsonResponse(
          z.object({ items: z.array(TransactionSuggestion) }).openapi("TransactionSuggestions"),
          "Transaction names already used, with the category they usually go in, most used first (ties: most recent)",
        ),
        ...problems(422),
      },
    }),
    async (c) => {
      const { q, limit } = c.req.valid("query");
      const needle = (q ?? "").toLowerCase();
      // A name that equals its category's name is the default, not a shortcut, so it is skipped.
      // `position` (not LIKE) keeps `%` and `_` in the search text literal.
      const rows = await withUser(deps.db, c.get("userId"), (tx) =>
        tx.execute<{ name: string; category_id: string }>(sql`
          with used as (
            select lower(t.name) as key, t.name, t.category_id, t.date, t.created_at
            from transactions t
            join categories c on c.id = t.category_id
            where t.deleted_at is null
              and c.archived_at is null
              and lower(t.name) <> lower(c.name)
          ),
          latest as (
            select distinct on (key) key, name, date, created_at
            from used
            order by key, date desc, created_at desc
          ),
          uses as (
            select key, count(*) as uses from used group by key
          ),
          usual as (
            select distinct on (key) key, category_id
            from (
              select key, category_id, count(*) as uses, max(date) as last_date,
                max(created_at) as last_created
              from used
              group by key, category_id
            ) per_category
            order by key, uses desc, last_date desc, last_created desc
          )
          select latest.name, usual.category_id
          from latest
          join usual using (key)
          join uses using (key)
          where ${needle} = '' or position(${needle} in latest.key) > 0
          order by (position(${needle} in latest.key) = 1) desc,
            uses.uses desc, latest.date desc, latest.created_at desc
          limit ${limit}
        `),
      );
      return c.json({ items: rows.map((r) => ({ name: r.name, categoryId: r.category_id })) }, 200);
    },
  );

  app.use("/v1/transactions", async (c, next) =>
    c.req.method === "POST" ? idempotent(deps.db)(c, next) : next(),
  );
  // A retried batch would save everything twice, so here the key is mandatory.
  app.use("/v1/transactions/batch", idempotent(deps.db, { required: true }));

  /** The one insert path for single and batch create: category check, account lock, currency. */
  async function insertTransactions(tx: Tx, userId: string, inputs: NewTransaction[]) {
    for (const categoryId of new Set(inputs.map((i) => i.categoryId))) {
      await requireActiveCategory(tx, categoryId);
    }
    // Locked like the import's: the currency cannot change under these inserts.
    const account = await defaultAccount(tx, { lock: true });
    return (await tx
      .insert(transactions)
      .values(
        inputs.map((i) => ({ ...i, userId, accountId: account.id, currency: account.currency })),
      )
      .returning()) as TransactionRow[];
  }

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/transactions",
      operationId: "createTransaction",
      request: {
        headers: idempotencyKeyHeader({ required: false }),
        body: jsonBody(CreateTransaction),
      },
      responses: { 201: jsonResponse(Transaction, "Created"), ...problems(422) },
    }),
    async (c) => {
      const input = c.req.valid("json");
      const userId = c.get("userId");
      const [row] = await withUser(deps.db, userId, (tx) =>
        insertTransactions(tx, userId, [input]),
      );
      return c.json(toTransactionDto(row as TransactionRow), 201);
    },
  );

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/transactions/batch",
      operationId: "createTransactionsBatch",
      description:
        "Saves up to 20 transactions in one transaction: all or nothing. `Idempotency-Key` is required; a retry with the same key and body returns the first response.",
      request: {
        headers: idempotencyKeyHeader({ required: true }),
        body: jsonBody(CreateTransactionsBatch),
      },
      responses: {
        201: jsonResponse(TransactionList, "Created, in request order"),
        ...problems(400, 422),
      },
    }),
    async (c) => {
      const { items } = c.req.valid("json");
      const userId = c.get("userId");
      const rows = await withUser(deps.db, userId, (tx) => insertTransactions(tx, userId, items));
      return c.json({ items: rows.map(toTransactionDto) }, 201);
    },
  );

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/transactions/batch-delete",
      operationId: "deleteTransactionsBatch",
      description:
        "Soft-deletes (restorable) the given transactions that are the caller's. Other ids are ignored without a trace.",
      request: { body: jsonBody(DeleteTransactionsBatch) },
      responses: { 204: { description: "Deleted (restorable)" }, ...problems(422) },
    }),
    async (c) => {
      const { ids } = c.req.valid("json");
      await withUser(deps.db, c.get("userId"), (tx) =>
        tx
          .update(transactions)
          .set({ deletedAt: new Date() })
          .where(and(inArray(transactions.id, ids), isNull(transactions.deletedAt))),
      );
      return c.body(null, 204);
    },
  );

  app.openapi(
    createRoute({
      method: "patch",
      path: "/v1/transactions/{id}",
      operationId: "updateTransaction",
      request: { params: idParam, body: jsonBody(UpdateTransaction) },
      responses: { 200: jsonResponse(Transaction, "Updated"), ...problems(404, 422) },
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
      operationId: "deleteTransaction",
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
      operationId: "restoreTransaction",
      request: { params: idParam },
      responses: { 200: jsonResponse(Transaction, "Restored"), ...problems(404) },
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
