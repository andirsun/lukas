import { monthOf, type SupportedCurrency, todayIn } from "@lukas/core";
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
import { useToast } from "../../ui/Toast.tsx";
import { type BudgetCategory, BudgetsStep, draftsTotal, readDraft } from "./BudgetsStep.tsx";
import { draftFromCents } from "./budget-input.ts";
import { CategoriesStep } from "./CategoriesStep.tsx";
import { CurrencyStep } from "./CurrencyStep.tsx";
import { currencyFromLanguages, DEFAULT_CURRENCY, isSupportedCurrency } from "./currency.ts";
import { DoneStep } from "./DoneStep.tsx";
import { ImportStep } from "./ImportStep.tsx";
import type { CurrencyNote, ImportDto, ImportState } from "./import-state.ts";
import { PasskeyStep } from "./PasskeyStep.tsx";
import type { PasskeyAdder } from "./passkey.ts";
import { nextStep, previousStep, type StepId, stepFromParam, stepPath } from "./steps.ts";
import { normalizeName, SUGGESTED_CATEGORIES, suggestionFor } from "./suggested-categories.ts";

type Profile = paths["/v1/me"]["get"]["responses"][200]["content"]["application/json"];
type Category =
  paths["/v1/categories"]["get"]["responses"][200]["content"]["application/json"][number];

export interface WelcomeProps {
  passkeys: PasskeyAdder;
  /** The browser's languages (`navigator.languages`), to preselect the currency. */
  languages: readonly string[];
}

/** Where the screen goes once onboarding is done. */
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

/** Suggestion keys the person already has as active categories (back from a later step, a reload). */
function selectedFrom(categories: Category[]): Set<string> {
  const keys = new Set<string>();
  for (const c of categories) {
    const suggestion = suggestionFor(c.name);
    if (suggestion && !c.archived) keys.add(suggestion.key);
  }
  return keys;
}

/**
 * `/welcome/:step?`: the onboarding a new user runs once (spec §2.4). Each step saves what it
 * needs before the next: the currency, the categories (the import maps rows to them by name), the
 * import. Budgets stay drafts until "Empezar", so an import that switches the currency can replace
 * amounts typed in the old one; then the flag is set and the person lands on /app.
 */
export function Welcome({ passkeys, languages }: WelcomeProps) {
  const t = useTranslations("onboarding");
  const tRoot = useTranslations() as unknown as Translator;
  const params = useParams();
  const step = stepFromParam(params.step);
  const navigate = useNavigate();
  const api = useApi();
  const queryClient = useQueryClient();
  const toast = useToast();
  const { locale, setLocale } = useLocale();
  const me = useMe();
  const categoriesQuery = useCategories();
  const [passkeysAvailable] = useState(() => passkeys.available());
  const context = { passkeys: passkeysAvailable };

  const [currency, setCurrency] = useState<SupportedCurrency | null>(null);
  const [selected, setSelected] = useState<Set<string> | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string> | null>(null);
  const [importState, setImportState] = useState<ImportState>({ phase: "idle" });
  const [busy, setBusy] = useState(false);
  // A ref, not state: two taps in one frame must not both start a write.
  const inFlight = useRef(false);
  const [error, setError] = useState<string | null>(null);
  const [passkeyState, setPasskeyState] = useState<{ adding: boolean; error: string | null }>({
    adding: false,
    error: null,
  });

  // First answers from the API seed the choices: the saved currency (or the browser's guess for a
  // new account), the categories and budgets they already have.
  if (currency === null && me.data) {
    const saved = me.data.currency;
    setCurrency(
      isSupportedCurrency(saved) && saved !== DEFAULT_CURRENCY
        ? saved
        : currencyFromLanguages(languages),
    );
  }
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

  if (me.error) throw me.error;
  if (categoriesQuery.error) throw categoriesQuery.error;

  if (step === null) return <Navigate to={stepPath("currency")} replace />;
  if (step === "passkey" && !passkeysAvailable) {
    return <Navigate to={stepPath("categories")} replace />;
  }
  if (!me.data || !categoriesQuery.data || currency === null || !selected || !drafts) {
    return <div className="lk-screen min-h-dvh" aria-busy="true" />;
  }

  const profile: Profile = me.data;
  const spending = budgetCategories(categoriesQuery.data);
  if (spending.length === 0 && (step === "budgets" || step === "import" || step === "done")) {
    return <Navigate to={stepPath("categories")} replace />;
  }

  const message = (problem: unknown) =>
    problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic");

  const go = (to: StepId | null) => {
    if (!to) return;
    setError(null);
    navigate(stepPath(to));
  };
  const back = previousStep(step, context);
  const onBack = back ? () => go(back) : undefined;
  const forward = () => go(nextStep(step, context));

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
    await queryClient.invalidateQueries({ queryKey: queryKeys.categories() });
    return queryClient.getQueryData<Category[]>(queryKeys.categories()) ?? [];
  }

  // -- Step 0 ----------------------------------------------------------------------------------

  const saveCurrency = () =>
    run(async () => {
      if (currency !== profile.currency) await patchCurrency(currency);
      forward();
    });

  // -- Step 1 ----------------------------------------------------------------------------------

  async function addPasskey() {
    if (passkeyState.adding) return;
    setPasskeyState({ adding: true, error: null });
    const outcome = await passkeys.add();
    if (outcome === "added") {
      setPasskeyState({ adding: false, error: null });
      toast.show({ message: t("passkey.added") });
      forward();
    } else {
      setPasskeyState({
        adding: false,
        error: outcome === "failed" ? t("passkey.failed") : null,
      });
    }
  }

  // -- Step 2 ----------------------------------------------------------------------------------

  const toggle = (key: string) =>
    setSelected((current) => {
      const next = new Set(current);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });

  /** Creates the chosen suggestions they don't have, brings back archived ones, archives the rest. */
  const saveCategories = () =>
    run(async () => {
      const all = dataOf(
        await api.GET("/v1/categories", { params: { query: { includeArchived: "true" } } }),
      );
      const writes: Promise<unknown>[] = [];
      SUGGESTED_CATEGORIES.forEach((suggestion, sortOrder) => {
        const mine = all.filter((c) => suggestionFor(c.name)?.key === suggestion.key);
        const wanted = selected.has(suggestion.key);
        const archive = (id: string, archived: boolean) =>
          api.PATCH("/v1/categories/{id}", { params: { path: { id } }, body: { archived } });
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
      await Promise.all(writes);
      await refreshCategories();
      forward();
    });

  // -- Step 4 ----------------------------------------------------------------------------------

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
  async function discardImport() {
    if (importState.phase !== "preview" || importState.discarding) return;
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
    } catch (problem) {
      setImportState({ ...importState, discarding: false, error: message(problem) });
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
    try {
      const result = dataOf(
        await api.POST("/v1/imports/{id}/confirm", {
          params: { path: { id: current.preview.id } },
        }),
      );
      // Everything built from transactions changed; so did the categories (new ones).
      await queryClient.invalidateQueries({
        predicate: (query) => query.queryKey[0] !== "me" && query.queryKey[0] !== "categories",
      });
      const categories = await refreshCategories();
      const averages = new Map(
        result.stats.averageMonthlySpending.map((a) => [normalizeName(a.category), a.amount]),
      );
      const switched = current.currencyNote?.kind === "switched";
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
      setImportState({
        phase: "imported",
        result,
        prefilled,
        currencyNote: current.currencyNote,
      });
    } catch (problem) {
      setImportState({ ...current, confirming: false, error: message(problem) });
    }
  }

  // -- Step 5 ----------------------------------------------------------------------------------

  /** Saves the budgets and the onboarding flag, celebrates, and goes to the app. */
  const finish = () =>
    run(async () => {
      const month = monthOf(todayIn(profile.timezone));
      const byId = new Map(categoriesQuery.data?.map((c) => [c.id, c]));
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
      setProfile(dataOf(await api.PATCH("/v1/me", { body: { onboardingCompleted: true } })));
      await queryClient.invalidateQueries({ queryKey: queryKeys.categories() });
      feedback("expenseSaved");
      navigate(APP_PATH, { replace: true });
    });

  // -- Screens ---------------------------------------------------------------------------------

  switch (step) {
    case "currency":
      return (
        <CurrencyStep
          value={currency}
          onChange={setCurrency}
          onNext={saveCurrency}
          busy={busy}
          error={error}
        />
      );
    case "passkey":
      return (
        <PasskeyStep
          onAdd={addPasskey}
          adding={passkeyState.adding}
          error={passkeyState.error}
          onBack={onBack}
          onNext={forward}
        />
      );
    case "categories":
      return (
        <CategoriesStep
          selected={selected}
          onToggle={toggle}
          busy={busy}
          error={error}
          onBack={onBack}
          onNext={saveCategories}
        />
      );
    case "budgets":
      return (
        <BudgetsStep
          categories={spending}
          drafts={drafts}
          onChange={(id, text) => setDrafts((current) => ({ ...current, [id]: text }))}
          currency={profile.currency}
          onBack={onBack}
          onNext={forward}
        />
      );
    case "import":
      return (
        <ImportStep
          state={importState}
          currency={profile.currency}
          onFile={readFile}
          onConfirm={confirmImport}
          onDiscard={discardImport}
          onReviewBudgets={() => go("budgets")}
          onBack={onBack}
          onNext={forward}
        />
      );
    case "done":
      return (
        <DoneStep
          total={draftsTotal(spending, drafts, locale)}
          currency={profile.currency}
          busy={busy}
          error={error}
          onBack={onBack}
          onNext={finish}
        />
      );
  }
}
