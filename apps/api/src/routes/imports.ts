import { createHash } from "node:crypto";
import { createRoute, z } from "@hono/zod-openapi";
import { SUPPORTED_CURRENCIES } from "@lukas/core";
import {
  accounts,
  categories,
  categoryBudgets,
  imports,
  recurrences,
  type Tx,
  transactions,
  withUser,
} from "@lukas/db";
import { and, asc, eq, inArray, ne } from "@lukas/db/orm";
import {
  averageMonthlySpending,
  averageWindow,
  type BudgeRow,
  categoryStyle,
  fileCurrency,
  inferCategoryKinds,
  normalizeName,
  parseBudgeCsv,
  rowHashes,
  UnrecognizedFormatError,
} from "@lukas/importers";
import type { AppDeps } from "../deps.ts";
import { jsonResponse, problems } from "../http/openapi.ts";
import { ApiError } from "../http/problem.ts";
import { router } from "../http/router.ts";
import { currentMonth } from "../services/time.ts";
import { defaultAccount } from "../services/transactions.ts";

const MAX_BYTES = 5 * 1024 * 1024;
/**
 * The preview's monthly averages (what onboarding prefills budgets with) cover the last 3 complete
 * months: years of history would otherwise average in categories long dropped.
 */
const AVERAGE_MONTHS = 3;
const INSERT_CHUNK = 500;
const idParam = z.object({ id: z.uuid() });

type ImportRow = typeof imports.$inferSelect;
type PayloadRow = BudgeRow & { hash: string };

const statsSchema = z
  .object({
    transactions: z.number().int(),
    duplicates: z.number().int(),
    newCategories: z.array(z.string()),
    rejected: z.array(z.object({ line: z.number().int(), reason: z.string() })),
    from: z.string().nullable(),
    to: z.string().nullable(),
    /** Per expense category, the average over the last 3 complete months (the running one excluded). */
    averageMonthlySpending: z.array(z.object({ category: z.string(), amount: z.number().int() })),
    /**
     * The file's currency (what most of its rows use), even when it is not the account's: those
     * rows are rejected as `currency_mismatch`, and a client can switch an empty account to this
     * currency and read the file again. Null for a file without rows (and for older previews).
     */
    currency: z.string().nullable(),
    /**
     * The months `averageMonthlySpending` covers: up to the last 3 complete ones, starting no earlier
     * than the file. Null when no complete month is left (and for older previews).
     */
    averageWindow: z
      .object({ from: z.string(), to: z.string(), months: z.number().int() })
      .nullable(),
    /**
     * The account has no transactions and the file is in another supported currency: the preview
     * already counts the file's rows in that currency, and confirming with `adoptFileCurrency`
     * switches the account to it (in the same transaction as the inserts).
     */
    adoptsCurrency: z.boolean(),
    /** Adopting the currency removes the account's budgets (their amounts are in the old one). */
    dropsBudgets: z.boolean(),
    inserted: z.number().int().optional(),
  })
  .openapi("ImportStats");
type ImportStats = z.infer<typeof statsSchema>;
const importDto = z
  .object({
    id: z.uuid(),
    status: z.enum(["preview", "confirmed", "reverted"]),
    stats: statsSchema,
  })
  .openapi("FileImport");
const toDto = (row: ImportRow) => {
  type Optional = "currency" | "averageWindow" | "adoptsCurrency" | "dropsBudgets";
  // Older previews were stored before these fields existed.
  const stats = row.stats as Omit<ImportStats, Optional> & Partial<Pick<ImportStats, Optional>>;
  return {
    id: row.id,
    status: row.status,
    stats: {
      ...stats,
      currency: stats.currency ?? null,
      averageWindow: stats.averageWindow ?? null,
      adoptsCurrency: stats.adoptsCurrency ?? false,
      dropsBudgets: stats.dropsBudgets ?? false,
    },
  };
};

async function existingHashes(tx: Tx, hashes: string[]): Promise<Set<string>> {
  const found = new Set<string>();
  for (let i = 0; i < hashes.length; i += INSERT_CHUNK) {
    const rows = await tx
      .select({ hash: transactions.externalHash })
      .from(transactions)
      .where(inArray(transactions.externalHash, hashes.slice(i, i + INSERT_CHUNK)));
    for (const r of rows) if (r.hash) found.add(r.hash);
  }
  return found;
}

async function assertFileNotImported(tx: Tx, fileHash: string, exceptId?: string) {
  const [dup] = await tx
    .select({ id: imports.id })
    .from(imports)
    .where(
      and(
        eq(imports.fileHash, fileHash),
        eq(imports.status, "confirmed"),
        exceptId ? ne(imports.id, exceptId) : undefined,
      ),
    );
  if (dup) throw new ApiError(409, "import_duplicate_file", "This file was already imported");
}

/** Whether the account has any transaction, soft-deleted ones included (as the currency lock). */
/**
 * Whether the account's currency is settled: it has transactions (soft-deleted ones too), or
 * recurrences, which would later materialize their old-currency amounts in a new currency.
 */
async function currencyLocked(tx: Tx, accountId: string): Promise<boolean> {
  const [found] = await tx
    .select({ id: transactions.id })
    .from(transactions)
    .where(eq(transactions.accountId, accountId))
    .limit(1);
  if (found) return true;
  const [recurrence] = await tx
    .select({ id: recurrences.id })
    .from(recurrences)
    .where(eq(recurrences.accountId, accountId))
    .limit(1);
  return recurrence !== undefined;
}

async function findImport(tx: Tx, id: string): Promise<ImportRow> {
  const [row] = await tx.select().from(imports).where(eq(imports.id, id));
  if (!row) throw new ApiError(404, "not_found", "Import not found");
  return row;
}

export function importRoutes(deps: AppDeps) {
  const app = router();

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/imports",
      operationId: "createImport",
      request: {
        body: {
          content: {
            "multipart/form-data": {
              schema: z.object({
                source: z.literal("budge"),
                file: z.instanceof(File).openapi({ type: "string", format: "binary" }),
              }),
            },
          },
          required: true,
        },
      },
      responses: { 201: jsonResponse(importDto, "Preview"), ...problems(409, 413, 422) },
    }),
    async (c) => {
      const { file } = c.req.valid("form");
      if (file.size > MAX_BYTES)
        throw new ApiError(413, "import_too_large", "Files are limited to 5 MB");
      const text = await file.text();
      const fileHash = createHash("sha256").update(text).digest("hex");
      let parsed: ReturnType<typeof parseBudgeCsv>;
      try {
        parsed = parseBudgeCsv(text);
      } catch (error) {
        if (error instanceof UnrecognizedFormatError) {
          throw new ApiError(
            422,
            "import_unrecognized_format",
            "This does not look like a Budge export",
          );
        }
        throw error;
      }

      const userId = c.get("userId");
      const row = await withUser(deps.db, userId, async (tx) => {
        await assertFileNotImported(tx, fileHash);
        const account = await defaultAccount(tx);
        // An empty account can take the file's currency on confirm: the preview counts the file's
        // rows in it. With transactions or recurrences, the account's currency stands and other
        // rows are rejected.
        const fromFile = fileCurrency(parsed.rows);
        const adoptsCurrency =
          fromFile !== null &&
          fromFile !== account.currency &&
          (SUPPORTED_CURRENCIES as readonly string[]).includes(fromFile) &&
          !(await currencyLocked(tx, account.id));
        const target = adoptsCurrency ? (fromFile as string) : account.currency;
        const dropsBudgets =
          adoptsCurrency &&
          (await tx.select({ id: categoryBudgets.id }).from(categoryBudgets).limit(1)).length > 0;
        const rejected: ImportStats["rejected"] = [...parsed.rejected];
        const rows = parsed.rows.filter((r) => {
          if (r.currency === target) return true;
          rejected.push({ line: r.line, reason: "currency_mismatch" });
          return false;
        });
        rejected.sort((x, y) => x.line - y.line);
        const hashes = rowHashes(rows);
        const known = await existingHashes(tx, hashes);
        const existingNames = new Set(
          (await tx.select({ name: categories.name }).from(categories)).map((cat) =>
            normalizeName(cat.name),
          ),
        );
        const newCategories = [
          ...new Map(
            rows
              .filter((r) => !existingNames.has(normalizeName(r.category)))
              .map((r) => [normalizeName(r.category), r.category]),
          ).values(),
        ];
        const dates = rows.map((r) => r.date).sort();
        const recent = { months: AVERAGE_MONTHS, until: currentMonth(deps, c.get("user")) };
        const stats: ImportStats = {
          transactions: rows.length,
          duplicates: hashes.filter((h) => known.has(h)).length,
          newCategories,
          rejected,
          from: dates[0] ?? null,
          to: dates.at(-1) ?? null,
          averageMonthlySpending: averageMonthlySpending(rows, recent),
          averageWindow: averageWindow(rows, recent),
          currency: fromFile,
          adoptsCurrency,
          dropsBudgets,
        };
        const payload: PayloadRow[] = rows.map((r, i) => ({ ...r, hash: hashes[i] as string }));
        const [created] = await tx
          .insert(imports)
          .values({ userId, source: "budge", fileHash, stats, payload })
          .returning();
        return created as ImportRow;
      });
      return c.json(toDto(row), 201);
    },
  );

  app.openapi(
    createRoute({
      method: "post",
      path: "/v1/imports/{id}/confirm",
      operationId: "confirmImport",
      request: {
        params: idParam,
        body: {
          content: {
            "application/json": {
              schema: z
                .object({
                  /**
                   * Switch the (still empty) account to the file's currency before inserting, as
                   * the preview's `adoptsCurrency` said. Without it, a currency mismatch is a 409.
                   */
                  adoptFileCurrency: z.boolean().optional(),
                })
                .openapi("ConfirmImport"),
            },
          },
          required: false,
        },
      },
      responses: { 200: jsonResponse(importDto, "Imported"), ...problems(404, 409) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      const { adoptFileCurrency = false } = c.req.valid("json") ?? {};
      const userId = c.get("userId");
      const row = await withUser(deps.db, userId, async (tx) => {
        // Locked before anything is read: a currency change waits for these inserts, then finds
        // the account no longer empty (see `setCurrency` in me.ts), and a second confirm of the
        // same preview waits too, then reads it as confirmed below and changes nothing.
        const account = await defaultAccount(tx, { lock: true });
        const imp = await findImport(tx, id);
        if (imp.status !== "preview")
          throw new ApiError(409, "import_not_in_preview", "This import is not a preview");
        await assertFileNotImported(tx, imp.fileHash, imp.id);
        const rows = (imp.payload ?? []) as PayloadRow[];
        // The preview kept rows in one currency: the account's, or the file's when it could adopt
        // it. Under the lock, a different one goes in only by adopting it now, and only while the
        // account is still empty (no transactions, no recurrences); the old currency's budgets go
        // with it. Otherwise the currency changed since the preview, and the rows would go in
        // under the wrong one.
        const rowCurrency = rows[0]?.currency;
        if (rowCurrency && rows.some((r) => r.currency !== account.currency)) {
          if (!adoptFileCurrency) {
            throw new ApiError(
              409,
              "import_currency_changed",
              "The account's currency changed after this preview; upload the file again",
            );
          }
          if (await currencyLocked(tx, account.id)) {
            throw new ApiError(
              409,
              "currency_locked",
              "The currency cannot change once the account has transactions",
            );
          }
          await tx
            .update(accounts)
            .set({ currency: rowCurrency })
            .where(eq(accounts.id, account.id));
          await tx.delete(categoryBudgets);
          account.currency = rowCurrency;
        }

        // Rows go to the active category of the same name (without case or accents); one that
        // exists only archived is brought back and used; otherwise one is created. Oldest first,
        // so the choice is the same every time.
        const existing = await tx
          .select()
          .from(categories)
          .orderBy(asc(categories.createdAt), asc(categories.id));
        const categoryIds = new Map<string, string>();
        const archivedIds = new Map<string, string>();
        for (const cat of existing) {
          const key = normalizeName(cat.name);
          const into = cat.archivedAt === null ? categoryIds : archivedIds;
          if (!into.has(key)) into.set(key, cat.id);
        }
        const kinds = inferCategoryKinds(rows);
        for (const r of rows) {
          const key = normalizeName(r.category);
          if (categoryIds.has(key)) continue;
          const archived = archivedIds.get(key);
          if (archived) {
            await tx
              .update(categories)
              .set({ archivedAt: null })
              .where(eq(categories.id, archived));
            categoryIds.set(key, archived);
            continue;
          }
          const [created] = await tx
            .insert(categories)
            .values({
              userId,
              name: r.category,
              kind: kinds.get(key) ?? "expense",
              ...categoryStyle(r.category),
            })
            .returning({ id: categories.id });
          if (created) categoryIds.set(key, created.id);
        }

        let inserted = 0;
        for (let i = 0; i < rows.length; i += INSERT_CHUNK) {
          const values = rows.slice(i, i + INSERT_CHUNK).map((r) => ({
            userId,
            accountId: account.id,
            categoryId: categoryIds.get(normalizeName(r.category)) as string,
            name: r.name,
            amount: r.amount,
            currency: r.currency,
            date: r.date,
            status: r.status,
            note: r.note,
            source: "import" as const,
            importId: imp.id,
            externalHash: r.hash,
          }));
          const result = await tx
            .insert(transactions)
            .values(values)
            .onConflictDoNothing()
            .returning({ id: transactions.id });
          inserted += result.length;
        }

        const [updated] = await tx
          .update(imports)
          .set({
            status: "confirmed",
            payload: null,
            stats: { ...(imp.stats as ImportStats), inserted },
          })
          .where(eq(imports.id, imp.id))
          .returning();
        return updated as ImportRow;
      });
      return c.json(toDto(row), 200);
    },
  );

  app.openapi(
    createRoute({
      method: "delete",
      path: "/v1/imports/{id}",
      operationId: "revertImport",
      request: { params: idParam },
      responses: { 204: { description: "Reverted" }, ...problems(404) },
    }),
    async (c) => {
      const { id } = c.req.valid("param");
      await withUser(deps.db, c.get("userId"), async (tx) => {
        const imp = await findImport(tx, id);
        if (imp.status === "confirmed")
          await tx.delete(transactions).where(eq(transactions.importId, imp.id));
        await tx
          .update(imports)
          .set({ status: "reverted", payload: null })
          .where(eq(imports.id, imp.id));
      });
      return c.body(null, 204);
    },
  );

  return app;
}
