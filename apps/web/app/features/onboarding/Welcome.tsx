import { addMonths, monthOf, type SupportedCurrency, todayIn } from "@lukas/core";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";
import { Navigate, useNavigate, useParams } from "react-router";
import { useTranslations } from "use-intl";
import { useApi } from "../../api/ApiProvider.tsx";
import type { ApiClient } from "../../api/client.ts";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { queryKeys, useCategories, useMe } from "../../api/queries.ts";
import type { paths } from "../../api/schema";
import { feedback } from "../../feedback/feedback.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import type { NewCategory } from "./AddCategorySheet.tsx";
import { type BudgetCategory, BudgetsStep, readDraft } from "./BudgetsStep.tsx";
import { draftFromCents } from "./budget-input.ts";
import { CategoriesStep, type CustomCategory } from "./CategoriesStep.tsx";
import { CurrencyStep } from "./CurrencyStep.tsx";
import { currencyFromLanguages, DEFAULT_CURRENCY, isSupportedCurrency } from "./currency.ts";
import { ImportStep } from "./ImportStep.tsx";
import type { CurrencyNote, ImportDto, ImportState } from "./import-state.ts";
import { nextStep, previousStep, type StepId, stepFromParam, stepPath } from "./steps.ts";
import { normalizeName, SUGGESTED_CATEGORIES, suggestionFor } from "./suggested-categories.ts";
import { browserTimeZone, timeZoneToSave } from "./timezone.ts";
import { WelcomeStep } from "./WelcomeStep.tsx";

type Profile = paths["/v1/me"]["get"]["responses"][200]["content"]["application/json"];
type Category =
  paths["/v1/categories"]["get"]["responses"][200]["content"]["application/json"][number];

export interface WelcomeProps {
  /** The browser's languages (`navigator.languages`), to preselect the currency. */
  languages: readonly string[];
  /** The browser's time zone and the zones it knows; read from `Intl` unless a story says. */
  timeZone?: { zone: string | undefined; supported: readonly string[] };
}

/** Where the screen goes once onboarding is done or skipped. */
const APP_PATH = "/app";

function dataOf<T>(result: { data?: T; response: Response }): T {
  if (result.data === undefined) {
    throw new ApiProblem({ status: result.response.status, code: "internal_error" });
  }
  return result.data;
}

async function uploadImport(api: ApiClient, file: File): Promise<ImportDto> {
  // openapi-fetch sends FormData as is (the browser sets the multipart boundary).
  const form = new FormData();
  form.append("source", "budge");
  form.append("file", file);
  return dataOf(
    await api.POST("/v1/imports", { body: form as unknown as { source: "budge"; file: string } }),
  );
}

/** Active spending categories, as the budgets step lists them. */
function budgetCategories(categories: Category[] | undefined): BudgetCategory[] {
  return (categories ?? [])
    .filter((c) => c.kind === "expense" && !c.archived)
    .map((c) => ({ id: c.id, name: c.name, ...categoryLook(c) }));
}

/** The person's own active categories (not one of the suggestions), as chips. */
function customFrom(categories: Category[]): CustomCategory[] {
  return categories
    .filter((c) => !c.archived && !suggestionFor(c.name))
    .map((c) => ({ id: c.id, name: c.name, kind: c.kind, glyph: categoryLook(c).glyph }));
}

/**
 * What is chosen: with no categories yet, every suggestion (they come pre-selected); otherwise the
 * suggestions they have and their own categories (by id).
 */
function selectedFrom(categories: Category[]): Set<string> {
  const active = categories.filter((c) => !c.archived);
  if (active.length === 0) return new Set(SUGGESTED_CATEGORIES.map((c) => c.key));
  const keys = new Set<string>();
  for (const c of active) keys.add(suggestionFor(c.name)?.key ?? c.id);
  return keys;
}

/**
 * `/welcome/:step?`: the onboarding a new user sees once (spec §2.4, revised). It is optional and
 * short: the welcome offers "Configurar en 1 minuto" or "Entrar directo", and every setup step has
 * SIGUIENTE (apply what is on screen) and SALTAR (this step's defaults). Each step saves what it
 * needs before the next (currency, categories, import); budgets come last and stay drafts until the
 * end, so an import that switches the currency can replace amounts typed in the old one. Finishing
 * or skipping sets the onboarding flag, celebrates and lands on /app.
 */
export function Welcome({ languages, timeZone }: WelcomeProps) {
  const t = useTranslations("onboarding");
  const tRoot = useTranslations() as unknown as Translator;
  const params = useParams();
  const step = stepFromParam(params.step);
  const navigate = useNavigate();
  const api = useApi();
  const queryClient = useQueryClient();
  const { locale, setLocale } = useLocale();
  const me = useMe();
  const categoriesQuery = useCategories();

  const [currency, setCurrency] = useState<SupportedCurrency | null>(null);
  const [selected, setSelected] = useState<Set<string> | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string> | null>(null);
  const [importState, setImportState] = useState<ImportState>({ phase: "sources" });
  const [busy, setBusy] = useState(false);
  // A ref, not state: two taps in one frame must not both start a write.
  const inFlight = useRef(false);
  const [error, setError] = useState<string | null>(null);

  // First answers from the API seed the choices: the saved currency (or the browser's guess for a
  // new account), the categories and budgets they already have.
  const presetCurrency = (saved: string): SupportedCurrency =>
    isSupportedCurrency(saved) && saved !== DEFAULT_CURRENCY
      ? saved
      : currencyFromLanguages(languages);
  if (currency === null && me.data) setCurrency(presetCurrency(me.data.currency));
  if (selected === null && categoriesQuery.data) setSelected(selectedFrom(categoriesQuery.data));
  // Seeded in the profile's language, so `300,50` is never read back as an English 30050.
  const localeSettled =
    (me.data?.locale !== "es" && me.data?.locale !== "en") || me.data.locale === locale;
  if (drafts === null && categoriesQuery.data && me.data && localeSettled) {
    const seeded: Record<string, string> = {};
    for (const c of categoriesQuery.data) {
      if (c.currentBudget) seeded[c.id] = draftFromCents(c.currentBudget, locale);
    }
    setDrafts(seeded);
  }

  // The app speaks the profile's language (after a reload, the URL alone says Spanish).
  const profileLocale = me.data?.locale;
  useEffect(() => {
    if ((profileLocale === "es" || profileLocale === "en") && profileLocale !== locale) {
      setLocale(profileLocale);
    }
  }, [profileLocale, locale, setLocale]);

  // A new profile is on UTC: give it the browser's zone, so "today" and the months are the
  // person's. Once, and only while the stored zone is still the default.
  const storedZone = me.data?.timezone;
  const zoneSent = useRef(false);
  useEffect(() => {
    if (!storedZone || zoneSent.current) return;
    const { zone, supported } = timeZone ?? browserTimeZone();
    const next = timeZoneToSave(storedZone, zone, supported);
    if (!next) return;
    zoneSent.current = true;
    api
      .PATCH("/v1/me", { body: { timezone: next } })
      .then((result) => {
        if (result.data) queryClient.setQueryData(queryKeys.me(), result.data);
      })
      .catch(() => {
        // A nicety: the person can still set it in settings.
      });
  }, [storedZone, timeZone, api, queryClient]);

  // Only a first load that failed goes to the error boundary; a failed refetch keeps the data.
  if (me.error && !me.data) throw me.error;
  if (categoriesQuery.error && !categoriesQuery.data) throw categoriesQuery.error;

  if (step === null) return <Navigate to={stepPath("welcome")} replace />;
  if (!me.data || !categoriesQuery.data || currency === null || !selected || !drafts) {
    return <div className="lk-screen min-h-dvh" aria-busy="true" />;
  }

  const profile: Profile = me.data;
  const categories = categoriesQuery.data;
  const spending = budgetCategories(categories);

  const message = (problem: unknown) =>
    problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic");

  const go = (to: StepId | null) => {
    if (!to) return;
    setError(null);
    navigate(stepPath(to));
  };
  const back = previousStep(step);
  const onBack = back && back !== "welcome" ? () => go(back) : undefined;
  const forward = () => go(nextStep(step));

  /** Runs one write at a time; a failure is shown on the step and keeps it. */
  async function run(write: () => Promise<void>) {
    if (inFlight.current) return;
    inFlight.current = true;
    setBusy(true);
    setError(null);
    try {
      await write();
    } catch (problem) {
      setError(message(problem));
    } finally {
      inFlight.current = false;
      setBusy(false);
    }
  }

  const setProfile = (next: Profile) => queryClient.setQueryData(queryKeys.me(), next);

  async function patchCurrency(code: string): Promise<Profile> {
    const next = dataOf(
      await api.PATCH("/v1/me", { body: { currency: code as SupportedCurrency } }),
    );
    setProfile(next);
    return next;
  }

  /** The categories, refetched; the screen and the returned list agree. */
  async function refreshCategories(): Promise<Category[]> {
    // Throws when the read fails: callers need the fresh list, not a stale one.
    await queryClient.invalidateQueries(
      { queryKey: queryKeys.categories() },
      { throwOnError: true },
    );
    return queryClient.getQueryData<Category[]>(queryKeys.categories()) ?? [];
  }

  // -- Defaults (ENTRAR DIRECTO and each SALTAR) -------------------------------------------------

  /**
   * The preselected currency (the region's), set only while the account is empty: an account that
   * already has transactions keeps its own (409 `currency_locked` is not a failure here).
   */
  async function applyCurrency(code: SupportedCurrency) {
    if (code === profile.currency) return;
    try {
      await patchCurrency(code);
    } catch (problem) {
      if (!(problem instanceof ApiProblem && problem.code === "currency_locked")) throw problem;
    }
  }

  /** The suggested categories, created when the person has none yet. */
  async function ensureDefaultCategories() {
    if (categories.some((c) => !c.archived)) return;
    await Promise.all(
      SUGGESTED_CATEGORIES.map((suggestion, sortOrder) =>
        api.POST("/v1/categories", {
          body: {
            name: suggestion.names[locale],
            kind: suggestion.kind,
            icon: suggestion.glyph,
            color: suggestion.tint,
            sortOrder,
          },
        }),
      ),
    );
    await refreshCategories();
  }

  /** Sets the onboarding flag, celebrates and goes to the app (with or without budgets). */
  async function complete() {
    setProfile(dataOf(await api.PATCH("/v1/me", { body: { onboardingCompleted: true } })));
    void queryClient.invalidateQueries({ queryKey: queryKeys.categories() });
    feedback("expenseSaved");
    navigate(APP_PATH, { replace: true });
  }

  // -- Welcome -----------------------------------------------------------------------------------

  /** ENTRAR DIRECTO: the region's currency, the suggested categories, no budgets, then the app. */
  const enterDirectly = () =>
    run(async () => {
      await applyCurrency(presetCurrency(profile.currency));
      await ensureDefaultCategories();
      await complete();
    });

  // -- Currency ----------------------------------------------------------------------------------

  const saveCurrency = () =>
    run(async () => {
      if (currency !== profile.currency) await patchCurrency(currency);
      forward();
    });

  const skipCurrency = () =>
    run(async () => {
      const preset = presetCurrency(profile.currency);
      await applyCurrency(preset);
      setCurrency(preset);
      forward();
    });

  // -- Categories --------------------------------------------------------------------------------

  const toggle = (keyOrId: string) =>
    setSelected((current) => {
      const next = new Set(current);
      if (next.has(keyOrId)) next.delete(keyOrId);
      else next.add(keyOrId);
      return next;
    });

  /**
   * SIGUIENTE: creates the chosen suggestions they don't have, brings back archived ones, and
   * archives the suggestions and own categories they deselected.
   */
  const saveCategories = () =>
    run(async () => {
      const all = dataOf(
        await api.GET("/v1/categories", { params: { query: { includeArchived: "true" } } }),
      );
      const archive = (id: string, archived: boolean) =>
        api.PATCH("/v1/categories/{id}", { params: { path: { id } }, body: { archived } });
      const writes: Promise<unknown>[] = [];
      SUGGESTED_CATEGORIES.forEach((suggestion, sortOrder) => {
        const mine = all.filter((c) => suggestionFor(c.name)?.key === suggestion.key);
        const wanted = selected.has(suggestion.key);
        if (wanted && mine.length === 0) {
          writes.push(
            api.POST("/v1/categories", {
              body: {
                name: suggestion.names[locale],
                kind: suggestion.kind,
                icon: suggestion.glyph,
                color: suggestion.tint,
                sortOrder,
              },
            }),
          );
        } else if (wanted && mine.every((c) => c.archived)) {
          const [first] = mine;
          if (first) writes.push(archive(first.id, false));
        } else if (!wanted) {
          for (const c of mine.filter((m) => !m.archived)) writes.push(archive(c.id, true));
        }
      });
      for (const c of all.filter((c) => !c.archived && !suggestionFor(c.name))) {
        if (!selected.has(c.id)) writes.push(archive(c.id, true));
      }
      await Promise.all(writes);
      await refreshCategories();
      forward();
    });

  /** SALTAR: leaves the choice as it is on the server; with nothing there yet, the suggestions. */
  const skipCategories = () =>
    run(async () => {
      await ensureDefaultCategories();
      forward();
    });

  /** "＋ Agregar categoría": created right away, and chosen. */
  async function createCategory(category: NewCategory) {
    const created = dataOf(
      await api.POST("/v1/categories", {
        body: {
          name: category.name,
          kind: category.kind,
          icon: category.glyph,
          color: category.tint,
        },
      }),
    );
    setSelected((current) => new Set([...(current ?? []), created.id]));
    await refreshCategories();
  }

  // -- Import ------------------------------------------------------------------------------------

  /**
   * Reads the file. The importer only takes rows in the account's currency, so when the file is in
   * another one and the account is still empty, the file wins: the account switches, the first
   * preview (made under the old currency, so with its rows rejected) is dropped and the file is
   * read again. The preview the person confirms is always one made under the final currency.
   */
  async function readFile(file: File) {
    setImportState({ phase: "reading", fileName: file.name });
    try {
      let preview = await uploadImport(api, file);
      let note: CurrencyNote = null;
      const account = profile.currency;
      const fileCurrency = preview.stats.currency;
      if (fileCurrency && fileCurrency !== account) {
        note = { kind: "locked", file: fileCurrency, account };
        if (isSupportedCurrency(fileCurrency)) {
          try {
            await patchCurrency(fileCurrency);
            setCurrency(fileCurrency);
            note = { kind: "switched", file: fileCurrency, account };
            await api
              .DELETE("/v1/imports/{id}", { params: { path: { id: preview.id } } })
              .catch(() => {});
            preview = await uploadImport(api, file);
          } catch (problem) {
            // Transactions already: the currency stays, and so does the preview (rows rejected).
            if (!(problem instanceof ApiProblem && problem.code === "currency_locked")) {
              throw problem;
            }
          }
        }
      }
      setImportState({
        phase: "preview",
        fileName: file.name,
        preview,
        currencyNote: note,
        confirming: false,
      });
    } catch (problem) {
      setImportState({ phase: "idle", error: message(problem) });
    }
  }

  /** Drops the preview; a currency switched for it goes back to what it was. */
  async function discardImport(): Promise<boolean> {
    if (importState.phase !== "preview" || importState.discarding) return false;
    const { preview, currencyNote } = importState;
    setImportState({ ...importState, discarding: true, error: null });
    try {
      await api
        .DELETE("/v1/imports/{id}", { params: { path: { id: preview.id } } })
        .catch(() => {});
      if (currencyNote?.kind === "switched" && isSupportedCurrency(currencyNote.account)) {
        await patchCurrency(currencyNote.account);
        setCurrency(currencyNote.account);
      }
      setImportState({ phase: "idle" });
      return true;
    } catch (problem) {
      setImportState({ ...importState, discarding: false, error: message(problem) });
      return false;
    }
  }

  /**
   * Imports the previewed rows, then fills budgets from the file's monthly averages: the empty ones,
   * or all of them when the currency switched (amounts typed in the old currency mean nothing now).
   */
  async function confirmImport() {
    if (importState.phase !== "preview" || importState.confirming) return;
    const current = importState;
    setImportState({ ...current, confirming: true, error: null });
    let result: ImportDto;
    try {
      result = dataOf(
        await api.POST("/v1/imports/{id}/confirm", {
          params: { path: { id: current.preview.id } },
        }),
      );
    } catch (problem) {
      setImportState({ ...current, confirming: false, error: message(problem) });
      return;
    }
    // From here the rows are in: whatever happens next, the step says so (confirming again could
    // only fail), and a failed follow-up gets a retry.
    await afterImport(result, current.currencyNote);
  }

  /**
   * Refreshes what the import changed, then fills budgets from the file's recent months (the
   * preview's `averageMonthlySpending`, last 3 complete months): the empty ones, or all of them
   * when the currency switched (amounts typed in the old currency mean nothing now). Categories
   * without spending in those months keep no budget.
   */
  async function afterImport(result: ImportDto, currencyNote: CurrencyNote) {
    const imported = { phase: "imported" as const, result, currencyNote };
    setImportState({ ...imported, prefilled: false, retrying: true });
    try {
      // Everything built from transactions changed; so did the categories (new ones).
      void queryClient.invalidateQueries({
        predicate: (query) => query.queryKey[0] !== "me" && query.queryKey[0] !== "categories",
      });
      const categories = await refreshCategories();
      const averages = new Map(
        result.stats.averageMonthlySpending.map((a) => [normalizeName(a.category), a.amount]),
      );
      const switched = currencyNote?.kind === "switched";
      const nextDrafts: Record<string, string> = { ...drafts };
      let prefilled = false;
      for (const c of budgetCategories(categories)) {
        const average = averages.get(normalizeName(c.name));
        const empty = !nextDrafts[c.id]?.trim();
        if (average && average > 0 && (empty || switched)) {
          nextDrafts[c.id] = draftFromCents(average, locale);
          prefilled = true;
        } else if (switched) {
          nextDrafts[c.id] = "";
        }
      }
      setDrafts(nextDrafts);
      setSelected((keys) => new Set([...(keys ?? []), ...selectedFrom(categories)]));
      setImportState({ ...imported, prefilled });
    } catch (problem) {
      setImportState({ ...imported, prefilled: false, error: message(problem) });
    }
  }

  /** SALTAR on the import: a pending preview is dropped (and a currency switched for it put back). */
  const skipImport = () =>
    run(async () => {
      if (importState.phase === "preview") await discardImport();
      forward();
    });

  /** "Basado en lo que gastaste en tus últimos 3 meses", or "…con movimientos" for an old export. */
  function prefillBasis(): string | null {
    if (importState.phase !== "imported" || !importState.prefilled) return null;
    const window = importState.result.stats.averageWindow;
    if (!window) return null;
    const lastComplete = addMonths(monthOf(todayIn(profile.timezone)), -1);
    return window.to === lastComplete
      ? t("prefill_basis", { months: window.months })
      : t("prefill_basis_activity", { months: window.months });
  }

  // -- Budgets (last) ----------------------------------------------------------------------------

  /** SIGUIENTE: saves the budgets typed or prefilled, then finishes. */
  const finish = () =>
    run(async () => {
      const month = monthOf(todayIn(profile.timezone));
      const byId = new Map(categories.map((c) => [c.id, c]));
      await Promise.all(
        spending.map(async (c) => {
          const amount = readDraft(drafts[c.id], locale);
          if (typeof amount !== "number" || byId.get(c.id)?.currentBudget === amount) return;
          dataOf(
            await api.PUT("/v1/categories/{id}/budget", {
              params: { path: { id: c.id } },
              body: { amount, effectiveFrom: month },
            }),
          );
        }),
      );
      await complete();
    });

  /** SALTAR: finishes without budgets. */
  const finishWithoutBudgets = () => run(complete);

  // -- Screens -----------------------------------------------------------------------------------

  const nav = { onBack, busy };
  switch (step) {
    case "welcome":
      return (
        <WelcomeStep
          onSetup={() => go("currency")}
          onDirect={enterDirectly}
          busy={busy}
          error={error}
        />
      );
    case "currency":
      return (
        <CurrencyStep
          {...nav}
          value={currency}
          onChange={setCurrency}
          onSkip={skipCurrency}
          onNext={saveCurrency}
          error={error}
        />
      );
    case "categories":
      return (
        <CategoriesStep
          {...nav}
          selected={selected}
          onToggle={toggle}
          custom={customFrom(categories)}
          onCreate={createCategory}
          errorText={message}
          onSkip={skipCategories}
          onNext={saveCategories}
          error={error}
        />
      );
    case "import":
      return (
        <ImportStep
          {...nav}
          state={importState}
          currency={profile.currency}
          onSource={(source) => setImportState({ phase: source ? "idle" : "sources" })}
          onFile={readFile}
          onConfirm={confirmImport}
          onDiscard={() => void discardImport()}
          onRetry={() => {
            if (importState.phase === "imported") {
              void afterImport(importState.result, importState.currencyNote);
            }
          }}
          prefillBasis={prefillBasis()}
          onSkip={skipImport}
          onNext={forward}
        />
      );
    case "budgets":
      return (
        <BudgetsStep
          {...nav}
          categories={spending}
          drafts={drafts}
          onChange={(id, text) => setDrafts((current) => ({ ...current, [id]: text }))}
          currency={profile.currency}
          prefillBasis={prefillBasis()}
          onSkip={finishWithoutBudgets}
          onNext={finish}
          error={error}
        />
      );
  }
}
