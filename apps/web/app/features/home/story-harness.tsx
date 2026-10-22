import {
  addMonths,
  lastDay,
  type MonthSummary,
  monthOf,
  monthSummary,
  type TransactionDto,
  todayIn,
} from "@lukas/core";
import { type ReactNode, useState } from "react";
import { MemoryRouter, Route, Routes } from "react-router";
import { ApiProvider } from "../../api/ApiProvider.tsx";
import { ToastProvider } from "../../ui/Toast.tsx";
import { CategoriesPage } from "../categories/CategoriesPage.tsx";
import { CategoryDetail } from "../categories/CategoryDetail.tsx";
import { RecurringPage } from "../recurring/RecurringPage.tsx";
import { AppShell } from "./AppShell.tsx";
import { Home } from "./Home.tsx";
import { clearHomeStorage } from "./home-storage.ts";
import type { SignOutRequest } from "./use-sign-out.ts";

/** The time zone of the made-up person: "today" and the month are theirs. */
export const STORY_TIMEZONE = "Europe/Madrid";
export const STORY_TODAY = todayIn(STORY_TIMEZONE);
const MONTH = monthOf(STORY_TODAY);
/** Who the fake API says is signed in. */
export const STORY_USER_ID = "u-ana";

interface FakeCategory {
  id: string;
  name: string;
  kind: "expense" | "income";
  icon: string;
  color: string;
  sortOrder: number;
  archived: boolean;
  currentBudget: number | null;
}

const category = (
  id: string,
  name: string,
  icon: string,
  color: string,
  sortOrder: number,
  currentBudget: number | null,
  kind: "expense" | "income" = "expense",
): FakeCategory => ({ id, name, kind, icon, color, sortOrder, archived: false, currentBudget });

const CATEGORIES: FakeCategory[] = [
  category("cat-groceries", "Supermercado", "🛒", "#ff9f1c", 0, 18000),
  category("cat-restaurant", "Restaurante", "🍽️", "#ff5c7a", 1, 30000),
  category("cat-fun", "Ocio", "⭐", "#a66bff", 2, 65000),
  category("cat-transport", "Transporte", "🚗", "#3fa7ff", 3, 9000),
  category("cat-salary", "Salario", "💰", "#2fd388", 7, null, "income"),
];

const PESO_CATEGORIES: FakeCategory[] = [
  category("cat-food", "Comida", "🍽️", "#ff5c7a", 0, 80000000),
  category("cat-home", "Casa", "🏠", "#3fa7ff", 1, 150000000),
  category("cat-salary", "Salario", "💰", "#2fd388", 7, null, "income"),
];

/** A day of this month `days` from today, kept inside the month. */
function dayFromToday(days: number): string {
  const [year, month, day] = STORY_TODAY.split("-").map(Number) as [number, number, number];
  const date = new Date(Date.UTC(year, month - 1, day + days)).toISOString().slice(0, 10);
  if (date > lastDay(MONTH)) return lastDay(MONTH);
  if (date < `${MONTH}-01`) return `${MONTH}-01`;
  return date;
}

let ids = 0;
function transaction(
  name: string,
  categoryId: string,
  amount: number,
  date: string,
  status: "paid" | "pending" = "paid",
  currency = "EUR",
): TransactionDto {
  ids += 1;
  return {
    id: `00000000-0000-4000-8000-${String(ids).padStart(12, "0")}`,
    name,
    amount,
    currency,
    date,
    status,
    note: null,
    categoryId,
    recurrenceId: null,
    importId: null,
    source: "web",
    createdAt: `${date}T09:00:00.000Z`,
    updatedAt: `${date}T09:00:00.000Z`,
  };
}

/**
 * This month, invented: groceries over budget (194,12 of 180 €), the restaurant near its limit,
 * a pending subscription a couple of days ahead, and the salary. 501,13 € left of 1.220 €.
 */
function sampleTransactions(): TransactionDto[] {
  const first = `${MONTH}-01`;
  return [
    transaction("desayuno", "cat-restaurant", -475, STORY_TODAY),
    transaction("pingo doce", "cat-groceries", -19412, first),
    transaction("cena", "cat-restaurant", -25367, first),
    transaction("cine", "cat-fun", -26280, first),
    transaction("Salario", "cat-salary", 250000, first),
    transaction("Spotify", "cat-fun", -353, dayFromToday(2), "pending"),
  ];
}

interface FakeRecurrence {
  id: string;
  name: string;
  amount: number;
  categoryId: string;
  frequency: "monthly" | "yearly";
  dayOfMonth: number;
  monthOfYear: number | null;
  startDate: string;
  endDate: string | null;
}

/**
 * Fixed costs: Spotify (the pending one above) and a film club in Ocio, the salary, and a yearly
 * car insurance in Transporte.
 */
function sampleRecurrences(): FakeRecurrence[] {
  const spotifyDay = Number(dayFromToday(2).slice(8, 10));
  return [
    {
      id: "rec-spotify",
      name: "Spotify",
      amount: -353,
      categoryId: "cat-fun",
      frequency: "monthly",
      dayOfMonth: spotifyDay,
      monthOfYear: null,
      startDate: "2026-01-01",
      endDate: null,
    },
    {
      id: "rec-cineclub",
      name: "Cine club",
      amount: -1500,
      categoryId: "cat-fun",
      frequency: "monthly",
      dayOfMonth: 12,
      monthOfYear: null,
      startDate: "2026-01-01",
      endDate: null,
    },
    {
      id: "rec-salary",
      name: "Salario",
      amount: 250000,
      categoryId: "cat-salary",
      frequency: "monthly",
      dayOfMonth: 1,
      monthOfYear: null,
      startDate: "2026-01-01",
      endDate: null,
    },
    {
      id: "rec-insurance",
      name: "Seguro del carro",
      amount: -42000,
      categoryId: "cat-transport",
      frequency: "yearly",
      dayOfMonth: 15,
      monthOfYear: 3,
      startDate: "2025-03-01",
      endDate: null,
    },
  ];
}

const SUGGESTIONS = [
  { name: "continente", categoryId: "cat-groceries" },
  { name: "pingo doce", categoryId: "cat-groceries" },
  { name: "desayuno", categoryId: "cat-restaurant" },
  { name: "cine", categoryId: "cat-fun" },
];

export interface HomeApiOptions {
  /** Every write, as `METHOD /path {json body}`, with its headers. */
  onRequest(line: string, headers: Record<string, string>): void;
  currency?: "EUR" | "COP";
  /** "sample": this month as above; "empty": categories without budgets and no transactions. */
  data?: "sample" | "empty" | "no-categories";
  /** Creating a transaction answers 503 (after `createDelayMs`). */
  failCreate?: boolean;
  /** How long a create takes, in ms. */
  createDelayMs?: number;
  /** Transporte is archived, with a taxi ride in it today (sample data only). */
  archivedCategory?: boolean;
  /** No recurrences (the sample has Spotify, the salary and a yearly insurance). */
  noRecurrences?: boolean;
}

/** One budget amount, from its month on (until a later one), as the API keeps them. */
interface FakeBudget {
  categoryId: string;
  amount: number;
  effectiveFrom: string;
}

/** The budget in force in `month`: the latest one starting on or before it. */
function budgetIn(budgets: FakeBudget[], categoryId: string, month: string): number | null {
  const found = budgets
    .filter((b) => b.categoryId === categoryId && b.effectiveFrom <= month)
    .sort((a, b) => (a.effectiveFrom < b.effectiveFrom ? 1 : -1))[0];
  return found ? found.amount : null;
}

function summaryOf(
  categories: FakeCategory[],
  budgets: FakeBudget[],
  transactions: TransactionDto[],
  month: string,
): MonthSummary {
  const inMonth = transactions.filter((t) => monthOf(t.date) === month);
  // Like the API: an archived category stays while it has spending that month.
  const used = new Set(inMonth.map((t) => t.categoryId));
  return monthSummary({
    month,
    categories: categories
      .filter((c) => !c.archived || used.has(c.id))
      .map((c) => ({ id: c.id, kind: c.kind })),
    budgets: categories.flatMap((c) => {
      const amount = budgetIn(budgets, c.id, month);
      return amount === null ? [] : [{ categoryId: c.id, amount, effectiveFrom: month }];
    }),
    transactions: inMonth,
  });
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function homeFetch({
  onRequest,
  currency = "EUR",
  data = "sample",
  failCreate = false,
  createDelayMs = 0,
  archivedCategory = false,
  noRecurrences = false,
}: HomeApiOptions): typeof fetch {
  let categories: FakeCategory[] =
    data === "no-categories"
      ? []
      : currency === "COP"
        ? structuredClone(PESO_CATEGORIES)
        : structuredClone(CATEGORIES);
  if (data === "empty") categories = categories.map((c) => ({ ...c, currentBudget: null }));
  let transactions: TransactionDto[] =
    data === "sample" && currency === "EUR" ? sampleTransactions() : [];
  if (archivedCategory) {
    categories = categories.map((c) =>
      c.id === "cat-transport" ? { ...c, archived: true, currentBudget: null } : c,
    );
    transactions = [...transactions, transaction("taxi", "cat-transport", -1500, STORY_TODAY)];
  }
  let budgets: FakeBudget[] = categories.flatMap((c) =>
    c.currentBudget === null
      ? []
      : [{ categoryId: c.id, amount: c.currentBudget, effectiveFrom: addMonths(MONTH, -12) }],
  );
  const withBudget = (c: FakeCategory): FakeCategory => ({
    ...c,
    currentBudget: budgetIn(budgets, c.id, MONTH),
  });
  let recurrences: FakeRecurrence[] =
    data === "sample" && currency === "EUR" && !noRecurrences ? sampleRecurrences() : [];
  let recurrenceIds = 0;
  const deleted = new Map<string, TransactionDto>();
  const profile = {
    id: STORY_USER_ID,
    email: "ana@example.com",
    timezone: STORY_TIMEZONE,
    locale: "es",
    onboardingCompletedAt: "2026-10-01T10:00:00.000Z",
    currency,
  };
  const newestFirst = (a: TransactionDto, b: TransactionDto) =>
    a.date === b.date ? (a.id < b.id ? 1 : -1) : a.date < b.date ? 1 : -1;

  return async (input) => {
    const request = input instanceof Request ? input : new Request(input);
    const url = new URL(request.url);
    const path = url.pathname;
    const isJson = request.headers.get("content-type")?.includes("application/json");
    const body = isJson ? await request.json() : undefined;
    if (request.method !== "GET") {
      onRequest(
        `${request.method} ${path}${body === undefined ? "" : ` ${JSON.stringify(body)}`}`,
        Object.fromEntries(request.headers.entries()),
      );
    }

    if (path === "/api/v1/me") return Response.json(profile);
    if (path === "/api/v1/categories" && request.method === "GET") {
      const all = url.searchParams.get("includeArchived") === "true";
      return Response.json(categories.filter((c) => all || !c.archived).map(withBudget));
    }
    if (path === "/api/v1/categories" && request.method === "POST") {
      const created = {
        ...(body as Omit<FakeCategory, "id" | "archived" | "currentBudget">),
        id: `cat-new-${categories.length}`,
        archived: false,
        currentBudget: null,
      } as FakeCategory;
      categories = [...categories, created];
      return Response.json(created, { status: 201 });
    }
    const categoryBudget = /^\/api\/v1\/categories\/([^/]+)\/budget$/.exec(path);
    if (categoryBudget && request.method === "PUT") {
      const id = categoryBudget[1] as string;
      const { amount, effectiveFrom } = body as { amount: number; effectiveFrom: string };
      if (!Number.isInteger(amount) || amount < 0) {
        return Response.json({ code: "validation_failed" }, { status: 422 });
      }
      budgets = [
        ...budgets.filter((b) => !(b.categoryId === id && b.effectiveFrom === effectiveFrom)),
        { categoryId: id, amount, effectiveFrom },
      ];
      return Response.json(withBudget(categories.find((c) => c.id === id) as FakeCategory));
    }
    const oneCategory = /^\/api\/v1\/categories\/([^/]+)$/.exec(path);
    if (oneCategory && request.method === "PATCH") {
      const id = oneCategory[1] as string;
      const patch = body as Partial<FakeCategory> & { archived?: boolean };
      const existing = categories.find((c) => c.id === id);
      if (!existing) return Response.json({ code: "not_found" }, { status: 404 });
      if (
        patch.kind &&
        patch.kind !== existing.kind &&
        transactions.some((t) => t.categoryId === id)
      ) {
        return Response.json({ code: "category_has_transactions" }, { status: 409 });
      }
      if (
        patch.name &&
        categories.some((c) => c.id !== id && c.name.toLowerCase() === patch.name?.toLowerCase())
      ) {
        return Response.json({ code: "category_name_taken" }, { status: 409 });
      }
      categories = categories.map((c) => (c.id === id ? { ...c, ...patch } : c));
      // Like the API: archiving ends the category's active recurrences today.
      if (patch.archived && !existing.archived) {
        recurrences = recurrences.map((r) =>
          r.categoryId === id && (r.endDate === null || r.endDate >= STORY_TODAY)
            ? { ...r, endDate: STORY_TODAY }
            : r,
        );
      }
      return Response.json(withBudget(categories.find((c) => c.id === id) as FakeCategory));
    }
    if (path === "/api/v1/recurrences" && request.method === "GET") {
      return Response.json(recurrences);
    }
    if (path === "/api/v1/recurrences" && request.method === "POST") {
      const input = body as Omit<FakeRecurrence, "id">;
      if (input.frequency === "yearly" && input.monthOfYear == null) {
        return Response.json({ code: "validation_failed" }, { status: 422 });
      }
      recurrenceIds += 1;
      const created: FakeRecurrence = {
        ...input,
        id: `rec-new-${recurrenceIds}`,
        monthOfYear: input.monthOfYear ?? null,
        endDate: input.endDate ?? null,
      };
      recurrences = [...recurrences, created];
      return Response.json(created, { status: 201 });
    }
    const oneRecurrence = /^\/api\/v1\/recurrences\/([^/]+)$/.exec(path);
    if (oneRecurrence && request.method === "PATCH") {
      const id = oneRecurrence[1] as string;
      recurrences = recurrences.map((r) =>
        r.id === id ? { ...r, ...(body as Partial<FakeRecurrence>) } : r,
      );
      return Response.json(recurrences.find((r) => r.id === id));
    }
    if (oneRecurrence && request.method === "DELETE") {
      recurrences = recurrences.filter((r) => r.id !== oneRecurrence[1]);
      return new Response(null, { status: 204 });
    }
    if (path === "/api/v1/summary") {
      return Response.json(
        summaryOf(categories, budgets, transactions, url.searchParams.get("month") ?? MONTH),
      );
    }
    if (path === "/api/v1/transactions/suggestions") {
      const q = (url.searchParams.get("q") ?? "").toLowerCase();
      return Response.json({ items: SUGGESTIONS.filter((s) => s.name.includes(q)) });
    }
    if (path === "/api/v1/transactions" && request.method === "GET") {
      const month = url.searchParams.get("month");
      const category = url.searchParams.get("category");
      const items = transactions
        .filter((t) => !month || monthOf(t.date) === month)
        .filter((t) => !category || t.categoryId === category)
        .sort(newestFirst)
        .slice(0, Number(url.searchParams.get("limit") ?? 50));
      return Response.json({ items, nextCursor: null });
    }
    if (path === "/api/v1/transactions" && request.method === "POST") {
      if (createDelayMs) await sleep(createDelayMs);
      if (failCreate) return Response.json({ code: "internal_error" }, { status: 503 });
      const input = body as Pick<
        TransactionDto,
        "name" | "amount" | "categoryId" | "date" | "status" | "note"
      >;
      const created = {
        ...transaction(input.name, input.categoryId, input.amount, input.date, input.status),
        note: input.note ?? null,
        currency,
      };
      transactions = [...transactions, created];
      return Response.json(created, { status: 201 });
    }
    const restore = /^\/api\/v1\/transactions\/([^/]+)\/restore$/.exec(path);
    if (restore) {
      const back = deleted.get(restore[1] as string);
      if (!back) return Response.json({ code: "not_found" }, { status: 404 });
      transactions = [...transactions, back];
      return Response.json(back);
    }
    const one = /^\/api\/v1\/transactions\/([^/]+)$/.exec(path);
    if (one && request.method === "PATCH") {
      transactions = transactions.map((t) =>
        t.id === one[1] ? { ...t, ...(body as Partial<TransactionDto>) } : t,
      );
      return Response.json(transactions.find((t) => t.id === one[1]));
    }
    if (one && request.method === "DELETE") {
      const gone = transactions.find((t) => t.id === one[1]);
      if (gone) deleted.set(gone.id, gone);
      transactions = transactions.filter((t) => t.id !== one[1]);
      return new Response(null, { status: 204 });
    }
    return new Response(null, { status: 404 });
  };
}

export interface HomeStageProps extends HomeApiOptions {
  /** Stands in for Better Auth's sign-out; by default it succeeds. */
  signOut?: SignOutRequest;
  /** Where the story starts (`/app` by default): any screen of the signed-in app. */
  path?: string;
}

/**
 * The signed-in app (the shell with its bottom bar or sidebar and the add sheet; home, the
 * categories, a category's detail and the recurring ones) in a memory router, against the fake
 * API above, with the toasts. Each story starts with no remembered choices; "Recargar" remounts
 * everything as a reload would, keeping what the browser stored.
 */
export function HomeStage({
  signOut = async () => ({ error: null }),
  path = "/app",
  ...api
}: HomeStageProps) {
  const [fetchImpl] = useState(() => {
    clearHomeStorage(STORY_USER_ID);
    return homeFetch(api);
  });
  const [reloads, setReloads] = useState(0);
  const shell = (screen: ReactNode) => <AppShell>{screen}</AppShell>;
  return (
    <MemoryRouter initialEntries={[path]}>
      <button
        type="button"
        className="sr-only focus:not-sr-only"
        onClick={() => setReloads((n) => n + 1)}
      >
        Recargar (stand-in)
      </button>
      <ApiProvider key={reloads} fetch={fetchImpl}>
        <ToastProvider>
          <Routes>
            <Route path="/app" element={shell(<Home signOut={signOut} />)} />
            <Route path="/app/categories" element={shell(<CategoriesPage />)} />
            <Route path="/app/categories/:id" element={shell(<CategoryDetail />)} />
            <Route path="/app/recurring" element={shell(<RecurringPage />)} />
            <Route
              path="/sign-in"
              element={<p className="p-(--space-4) text-ink">Sign-in (stand-in)</p>}
            />
          </Routes>
        </ToastProvider>
      </ApiProvider>
    </MemoryRouter>
  );
}
