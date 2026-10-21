import { addMonths, monthOf, todayIn } from "@lukas/core";
import { useState } from "react";
import { MemoryRouter, Route, Routes } from "react-router";
import { ApiProvider } from "../../api/ApiProvider.tsx";
import { ToastProvider } from "../../ui/Toast.tsx";
import type { ImportDto } from "./import-state.ts";
import {
  clearOnboardingDraft,
  type OnboardingDraft,
  saveOnboardingDraft,
} from "./onboarding-draft.ts";
import { normalizeName, SUGGESTED_CATEGORIES } from "./suggested-categories.ts";
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
  /**
   * "none": a brand-new account; "some": Supermercado and Salario already there; "archived": every
   * suggestion there but archived (all of them deselected in an earlier visit).
   */
  categories?: "none" | "some" | "archived";
  /** The account already has transactions (its currency is locked). */
  hasTransactions?: boolean;
  timezone?: string;
  /** The file ended long ago: its window is its own last 3 months, not the last 3 complete ones. */
  oldExport?: boolean;
  /**
   * The Nth category POST (1-based) answers 503, once. `created`: the server made it anyway (the
   * answer was lost on the way back).
   */
  failCategoryPost?: { nth: number; created: boolean };
  /** Names the server says are taken (409) although no list shows them. */
  takenNames?: string[];
  /** How long a confirm takes, in ms. */
  confirmDelayMs?: number;
  /** Transactions per category name (the categories step counts them before a delete). */
  transactionsByName?: Record<string, number>;
}

function onboardingFetch({
  currency,
  onRequest,
  failRefreshesAfterConfirm = 0,
  categories: start = "some",
  timezone = "America/Bogota",
  oldExport = false,
  failCategoryPost,
  takenNames = [],
  confirmDelayMs = 0,
  hasTransactions = false,
  transactionsByName = {},
}: FakeApiOptions): typeof fetch {
  let categoryPosts = 0;
  let confirmed = false;
  const window = oldExport
    ? { from: "2025-01", to: "2025-03", months: 3 }
    : SAMPLE_PREVIEW.stats.averageWindow;
  let profile = {
    id: FAKE_USER_ID,
    email: "ana@example.com",
    timezone,
    locale: "es",
    onboardingCompletedAt: null as string | null,
    currency,
  };
  let categories: FakeCategory[] =
    start === "none"
      ? []
      : start === "archived"
        ? SUGGESTED_CATEGORIES.map((c, index) => ({
            id: `cat-${c.key}`,
            name: c.names.es,
            kind: c.kind,
            icon: c.glyph,
            color: c.tint,
            sortOrder: index,
            archived: true,
            currentBudget: null,
          }))
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
      categoryPosts += 1;
      const input = body as Omit<FakeCategory, "id" | "archived" | "currentBudget">;
      const taken = (name: string) => name.toLowerCase() === input.name.toLowerCase();
      // Like the API: names are unique among a person's active categories, ignoring case.
      if (categories.some((c) => !c.archived && taken(c.name)) || takenNames.some(taken)) {
        return Response.json({ code: "category_name_taken" }, { status: 409 });
      }
      const created = {
        ...input,
        id: `cat-${categories.length}`,
        archived: false,
        currentBudget: null,
      };
      if (failCategoryPost?.nth === categoryPosts) {
        if (failCategoryPost.created) categories = [...categories, created];
        return Response.json({ code: "internal_error" }, { status: 503 });
      }
      categories = [...categories, created];
      return Response.json(created, { status: 201 });
    }
    if (path === "/api/v1/transactions" && request.method === "GET") {
      const categoryId = url.searchParams.get("category");
      if (categoryId) {
        const name = categories.find((c) => c.id === categoryId)?.name ?? "";
        const count = transactionsByName[name] ?? 0;
        return Response.json({
          items: Array.from({ length: Math.min(count, 200) }, (_, i) => ({ id: `t-${i}` })),
          nextCursor: null,
        });
      }
      return Response.json({
        items: confirmed || hasTransactions ? [{ id: "t-1" }] : [],
        nextCursor: null,
      });
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
      if (confirmDelayMs) await new Promise((resolve) => setTimeout(resolve, confirmDelayMs));
      confirmed = true;
      // Like the importer: the file's categories that don't exist yet (by name, any case) are made,
      // as the file writes them ("supermercado" in lower case, "Salário" with its accent).
      for (const [name, kind, icon] of IMPORTED_CATEGORIES) {
        // The importer matches names without case or accents (and archived ones too).
        if (categories.some((c) => normalizeName(c.name) === normalizeName(name))) {
          continue;
        }
        categories = [
          ...categories,
          {
            id: `cat-${categories.length}`,
            name,
            kind,
            icon,
            color: "orange",
            sortOrder: 0,
            archived: false,
            currentBudget: null,
          },
        ];
      }
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

/** What the sample file's import makes, as the importer names it: [name, kind, icon]. */
const IMPORTED_CATEGORIES: [string, "expense" | "income", string][] = [
  ["supermercado", "expense", "cart"],
  ["Ocio", "expense", "star"],
  ["Taxes", "expense", "document"],
  ["Salário", "income", "salary"],
];

/** Who the fake API says is signed in. */
const FAKE_USER_ID = "u-new";

/** The browser this stage pretends to be: in Bogotá. */
const BOGOTA = { zone: "America/Bogota", supported: ["America/Bogota", "Europe/Madrid", "UTC"] };

/** Where the router starts (e.g. `/welcome/import`), and how the fake API behaves. */
export interface WelcomeStageProps extends FakeApiOptions {
  initialEntry: string;
  /** What this browser session already remembers (as after a reload mid-onboarding). */
  draft?: OnboardingDraft;
}

/** The `/welcome` flow in a memory router, with the fake API, toasts, and a stand-in for /app. */
export function WelcomeStage({ initialEntry, draft, ...api }: WelcomeStageProps) {
  const [fetchImpl] = useState(() => {
    // Each story starts a fresh session; "Recargar" below keeps it, as a real reload would.
    clearOnboardingDraft(FAKE_USER_ID);
    if (draft) saveOnboardingDraft(FAKE_USER_ID, draft);
    return onboardingFetch(api);
  });
  const [reloads, setReloads] = useState(0);
  return (
    <MemoryRouter initialEntries={[initialEntry]}>
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
