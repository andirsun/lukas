import { addMonths, monthOf, todayIn } from "@lukas/core";
import { useState } from "react";
import { MemoryRouter, Route, Routes } from "react-router";
import { ApiProvider } from "../../api/ApiProvider.tsx";
import { ToastProvider } from "../../ui/Toast.tsx";
import type { ImportDto } from "./import-state.ts";
import { Welcome } from "./Welcome.tsx";

/** The last 3 complete months, as the API would report them today. */
const lastComplete = addMonths(monthOf(todayIn("America/Bogota")), -1);
const RECENT_WINDOW = { from: addMonths(lastComplete, -2), to: lastComplete, months: 3 };

/** A preview like the sample Budge file's (invented data): 22 rows, one bad date. */
export const SAMPLE_PREVIEW: ImportDto = {
  id: "preview-sample",
  status: "preview",
  stats: {
    transactions: 22,
    duplicates: 3,
    newCategories: ["Salário", "Investimento", "Taxes", "Things"],
    rejected: [{ line: 19, reason: "invalid_date" }],
    from: "2026-09-01",
    to: "2026-10-30",
    averageMonthlySpending: [
      { category: "Ocio", amount: 6225 },
      { category: "Supermercado", amount: 3589 },
    ],
    currency: "EUR",
    averageWindow: RECENT_WINDOW,
  },
};

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

/**
 * A stand-in for the API's onboarding endpoints. The "file" is always the sample, in EUR: while the
 * account uses another currency, its preview rejects every row (as the real importer does).
 * Every write is reported to `onRequest` as `METHOD /path {json body}` (multipart without body).
 */
interface FakeApiOptions {
  currency: string;
  onRequest(line: string): void;
  failRefreshesAfterConfirm?: number;
  /** "none": a brand-new account; "some": Supermercado and Salario already there. */
  categories?: "none" | "some";
  timezone?: string;
  /** The file ended long ago: its window is its own last 3 months, not the last 3 complete ones. */
  oldExport?: boolean;
}

function onboardingFetch({
  currency,
  onRequest,
  failRefreshesAfterConfirm = 0,
  categories: start = "some",
  timezone = "America/Bogota",
  oldExport = false,
}: FakeApiOptions): typeof fetch {
  const window = oldExport
    ? { from: "2025-01", to: "2025-03", months: 3 }
    : SAMPLE_PREVIEW.stats.averageWindow;
  let profile = {
    id: "u-new",
    email: "ana@example.com",
    timezone,
    locale: "es",
    onboardingCompletedAt: null as string | null,
    currency,
  };
  let categories: FakeCategory[] =
    start === "none"
      ? []
      : [
          {
            id: "cat-groceries",
            name: "Supermercado",
            kind: "expense",
            icon: "🛒",
            color: "#ff9f1c",
            sortOrder: 0,
            archived: false,
            currentBudget: null,
          },
          {
            id: "cat-salary",
            name: "Salario",
            kind: "income",
            icon: "💰",
            color: "#2fd388",
            sortOrder: 7,
            archived: false,
            currentBudget: null,
          },
        ];
  let uploads = 0;
  let failuresLeft = 0;

  return async (input) => {
    const request = input instanceof Request ? input : new Request(input);
    const url = new URL(request.url);
    const path = url.pathname;
    const isJson = request.headers.get("content-type")?.includes("application/json");
    const body = isJson ? await request.json() : undefined;
    if (request.method !== "GET") {
      onRequest(`${request.method} ${path}${body === undefined ? "" : ` ${JSON.stringify(body)}`}`);
    }

    if (path === "/api/v1/me") {
      if (request.method === "PATCH") {
        const patch = body as { currency?: string; timezone?: string; onboardingCompleted?: true };
        if (patch.currency) profile = { ...profile, currency: patch.currency };
        if (patch.timezone) profile = { ...profile, timezone: patch.timezone };
        if (patch.onboardingCompleted) {
          profile = { ...profile, onboardingCompletedAt: "2026-10-21T10:00:00.000Z" };
        }
      }
      return Response.json(profile);
    }
    if (path === "/api/v1/categories" && request.method === "GET" && failuresLeft > 0) {
      failuresLeft -= 1;
      return Response.json({ code: "internal_error" }, { status: 503 });
    }
    if (path === "/api/v1/categories" && request.method === "GET") {
      const all = url.searchParams.get("includeArchived") === "true";
      return Response.json(categories.filter((c) => all || !c.archived));
    }
    if (path === "/api/v1/categories" && request.method === "POST") {
      const created = {
        ...(body as Omit<FakeCategory, "id" | "archived" | "currentBudget">),
        id: `cat-${categories.length}`,
        archived: false,
        currentBudget: null,
      };
      categories = [...categories, created];
      return Response.json(created, { status: 201 });
    }
    const budget = /^\/api\/v1\/categories\/([^/]+)\/budget$/.exec(path);
    if (budget) {
      const amount = (body as { amount: number }).amount;
      categories = categories.map((c) =>
        c.id === budget[1] ? { ...c, currentBudget: amount } : c,
      );
      return Response.json(categories.find((c) => c.id === budget[1]));
    }
    const category = /^\/api\/v1\/categories\/([^/]+)$/.exec(path);
    if (category && request.method === "PATCH") {
      categories = categories.map((c) =>
        c.id === category[1] ? { ...c, ...(body as Partial<FakeCategory>) } : c,
      );
      return Response.json(categories.find((c) => c.id === category[1]));
    }
    if (path === "/api/v1/imports" && request.method === "POST") {
      uploads += 1;
      const inCurrency = profile.currency === "EUR";
      const stats = inCurrency
        ? { ...SAMPLE_PREVIEW.stats, duplicates: 0, averageWindow: window }
        : {
            ...SAMPLE_PREVIEW.stats,
            transactions: 0,
            duplicates: 0,
            newCategories: [],
            rejected: [{ line: 7, reason: "currency_mismatch" }],
            from: null,
            to: null,
            averageMonthlySpending: [],
            averageWindow: null,
          };
      return Response.json({ id: `preview-${uploads}`, status: "preview", stats }, { status: 201 });
    }
    const confirm = /^\/api\/v1\/imports\/([^/]+)\/confirm$/.exec(path);
    if (confirm) {
      failuresLeft = failRefreshesAfterConfirm;
      return Response.json({
        id: confirm[1],
        status: "confirmed",
        stats: { ...SAMPLE_PREVIEW.stats, duplicates: 0, averageWindow: window, inserted: 22 },
      });
    }
    if (/^\/api\/v1\/imports\/[^/]+$/.test(path) && request.method === "DELETE") {
      return new Response(null, { status: 204 });
    }
    return new Response(null, { status: 404 });
  };
}

/** The browser this stage pretends to be: in Bogotá. */
const BOGOTA = { zone: "America/Bogota", supported: ["America/Bogota", "Europe/Madrid", "UTC"] };

export interface WelcomeStageProps {
  /** Where the router starts, e.g. `/welcome/import`. */
  initialEntry: string;
  /** The account's currency. */
  currency: string;
  onRequest(line: string): void;
  /** How many category reads fail (503) right after a confirm, retries included. */
  failRefreshesAfterConfirm?: number;
  /** What the account starts with: no categories (new) or a couple. */
  categories?: "none" | "some";
  /** The profile's stored time zone; "UTC" is a new profile's default. */
  timezone?: string;
  /** The uploaded file ended long ago (see `FakeApiOptions.oldExport`). */
  oldExport?: boolean;
}

/** The `/welcome` flow in a memory router, with the fake API, toasts, and a stand-in for /app. */
export function WelcomeStage({ initialEntry, ...api }: WelcomeStageProps) {
  const [fetchImpl] = useState(() => onboardingFetch(api));
  return (
    <MemoryRouter initialEntries={[initialEntry]}>
      <ApiProvider fetch={fetchImpl}>
        <ToastProvider>
          <Routes>
            <Route
              path="/welcome/:step?"
              element={<Welcome languages={["es-CO"]} timeZone={BOGOTA} />}
            />
            <Route path="/app" element={<p className="p-(--space-4) text-ink">App (stand-in)</p>} />
          </Routes>
        </ToastProvider>
      </ApiProvider>
    </MemoryRouter>
  );
}
