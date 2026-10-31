import {
  type CategoryDto,
  type CreateTransaction,
  createRecurrenceSchema,
  type RecurrenceDto,
  type UpdateRecurrence,
  type UpdateTransaction,
} from "@lukas/core";
import { z } from "zod";
import { normalizeName } from "../categories.ts";
import { ToolError } from "../errors.ts";
import type { Profile } from "../lukitas.ts";
import { formatMoney, fromMinor, toMinor } from "../money.ts";
import { phrases, quote } from "../text.ts";
import { defineTool } from "../tool.ts";
import {
  amountInput,
  byId,
  categoryInput,
  categoryOutput,
  chunks,
  currentMonth,
  DATA_NOTE,
  dateInput,
  findCategory,
  invalid,
  kindInput,
  money,
  moneyOutput,
  monthInput,
  toCategoryOutput,
  today,
  toTransactionOutput,
  transactionOutput,
} from "./shared.ts";

/** Items per write call, for the model (spec §4.3). */
const MAX_ITEMS = 50;
/** Items per call to Lukitas: the API's batch limit. */
const BATCH_LIMIT = 20;
/** A re-sent `add_transactions` within this window saves nothing twice (spec §4.3). */
const IDEMPOTENCY_WINDOW_MS = 10 * 60 * 1000;

const DEFAULT_ICON = "🏷️";
const DEFAULT_COLOR = "#8e87b8";

/** JSON with object keys sorted and undefined fields left out: the same content, the same text. */
function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value !== null && typeof value === "object") {
    const fields = Object.entries(value)
      .filter(([, v]) => v !== undefined)
      .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
      .map(([k, v]) => `${JSON.stringify(k)}:${canonicalJson(v)}`);
    return `{${fields.join(",")}}`;
  }
  return JSON.stringify(value);
}

/**
 * The `Idempotency-Key` of one chunk of `add_transactions`: sha256 of the person, the chunk's
 * place, its content and the 10-minute window. Under 2026-07-28 a broken stream is re-sent as a
 * new request; the same content in the same window gets the same keys, so the API replays what
 * it saved instead of saving it again, chunk by chunk.
 */
export async function idempotencyKey(
  userId: string,
  chunkIndex: number,
  chunk: CreateTransaction[],
  now: Date,
): Promise<string> {
  const window = Math.floor(now.getTime() / IDEMPOTENCY_WINDOW_MS);
  const text = `${userId}|${chunkIndex}|${canonicalJson(chunk)}|${window}`;
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
}

const idsInput = z
  .array(z.uuid())
  .min(1)
  .max(MAX_ITEMS)
  .describe(`1 to ${MAX_ITEMS} transaction ids, from list_transactions`);

const nameInput = z.string().trim().min(1).max(120);
const noteInput = z.string().max(1000);

export const addTransactions = defineTool({
  name: "add_transactions",
  title: "Add transactions",
  description: `Saves 1 to ${MAX_ITEMS} transactions in one call (put everything the person dictated in a single call). Each needs a name, a positive amount in currency units and an existing category; the date defaults to today in the person's time zone. Re-sending the same call within 10 minutes saves nothing twice: the answer then says alreadySaved.`,
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  },
  input: z.object({
    items: z
      .array(
        z.object({
          name: nameInput.describe("Short name, e.g. Almuerzo"),
          amount: amountInput,
          kind: kindInput
            .optional()
            .describe(
              "expense or income; omit to take the category's kind. Must match the category's kind.",
            ),
          category: categoryInput,
          date: dateInput
            .optional()
            .describe("YYYY-MM-DD; omit for today in the person's time zone"),
          status: z
            .enum(["paid", "pending"])
            .default("paid")
            .describe("paid (default), or pending when it is still to be paid"),
          note: noteInput.optional(),
        }),
      )
      .min(1)
      .max(MAX_ITEMS),
  }),
  output: z.object({
    alreadySaved: z
      .boolean()
      .describe("True when this exact call had already been saved: nothing was saved again"),
    saved: z.number().int().describe("Transactions saved by this call"),
    items: z.array(transactionOutput),
  }),
  async handler(input, { lukitas, userId, now }) {
    const profile = await lukitas.profile();
    const categories = await lukitas.listCategories();
    const at = now();
    const date = today(profile, at);
    // Every category and amount is checked before the first write, so a bad item saves nothing.
    const items = input.items.map((item): CreateTransaction => {
      const category = findCategory(item.category, categories, { kind: item.kind });
      return {
        name: item.name,
        amount: toMinor(item.amount, category.kind),
        categoryId: category.id,
        date: item.date ?? date,
        status: item.status,
        note: item.note,
        source: "mcp",
      };
    });
    const results = [];
    for (const [index, chunk] of chunks(items, BATCH_LIMIT).entries()) {
      const key = await idempotencyKey(userId, index, chunk, at);
      results.push(await lukitas.addTransactions(chunk, key));
    }
    const names = byId(categories);
    const saved = results.filter((r) => !r.replayed).reduce((n, r) => n + r.items.length, 0);
    const out = results.flatMap((r) => r.items).map((t) => toTransactionOutput(t, names, profile));
    const alreadySaved = results.every((r) => r.replayed);
    const p = phrases(profile.locale);
    const head = alreadySaved
      ? p.alreadySaved(out.length)
      : saved === out.length
        ? p.saved(saved)
        : p.partlySaved(saved, out.length - saved);
    return {
      structured: { alreadySaved, saved, items: out },
      text: [head, ...out.map(transactionLine)].join("\n"),
    };
  },
});

function transactionLine(t: z.infer<typeof transactionOutput>): string {
  return `${t.date} ${quote(t.name)} ${t.kind === "expense" ? "-" : "+"}${t.formatted} ${quote(t.category)} [${t.id}]`;
}

export const updateTransaction = defineTool({
  name: "update_transaction",
  title: "Update a transaction",
  description:
    "Changes one transaction's name, amount, category, date or note, or marks it as paid. Get its id from list_transactions. The amount is positive; the sign always follows the category's kind.",
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  },
  input: z
    .object({
      id: z.uuid().describe("The transaction's id, from list_transactions"),
      name: nameInput.optional(),
      amount: amountInput.optional(),
      category: categoryInput.optional(),
      date: dateInput.optional(),
      status: z.enum(["paid", "pending"]).optional().describe("paid to mark it as paid"),
      note: noteInput.nullable().optional().describe("null clears the note"),
    })
    .refine(({ id: _id, ...fields }) => Object.values(fields).some((v) => v !== undefined), {
      message: "Provide at least one field to change",
    }),
  output: z.object({ transaction: transactionOutput }),
  async handler(input, { lukitas }) {
    const profile = await lukitas.profile();
    const categories = await lukitas.listCategories();
    const category = input.category ? findCategory(input.category, categories) : undefined;
    const patch: UpdateTransaction = {};
    if (input.name !== undefined) patch.name = input.name;
    if (input.date !== undefined) patch.date = input.date;
    if (input.status !== undefined) patch.status = input.status;
    if (input.note !== undefined) patch.note = input.note;
    if (category) patch.categoryId = category.id;
    // Without a new category its kind is not known before the write (Lukitas has no
    // get-by-id): guess expense, the common case, and fix the sign below if it is income.
    if (input.amount !== undefined)
      patch.amount = toMinor(input.amount, category?.kind ?? "expense");
    let tx = await lukitas.updateTransaction(input.id, patch);
    if (input.amount !== undefined || category) {
      const kind = byId(categories).get(tx.categoryId)?.kind;
      if (kind && (kind === "expense") !== tx.amount < 0) {
        tx = await lukitas.updateTransaction(input.id, { amount: -tx.amount });
      }
    }
    const transaction = toTransactionOutput(tx, byId(categories), profile);
    return {
      structured: { transaction },
      text: `${phrases(profile.locale).updated} ${transactionLine(transaction)}`,
    };
  },
});

export const deleteTransactions = defineTool({
  name: "delete_transactions",
  title: "Delete transactions",
  description: `Deletes 1 to ${MAX_ITEMS} transactions by id. Recoverable with restore_transactions. Confirm with the person before deleting more than 5.`,
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: true,
    idempotentHint: true,
    openWorldHint: false,
  },
  input: z.object({ ids: idsInput }),
  output: z.object({
    deleted: z.number().int(),
    ids: z.array(z.string()).describe("Pass them to restore_transactions to undo"),
  }),
  async handler(input, { lukitas }) {
    const profile = await lukitas.profile();
    for (const chunk of chunks(input.ids, BATCH_LIMIT)) await lukitas.deleteTransactions(chunk);
    return {
      structured: { deleted: input.ids.length, ids: input.ids },
      text: phrases(profile.locale).deleted(input.ids.length),
    };
  },
});

export const restoreTransactions = defineTool({
  name: "restore_transactions",
  title: "Restore transactions",
  description: "Undoes delete_transactions: brings the given transactions back.",
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  },
  input: z.object({ ids: idsInput }),
  output: z.object({ items: z.array(transactionOutput) }),
  async handler(input, { lukitas }) {
    const profile = await lukitas.profile();
    const categories = byId(await lukitas.listCategories());
    const items = [];
    for (const id of input.ids) {
      items.push(toTransactionOutput(await lukitas.restoreTransaction(id), categories, profile));
    }
    return {
      structured: { items },
      text: [phrases(profile.locale).restored(items.length), ...items.map(transactionLine)].join(
        "\n",
      ),
    };
  },
});

export const setBudget = defineTool({
  name: "set_budget",
  title: "Set a budget",
  description:
    "Sets an expense category's monthly budget from a month on (that month and the following ones, until changed). 0 means no spending planned. Confirm the amount with the person first.",
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  },
  input: z.object({
    category: categoryInput.describe("An expense category, by name or id"),
    amount: z.number().describe("The monthly budget in currency units, e.g. 400000 for 400 lukas"),
    effectiveFrom: monthInput
      .optional()
      .describe("First month it applies; defaults to the current month"),
  }),
  output: z.object({
    categoryId: z.string(),
    category: z.string().describe(DATA_NOTE),
    budget: moneyOutput,
    effectiveFrom: z.string(),
  }),
  async handler(input, { lukitas, now }) {
    const profile = await lukitas.profile();
    const category = findCategory(input.category, await lukitas.listCategories(), {
      kind: "expense",
    });
    const amount = Math.round(Math.abs(input.amount) * 100);
    if (!Number.isSafeInteger(amount))
      throw new ToolError("invalid_amount", "The amount is too large");
    const effectiveFrom = input.effectiveFrom ?? currentMonth(profile, now());
    await lukitas.setBudget(category.id, { amount, effectiveFrom });
    const budget = money(amount, profile);
    return {
      structured: { categoryId: category.id, category: category.name, budget, effectiveFrom },
      text: phrases(profile.locale).budgetSet({
        name: quote(category.name),
        amount: budget.formatted,
        from: effectiveFrom,
      }),
    };
  },
});

function nameTaken(name: string, categories: CategoryDto[], exceptId?: string) {
  const wanted = normalizeName(name);
  const clash = categories.find(
    (c) => !c.archived && c.id !== exceptId && normalizeName(c.name) === wanted,
  );
  if (clash) {
    throw new ToolError(
      "category_name_taken",
      `There is already a category named "${clash.name}"; use it instead of making another.`,
      { existing: { id: clash.id, name: clash.name } },
    );
  }
}

export const createCategory = defineTool({
  name: "create_category",
  title: "Create a category",
  description:
    "Creates an expense or income category. Only when the person asks for a new one: transactions never create categories. Refused when one with the same name (ignoring case and accents) exists.",
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: false,
    openWorldHint: false,
  },
  input: z.object({
    name: z.string().trim().min(1).max(40).describe("The name, in the person's language"),
    kind: kindInput,
    icon: z.string().min(1).max(40).optional().describe("One emoji, e.g. 🐶"),
  }),
  output: z.object({ category: categoryOutput }),
  async handler(input, { lukitas }) {
    const profile = await lukitas.profile();
    nameTaken(input.name, await lukitas.listCategories());
    const created = await lukitas.createCategory({
      name: input.name,
      kind: input.kind,
      icon: input.icon ?? DEFAULT_ICON,
      color: DEFAULT_COLOR,
    });
    return {
      structured: { category: toCategoryOutput(created, profile) },
      text: phrases(profile.locale).categoryCreated(quote(created.name)),
    };
  },
});

export const updateCategory = defineTool({
  name: "update_category",
  title: "Update a category",
  description:
    "Renames a category, changes its icon, archives it (it disappears from lists and its recurring transactions stop; its history stays) or brings an archived one back.",
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  },
  input: z
    .object({
      category: categoryInput.describe("The category to change, by its current name or id"),
      name: z.string().trim().min(1).max(40).optional().describe("The new name"),
      icon: z.string().min(1).max(40).optional().describe("One emoji"),
      archived: z.boolean().optional().describe("true archives it, false brings it back"),
    })
    .refine((v) => v.name !== undefined || v.icon !== undefined || v.archived !== undefined, {
      message: "Provide name, icon or archived",
    }),
  output: z.object({ category: categoryOutput }),
  async handler(input, { lukitas }) {
    const profile = await lukitas.profile();
    const categories = await lukitas.listCategories();
    const target = findCategory(input.category, categories, { archived: true });
    if (input.name !== undefined) nameTaken(input.name, categories, target.id);
    const updated = await lukitas.updateCategory(target.id, {
      name: input.name,
      icon: input.icon,
      archived: input.archived,
    });
    const p = phrases(profile.locale);
    const name = quote(updated.name);
    return {
      structured: { category: toCategoryOutput(updated, profile) },
      text: input.archived ? p.categoryArchived(name) : p.categoryUpdated(name),
    };
  },
});

const recurrenceOutput = z.object({
  id: z.string(),
  name: z.string().describe(DATA_NOTE),
  kind: z.enum(["expense", "income"]),
  amount: z.number().describe("Positive, in currency units"),
  formatted: z.string(),
  category: z.string().describe(DATA_NOTE),
  categoryId: z.string(),
  frequency: z.enum(["monthly", "yearly"]),
  dayOfMonth: z.number().int(),
  monthOfYear: z.number().int().nullable(),
  startDate: z.string(),
  endDate: z.string().nullable(),
});

function toRecurrenceOutput(
  r: RecurrenceDto,
  categories: Map<string, CategoryDto>,
  profile: Profile,
): z.infer<typeof recurrenceOutput> {
  return {
    id: r.id,
    name: r.name,
    kind: r.amount < 0 ? "expense" : "income",
    amount: fromMinor(r.amount),
    formatted: formatMoney(Math.abs(r.amount), profile.currency, profile.locale),
    category: categories.get(r.categoryId)?.name ?? "",
    categoryId: r.categoryId,
    frequency: r.frequency,
    dayOfMonth: r.dayOfMonth,
    monthOfYear: r.monthOfYear,
    startDate: r.startDate,
    endDate: r.endDate,
  };
}

function checked<T>(value: T): T {
  const result = createRecurrenceSchema.safeParse(value);
  if (!result.success) {
    throw invalid(result.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; "));
  }
  return value;
}

export const manageRecurring = defineTool({
  name: "manage_recurring",
  title: "Manage recurring transactions",
  description:
    "Creates, changes or stops a recurring payment or income (rent, a subscription, the salary). create needs name, amount and category (monthly by default, starting today, on that day of the month). update and stop need the id from list_recurring. stop ends it today: past transactions stay, no new ones come.",
  scope: "finance:write",
  annotations: {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: false,
    openWorldHint: false,
  },
  input: z.object({
    action: z.enum(["create", "update", "stop"]),
    id: z.uuid().optional().describe("For update and stop: the id from list_recurring"),
    name: nameInput.optional(),
    amount: amountInput.optional(),
    kind: kindInput.optional().describe("Omit to take the category's kind"),
    category: categoryInput.optional(),
    frequency: z.enum(["monthly", "yearly"]).optional().describe("monthly (default) or yearly"),
    dayOfMonth: z.number().int().min(1).max(31).optional().describe("Defaults to startDate's day"),
    monthOfYear: z
      .number()
      .int()
      .min(1)
      .max(12)
      .optional()
      .describe("For yearly ones; defaults to startDate's month"),
    startDate: dateInput.optional().describe("First occurrence; defaults to today"),
    endDate: dateInput.nullable().optional().describe("Last day it can occur; null for no end"),
  }),
  output: z.object({
    action: z.enum(["create", "update", "stop"]),
    recurrence: recurrenceOutput,
    removed: z.boolean().describe("True when stopping removed a rule that had not started yet"),
  }),
  async handler(input, { lukitas, now }) {
    const profile = await lukitas.profile();
    const categories = await lukitas.listCategories();
    const names = byId(categories);
    const p = phrases(profile.locale);
    const todayIs = today(profile, now());
    const answer = (r: RecurrenceDto, text: (name: string) => string, removed = false) => ({
      structured: {
        action: input.action,
        recurrence: toRecurrenceOutput(r, names, profile),
        removed,
      },
      text: text(quote(r.name)),
    });

    if (input.action === "create") {
      if (input.name === undefined || input.amount === undefined || !input.category) {
        throw invalid("create needs name, amount and category");
      }
      const category = findCategory(input.category, categories, { kind: input.kind });
      const startDate = input.startDate ?? todayIs;
      const frequency = input.frequency ?? "monthly";
      const created = await lukitas.createRecurrence(
        checked({
          name: input.name,
          amount: toMinor(input.amount, category.kind),
          categoryId: category.id,
          frequency,
          dayOfMonth: input.dayOfMonth ?? Number(startDate.slice(8, 10)),
          monthOfYear:
            frequency === "yearly" ? (input.monthOfYear ?? Number(startDate.slice(5, 7))) : null,
          startDate,
          endDate: input.endDate ?? null,
        }),
      );
      return answer(created, p.recurringCreated);
    }

    if (!input.id) throw invalid(`${input.action} needs the id from list_recurring`);
    const existing = (await lukitas.listRecurrences()).find((r) => r.id === input.id);
    if (!existing) throw new ToolError("not_found", "Recurring transaction not found");

    if (input.action === "stop") {
      if (existing.startDate > todayIs) {
        await lukitas.deleteRecurrence(existing.id);
        return answer(existing, p.recurringStopped, true);
      }
      if (existing.endDate !== null && existing.endDate <= todayIs) {
        return answer(existing, p.recurringStopped);
      }
      const stopped = await lukitas.updateRecurrence(existing.id, { endDate: todayIs });
      return answer(stopped, p.recurringStopped);
    }

    const category = input.category
      ? findCategory(input.category, categories, { kind: input.kind })
      : undefined;
    const kind = (category ?? names.get(existing.categoryId))?.kind ?? "expense";
    const patch: UpdateRecurrence = {};
    if (input.name !== undefined) patch.name = input.name;
    if (category) patch.categoryId = category.id;
    // A new category of the other kind flips the stored sign even when the amount stays.
    if (input.amount !== undefined || category) {
      patch.amount = toMinor(input.amount ?? fromMinor(existing.amount), kind);
    }
    if (input.frequency !== undefined) patch.frequency = input.frequency;
    if (input.dayOfMonth !== undefined) patch.dayOfMonth = input.dayOfMonth;
    if (input.monthOfYear !== undefined) patch.monthOfYear = input.monthOfYear;
    if (input.startDate !== undefined) patch.startDate = input.startDate;
    if (input.endDate !== undefined) patch.endDate = input.endDate;
    if (Object.keys(patch).length === 0) throw invalid("update needs at least one field to change");
    checked({ ...existing, ...patch });
    const updated = await lukitas.updateRecurrence(existing.id, patch);
    return answer(updated, p.recurringUpdated);
  },
});

/** The write tools, in the spec's order (§4.2). */
export const WRITE_TOOLS = [
  addTransactions,
  updateTransaction,
  deleteTransactions,
  restoreTransactions,
  setBudget,
  createCategory,
  updateCategory,
  manageRecurring,
] as const;
