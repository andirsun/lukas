import { addMonths } from "@lukas/core";
import { z } from "zod";
import { phrases, quote } from "../text.ts";
import { defineTool, READ_ONLY } from "../tool.ts";
import {
  byId,
  categoryInput,
  categoryOutput,
  checkRange,
  currentMonth,
  DATA_NOTE,
  dateInput,
  findCategory,
  invalid,
  money,
  moneyOutput,
  monthInput,
  toCategoryOutput,
  toTransactionOutput,
  transactionOutput,
} from "./shared.ts";

/** A list page: the API's limit is 200; the model gets at most 100 to keep answers small. */
const PAGE_LIMIT = 100;

export const getMonthOverview = defineTool({
  name: "get_month_overview",
  title: "Month overview",
  description:
    "How a month is going: income, expenses, the total budget, what is left, the balance, and each budget's spending and state (ok, near the limit, over). Use it for '¿cómo voy?' and month reviews. Defaults to the current month in the person's time zone.",
  scope: "finance:read",
  annotations: READ_ONLY,
  input: z.object({
    month: monthInput.optional().describe("The month as YYYY-MM; omit for the current month"),
  }),
  output: z.object({
    month: z.string(),
    currency: z.string(),
    income: moneyOutput,
    spent: moneyOutput.describe("Expenses of the month, positive"),
    budgetTotal: moneyOutput,
    remaining: moneyOutput.describe("Budget minus expenses; negative when over"),
    balance: moneyOutput.describe("Income minus expenses"),
    budgets: z.array(
      z.object({
        categoryId: z.string(),
        category: z.string().describe(DATA_NOTE),
        budget: moneyOutput.nullable(),
        spent: moneyOutput,
        remaining: moneyOutput.nullable(),
        state: z.enum(["ok", "near", "over"]),
      }),
    ),
  }),
  async handler(input, { lukitas, now }) {
    const profile = await lukitas.profile();
    const month = input.month ?? currentMonth(profile, now());
    const [summary, categories] = await Promise.all([
      lukitas.monthSummary(month),
      lukitas.listCategories(),
    ]);
    const names = byId(categories);
    const budgets = summary.categories
      .filter((c) => c.budget !== null || c.spent !== 0)
      .map((c) => ({
        categoryId: c.categoryId,
        category: names.get(c.categoryId)?.name ?? "",
        budget: c.budget === null ? null : money(c.budget, profile),
        spent: money(c.spent, profile),
        remaining: c.remaining === null ? null : money(c.remaining, profile),
        state: c.state,
      }));
    const p = phrases(profile.locale);
    const lines = [
      p.overview({
        month,
        income: money(summary.income, profile).formatted,
        spent: money(summary.spent, profile).formatted,
        budget: money(summary.budgetTotal, profile).formatted,
        remaining: money(summary.remaining, profile).formatted,
      }),
      ...budgets
        .filter((b) => b.budget !== null)
        .map((b) =>
          p.budgetLine({
            name: quote(b.category),
            spent: b.spent.formatted,
            budget: b.budget?.formatted ?? "",
            state: b.state,
          }),
        ),
    ];
    return {
      structured: {
        month,
        currency: profile.currency,
        income: money(summary.income, profile),
        spent: money(summary.spent, profile),
        budgetTotal: money(summary.budgetTotal, profile),
        remaining: money(summary.remaining, profile),
        balance: money(summary.balance, profile),
        budgets,
      },
      text: lines.join("\n"),
    };
  },
});

export const listTransactions = defineTool({
  name: "list_transactions",
  title: "List transactions",
  description: `Transactions (movements), newest first, for a month or a date range, optionally filtered by category, text or status. Defaults to the current month when neither month nor from/to is given. Pages hold up to ${PAGE_LIMIT}; pass nextCursor back to get the next page. Use it to find the id of a transaction before changing or deleting it.`,
  scope: "finance:read",
  annotations: READ_ONLY,
  input: z.object({
    month: monthInput.optional(),
    from: dateInput.optional().describe("First day included, YYYY-MM-DD"),
    to: dateInput.optional().describe("Last day included, YYYY-MM-DD"),
    category: categoryInput.optional(),
    text: z
      .string()
      .trim()
      .min(1)
      .max(100)
      .optional()
      .describe("Matches the name or the note, ignoring case and accents"),
    status: z
      .enum(["paid", "pending"])
      .optional()
      .describe("pending: expected but not paid yet (e.g. upcoming recurring bills)"),
    cursor: z.string().optional().describe("nextCursor from the previous page"),
    limit: z.number().int().min(1).max(PAGE_LIMIT).default(50),
  }),
  output: z.object({
    items: z.array(transactionOutput),
    nextCursor: z
      .string()
      .nullable()
      .describe("Pass it as cursor for the next page; null at the end"),
  }),
  async handler(input, { lukitas, now }) {
    const profile = await lukitas.profile();
    if (input.from && input.to && input.from > input.to) throw invalid("from must not be after to");
    const categories = await lukitas.listCategories();
    const ranged = input.month !== undefined || input.from !== undefined || input.to !== undefined;
    const page = await lukitas.listTransactions({
      month: ranged ? input.month : currentMonth(profile, now()),
      from: input.from,
      to: input.to,
      categoryId: input.category
        ? findCategory(input.category, categories, { archived: true }).id
        : undefined,
      status: input.status,
      q: input.text,
      cursor: input.cursor,
      limit: input.limit,
    });
    const names = byId(categories);
    const items = page.items.map((tx) => toTransactionOutput(tx, names, profile));
    const p = phrases(profile.locale);
    const lines = [
      p.transactions(items.length, page.nextCursor !== null),
      ...items.map(
        (t) =>
          `${t.date} ${quote(t.name)} ${t.kind === "expense" ? "-" : "+"}${t.formatted} ${quote(t.category)}${t.status === "pending" ? ` (${p.pending})` : ""} [${t.id}]`,
      ),
    ];
    return { structured: { items, nextCursor: page.nextCursor }, text: lines.join("\n") };
  },
});

export const spendingByCategory = defineTool({
  name: "spending_by_category",
  title: "Spending by category",
  description:
    "How much went to each category over a range of months, largest first, with each one's share of the total. Defaults to the current month. With kind income, how much came in per category. To see what grew, compare two calls (e.g. this month and the previous one).",
  scope: "finance:read",
  annotations: READ_ONLY,
  input: z.object({
    from: monthInput.optional().describe("First month included; defaults to the current month"),
    to: monthInput.optional().describe("Last month included; defaults to from"),
    kind: z.enum(["expense", "income"]).default("expense"),
  }),
  output: z.object({
    from: z.string(),
    to: z.string(),
    kind: z.enum(["expense", "income"]),
    total: moneyOutput,
    items: z.array(
      z.object({
        categoryId: z.string(),
        category: z.string().describe(DATA_NOTE),
        total: moneyOutput,
        share: z.number().describe("Share of the total, 0 to 1"),
      }),
    ),
  }),
  async handler(input, { lukitas, now }) {
    const profile = await lukitas.profile();
    const from = input.from ?? input.to ?? currentMonth(profile, now());
    const to = input.to ?? from;
    checkRange(from, to);
    const [report, categories] = await Promise.all([
      lukitas.categoryReport({ from, to, kind: input.kind }),
      lukitas.listCategories(),
    ]);
    const names = byId(categories);
    const items = report.items.map((i) => ({
      categoryId: i.categoryId,
      category: names.get(i.categoryId)?.name ?? "",
      total: money(i.total, profile),
      share: report.total === 0 ? 0 : Math.round((i.total / report.total) * 10_000) / 10_000,
    }));
    const total = money(report.total, profile);
    const p = phrases(profile.locale);
    const lines = [
      p.byCategory({ from, to, total: total.formatted, income: input.kind === "income" }),
      ...items.map(
        (i) => `${quote(i.category)}: ${i.total.formatted} (${Math.round(i.share * 100)}%)`,
      ),
    ];
    return {
      structured: { from, to, kind: input.kind, total, items },
      text: lines.join("\n"),
    };
  },
});

export const spendingTrend = defineTool({
  name: "spending_trend",
  title: "Spending trend",
  description:
    "Income, expenses and the total budget month by month. Defaults to the last 6 months, the current one included. At most 36 months.",
  scope: "finance:read",
  annotations: READ_ONLY,
  input: z.object({
    from: monthInput.optional().describe("First month; defaults to 5 months before to"),
    to: monthInput.optional().describe("Last month; defaults to the current month"),
  }),
  output: z.object({
    months: z.array(
      z.object({
        month: z.string(),
        income: moneyOutput,
        expenses: moneyOutput,
        budget: moneyOutput,
      }),
    ),
  }),
  async handler(input, { lukitas, now }) {
    const profile = await lukitas.profile();
    const to = input.to ?? currentMonth(profile, now());
    const from = input.from ?? addMonths(to, -5);
    checkRange(from, to);
    const { months } = await lukitas.trend({ from, to });
    const rows = months.map((m) => ({
      month: m.month,
      income: money(m.income, profile),
      expenses: money(m.expenses, profile),
      budget: money(m.budget, profile),
    }));
    const p = phrases(profile.locale);
    return {
      structured: { months: rows },
      text: rows
        .map((m) =>
          p.trend({ month: m.month, income: m.income.formatted, expenses: m.expenses.formatted }),
        )
        .join("\n"),
    };
  },
});

export const listCategories = defineTool({
  name: "list_categories",
  title: "List categories",
  description:
    "The person's categories with their id, kind (expense or income), this month's budget and whether they are archived. Read it before writing transactions, to pick an existing category; archived ones cannot take new transactions.",
  scope: "finance:read",
  annotations: READ_ONLY,
  input: z.object({}),
  output: z.object({ items: z.array(categoryOutput) }),
  async handler(_input, { lukitas }) {
    const profile = await lukitas.profile();
    const items = (await lukitas.listCategories()).map((c) => toCategoryOutput(c, profile));
    const p = phrases(profile.locale);
    const lines = [
      p.categories(items.length),
      ...items.map((c) =>
        [
          `${quote(c.name)} (${c.kind})`,
          c.budget ? p.budget(c.budget.formatted) : null,
          c.archived ? p.archived : null,
          `[${c.id}]`,
        ]
          .filter(Boolean)
          .join(", "),
      ),
    ];
    return { structured: { items }, text: lines.join("\n") };
  },
});

export const listRecurring = defineTool({
  name: "list_recurring",
  title: "List recurring transactions",
  description:
    "Recurring payments and income (rent, subscriptions, salary): amount, category, how often, the day, and when they start and end. Each one creates a pending transaction in its month.",
  scope: "finance:read",
  annotations: READ_ONLY,
  input: z.object({}),
  output: z.object({
    items: z.array(
      z.object({
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
      }),
    ),
  }),
  async handler(_input, { lukitas }) {
    const profile = await lukitas.profile();
    const [recurrences, categories] = await Promise.all([
      lukitas.listRecurrences(),
      lukitas.listCategories(),
    ]);
    const names = byId(categories);
    const items = recurrences.map((r) => {
      const amount = money(Math.abs(r.amount), profile);
      return {
        id: r.id,
        name: r.name,
        kind: r.amount < 0 ? ("expense" as const) : ("income" as const),
        amount: amount.amount,
        formatted: amount.formatted,
        category: names.get(r.categoryId)?.name ?? "",
        categoryId: r.categoryId,
        frequency: r.frequency,
        dayOfMonth: r.dayOfMonth,
        monthOfYear: r.monthOfYear,
        startDate: r.startDate,
        endDate: r.endDate,
      };
    });
    const p = phrases(profile.locale);
    const lines = [
      p.recurring(items.length),
      ...items.map(
        (r) =>
          `${quote(r.name)} ${r.formatted} ${quote(r.category)}, ${
            r.frequency === "monthly"
              ? p.monthly(r.dayOfMonth)
              : p.yearly(r.dayOfMonth, r.monthOfYear ?? 1)
          }${r.endDate ? ` → ${r.endDate}` : ""} [${r.id}]`,
      ),
    ];
    return { structured: { items }, text: lines.join("\n") };
  },
});

/** The read tools, in the spec's order (§4.1). */
export const READ_TOOLS = [
  getMonthOverview,
  listTransactions,
  spendingByCategory,
  spendingTrend,
  listCategories,
  listRecurring,
] as const;
