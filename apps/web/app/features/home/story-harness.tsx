import {
  addMonths,
  lastDay,
  type MonthSummary,
  monthOf,
  monthSummary,
  type TransactionDto,
  todayIn,
} from "@lukas/core";
import { useState } from "react";
import { MemoryRouter, Route, Routes } from "react-router";
import { ApiProvider } from "../../api/ApiProvider.tsx";
import { ToastProvider } from "../../ui/Toast.tsx";
import { AppShell } from "./AppShell.tsx";
import { Home } from "./Home.tsx";
import { clearHomeStorage } from "./home-storage.ts";

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
}

function summaryOf(
  categories: FakeCategory[],
  transactions: TransactionDto[],
  month: string,
): MonthSummary {
  return monthSummary({
    month,
    categories: categories.filter((c) => !c.archived).map((c) => ({ id: c.id, kind: c.kind })),
    budgets: categories.flatMap((c) =>
      c.currentBudget === null
        ? []
        : [{ categoryId: c.id, amount: c.currentBudget, effectiveFrom: addMonths(month, -12) }],
    ),
    transactions: transactions.filter((t) => monthOf(t.date) === month),
  });
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function homeFetch({
  onRequest,
  currency = "EUR",
  data = "sample",
  failCreate = false,
  createDelayMs = 0,
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
      return Response.json(categories.filter((c) => !c.archived));
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
    if (path === "/api/v1/summary") {
      return Response.json(
        summaryOf(categories, transactions, url.searchParams.get("month") ?? MONTH),
      );
    }
    if (path === "/api/v1/transactions/suggestions") {
      const q = (url.searchParams.get("q") ?? "").toLowerCase();
      return Response.json({ items: SUGGESTIONS.filter((s) => s.name.includes(q)) });
    }
    if (path === "/api/v1/transactions" && request.method === "GET") {
      const month = url.searchParams.get("month");
      const items = transactions
        .filter((t) => !month || monthOf(t.date) === month)
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

export type HomeStageProps = HomeApiOptions;

/**
 * `/app` (the shell with its bottom bar and the add sheet, and home) in a memory router, against
 * the fake API above, with the toasts. Each story starts with no remembered choices; "Recargar"
 * remounts everything as a reload would, keeping what the browser stored.
 */
export function HomeStage(api: HomeStageProps) {
  const [fetchImpl] = useState(() => {
    clearHomeStorage(STORY_USER_ID);
    return homeFetch(api);
  });
  const [reloads, setReloads] = useState(0);
  return (
    <MemoryRouter initialEntries={["/app"]}>
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
            <Route
              path="/app"
              element={
                <AppShell>
                  <Home />
                </AppShell>
              }
            />
          </Routes>
        </ToastProvider>
      </ApiProvider>
    </MemoryRouter>
  );
}
