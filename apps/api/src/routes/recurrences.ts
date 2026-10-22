import { createRoute, z } from "@hono/zod-openapi";
import {
  createRecurrenceSchema,
  firstDay,
  type RecurrenceDto,
  recurrenceDto,
  updateRecurrenceSchema,
} from "@lukas/core";
import { recurrences, type Tx, transactions, withUser } from "@lukas/db";
import { and, asc, eq, gte, isNull } from "@lukas/db/orm";
import type { AppDeps } from "../deps.ts";
import { jsonBody, jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import { dropPendingOccurrences } from "../services/recurrence-stop.ts";
import { currentMonth } from "../services/time.ts";
import { defaultAccount, requireActiveCategory } from "../services/transactions.ts";

type RecurrenceRow = typeof recurrences.$inferSelect;
const idParam = z.object({ id: z.uuid() });

const toDto = (row: RecurrenceRow): RecurrenceDto => ({
  id: row.id,
  name: row.name,
  amount: row.amount,
  categoryId: row.categoryId,
  frequency: row.frequency,
  dayOfMonth: row.dayOfMonth,
  monthOfYear: row.monthOfYear,
  startDate: row.startDate,
  endDate: row.endDate,
});

async function findRecurrence(tx: Tx, id: string): Promise<RecurrenceRow> {
  const [row] = await tx.select().from(recurrences).where(eq(recurrences.id, id));
  if (!row) throw new ApiError(404, "not_found", "Recurrence not found");
  return row;
}

export function recurrenceRoutes(deps: AppDeps) {
  const app = router();

  app.openapi(
    createRoute({
      method: "get",
      path: "/v1/recurrences",
      responses: { 200: jsonResponse(z.array(recurrenceDto), "Recurrences") },
    }),
    async (c) => {
      const rows = await withUser(deps.db, c.get("userId"), (tx) =>
        tx.select().from(recurrences).orderBy(asc(recurrences.createdAt)),
      );
      return c.json(rows.map(toDto), 200);
    },
  );

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/recurrences",
      request: { body: jsonBody(createRecurrenceSchema) },
      responses: { 201: jsonResponse(recurrenceDto, "Created"), ...problems(422) },
    }),
    async (c) => {
      const input = c.req.valid("json");
      const userId = c.get("userId");
      const row = await withUser(deps.db, userId, async (tx) => {
        await requireActiveCategory(tx, input.categoryId);
        // Locked like a new transaction: a currency switch in flight (PATCH /v1/me, an import that
        // adopts the file's currency) finishes first, and one after this finds the account locked.
        const account = await defaultAccount(tx, { lock: true });
        const [created] = await tx
          .insert(recurrences)
          .values({
            ...input,
            monthOfYear: input.monthOfYear ?? null,
            endDate: input.endDate ?? null,
            userId,
            accountId: account.id,
          })
          .returning();
        return created as RecurrenceRow;
      });
      return c.json(toDto(row), 201);
    },
  );

  app.openapi(
    createRoute({
      method: "patch",
      path: "/v1/recurrences/{id}",
      request: { params: idParam, body: jsonBody(updateRecurrenceSchema) },
      responses: { 200: jsonResponse(recurrenceDto, "Updated"), ...problems(404, 422) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      const input = c.req.valid("json");
      const row = await withUser(deps.db, c.get("userId"), async (tx) => {
        // Locked like any recurrence write: a read materializing this rule finishes first (and
        // its pending rows are then dropped below), and one after this sees the new rule.
        await defaultAccount(tx, { lock: true });
        const existing = await findRecurrence(tx, id);
        if (input.categoryId) await requireActiveCategory(tx, input.categoryId);
        const merged = { ...existing, ...input };
        const check = createRecurrenceSchema.safeParse(merged);
        if (!check.success) {
          throw new ApiError(
            422,
            "validation_failed",
            "The recurrence is invalid",
            check.error.issues.map((i) => ({ path: i.path.join("."), message: i.message })),
          );
        }
        const [updated] = await tx
          .update(recurrences)
          .set(input)
          .where(eq(recurrences.id, id))
          .returning();
        // Pending occurrences from this month on follow the new rule: drop them so the next read
        // regenerates them. Paid and soft-deleted (dismissed) occurrences are kept.
        await dropPendingOccurrences(tx, [id], { fromMonth: currentMonth(deps, c.get("user")) });
        return updated as RecurrenceRow;
      });
      return c.json(toDto(row), 200);
    },
  );

  app.openapi(
    createRoute({
      method: "delete",
      path: "/v1/recurrences/{id}",
      request: { params: idParam },
      responses: {
        204: {
          description:
            "Deleted; its unpaid pending transactions from this month on go, the rest are kept",
        },
        ...problems(404),
      },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      await withUser(deps.db, c.get("userId"), async (tx) => {
        // Locked like any recurrence write: a read materializing this rule finishes first (its
        // pending rows are then dropped below), and one after this no longer sees the rule.
        await defaultAccount(tx, { lock: true });
        await findRecurrence(tx, id);
        // Like an edit: its unpaid pending rows from this month on go (they would look like bills
        // still due). The FK is ON DELETE SET NULL, so paid, past and dismissed ones stay, with
        // recurrence_id = null.
        await dropPendingOccurrences(tx, [id], { fromMonth: currentMonth(deps, c.get("user")) });
        await tx.delete(recurrences).where(eq(recurrences.id, id));
      });
      return c.body(null, 204);
    },
  );

  return app;
}
