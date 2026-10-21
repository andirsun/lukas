import { monthOf, type SupportedCurrency, todayIn } from "@lukas/core";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";
import { Navigate, useNavigate, useParams } from "react-router";
import { useTranslations } from "use-intl";
import { useApi } from "../../api/ApiProvider.tsx";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { queryKeys, useCategories, useMe } from "../../api/queries.ts";
import { feedback } from "../../feedback/feedback.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import type { NewCategory } from "./AddCategorySheet.tsx";
import { BudgetsStep, readDraft } from "./BudgetsStep.tsx";
import { draftFromCents } from "./budget-input.ts";
import { CategoriesStep, type CustomCategory } from "./CategoriesStep.tsx";
import { CurrencyStep } from "./CurrencyStep.tsx";
import { defaultCurrency, isSupportedCurrency } from "./currency.ts";
import { ImportStep } from "./ImportStep.tsx";
import {
  allCategories,
  type Category,
  createSuggestions,
  dataOf,
  type Profile,
  patchCurrency,
  useHasTransactions,
} from "./onboarding-api.ts";
import { clearOnboardingDraft, useOnboardingDraft } from "./onboarding-draft.ts";
import { nextStep, previousStep, type StepId, stepFromParam, stepPath } from "./steps.ts";
import { SUGGESTED_CATEGORIES, suggestionFor } from "./suggested-categories.ts";
import { browserTimeZone, timeZoneToSave } from "./timezone.ts";
import { spendingOf, useImportFlow } from "./use-import-flow.ts";
import { WelcomeStep } from "./WelcomeStep.tsx";

export interface WelcomeProps {
  /** The browser's languages (`navigator.languages`), to preselect the currency. */
  languages: readonly string[];
  /** The browser's time zone and the zones it knows; read from `Intl` unless a story says. */
  timeZone?: { zone: string | undefined; supported: readonly string[] };
}

/** Where the screen goes once onboarding is done or skipped. */
const APP_PATH = "/app";
const ALL_SUGGESTIONS = new Set(SUGGESTED_CATEGORIES.map((c) => c.key));

/** The person's own active categories (not one of the suggestions), as chips. */
function customFrom(categories: Category[]): CustomCategory[] {
  return categories
    .filter((c) => !c.archived && !suggestionFor(c.name))
    .map((c) => ({ id: c.id, name: c.name, kind: c.kind, glyph: categoryLook(c).glyph }));
}

/** What is active on the server, as chips: suggestion keys and own category ids. */
function activeChips(categories: Category[]): string[] {
  return categories.filter((c) => !c.archived).map((c) => suggestionFor(c.name)?.key ?? c.id);
}

/**
 * `/welcome/:step?`: the onboarding a new user sees once (spec §2.4, revised). It is optional and
 * short: the welcome offers "Configurar en 1 minuto" or "Entrar directo", and every setup step has
 * SIGUIENTE (apply what is on screen) and SALTAR (move on with this step's defaults). Each step
 * saves what it needs before the next (currency, categories, import); budgets come last and stay
 * drafts until the end, so an import that switches the currency can replace amounts typed in the
 * old one. Choices not on the server yet (the currency picked, the chips) live in a session draft,
 * so a reload keeps them. Finishing or skipping sets the onboarding flag, celebrates and lands on
 * /app.
 */
export function Welcome({ languages, timeZone }: WelcomeProps) {
  const tRoot = useTranslations() as unknown as Translator;
  const params = useParams();
  const step = stepFromParam(params.step);
  const navigate = useNavigate();
  const api = useApi();
  const queryClient = useQueryClient();
  const { locale, setLocale } = useLocale();
  const me = useMe();
  const categoriesQuery = useCategories();
  const hasTransactions = useHasTransactions();
  const [draft, updateDraft] = useOnboardingDraft(me.data?.id);
  const [browser] = useState(() => timeZone ?? browserTimeZone());

  const [currency, setCurrency] = useState<SupportedCurrency | null>(null);
  const [selected, setSelected] = useState<Set<string> | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string> | null>(null);
  const [busy, setBusy] = useState(false);
  // A ref, not state: two taps in one frame must not both start a write.
  const inFlight = useRef(false);
  const [error, setError] = useState<string | null>(null);

  /**
   * The currency to preselect: one they chose this session; else, with transactions (the currency
   * is locked), the account's; else the default for where they are (CO → COP, Europe → EUR, USD).
   */
  const preset = (): SupportedCurrency | null => {
    if (!me.data || !draft || hasTransactions.data === undefined) return null;
    if (draft.currency) return draft.currency;
    if (hasTransactions.data && isSupportedCurrency(me.data.currency)) return me.data.currency;
    return defaultCurrency(languages, browser.zone);
  };
  if (currency === null) {
    const first = preset();
    if (first) setCurrency(first);
  }
  // The chips: those they chose this session; else what they kept from the categories step; else
  // every suggestion (pre-selected) plus what they already have.
  if (selected === null && categoriesQuery.data && draft) {
    const active = activeChips(categoriesQuery.data);
    setSelected(
      new Set(draft.selected ?? (draft.categoriesDone ? active : [...ALL_SUGGESTIONS, ...active])),
    );
  }
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
    const next = timeZoneToSave(storedZone, browser.zone, browser.supported);
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
  }, [storedZone, browser, api, queryClient]);

  const message = (problem: unknown) =>
    problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic");

  /** The categories, refetched; the screen and the returned list agree. */
  async function refreshCategories(): Promise<Category[]> {
    // Throws when the read fails: callers need the fresh list, not a stale one.
    await queryClient.invalidateQueries(
      { queryKey: queryKeys.categories() },
      { throwOnError: true },
    );
    return queryClient.getQueryData<Category[]>(queryKeys.categories()) ?? [];
  }

  const choose = (next: Set<string>) => {
    setSelected(next);
    updateDraft({ selected: [...next] });
  };

  const importFlow = useImportFlow({
    // Placeholders until the data is in; the hook only acts on a step, which waits for it.
    profile: me.data ?? ({ currency: "", timezone: "UTC" } as Profile),
    locale,
    message,
    refreshCategories,
    onCurrency: setCurrency,
    drafts: drafts ?? {},
    setDrafts,
    onImported: (categories) => choose(new Set([...(selected ?? []), ...activeChips(categories)])),
  });

  // Only a first load that failed goes to the error boundary; a failed refetch keeps the data.
  if (me.error && !me.data) throw me.error;
  if (categoriesQuery.error && !categoriesQuery.data) throw categoriesQuery.error;
  if (hasTransactions.error && hasTransactions.data === undefined) throw hasTransactions.error;

  if (step === null) return <Navigate to={stepPath("welcome")} replace />;
  if (!me.data || !categoriesQuery.data || !draft || currency === null || !selected || !drafts) {
    return <div className="lk-screen min-h-dvh" aria-busy="true" />;
  }

  const profile: Profile = me.data;
  const categories = categoriesQuery.data;
  const spending = spendingOf(categories);
  // A deep link (or a reload) to the budgets before any categories exist goes to make them first.
  // After the categories step it stays: deselecting everything is allowed.
  if (step === "budgets" && spending.length === 0 && !draft.categoriesDone) {
    return <Navigate to={stepPath("categories")} replace />;
  }

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

  /** The currency set, only while the account is empty (a locked one is not a failure here). */
  async function applyCurrency(code: SupportedCurrency) {
    if (code === profile.currency) return;
    try {
      queryClient.setQueryData(queryKeys.me(), await patchCurrency(api, code));
    } catch (problem) {
      if (!(problem instanceof ApiProblem && problem.code === "currency_locked")) throw problem;
    }
  }

  /** Sets the onboarding flag, celebrates and goes to the app (with or without budgets). */
  async function complete() {
    queryClient.setQueryData(
      queryKeys.me(),
      dataOf(await api.PATCH("/v1/me", { body: { onboardingCompleted: true } })),
    );
    clearOnboardingDraft(profile.id);
    void queryClient.invalidateQueries({ queryKey: queryKeys.categories() });
    feedback("expenseSaved");
    navigate(APP_PATH, { replace: true });
  }

  /**
   * ENTRAR DIRECTO: the preselected currency, the suggested categories, no budgets, then the app.
   * Safe to tap again after a failure: the suggestions are re-read before creating the missing ones.
   */
  const enterDirectly = () =>
    run(async () => {
      if (!hasTransactions.data) await applyCurrency(currency);
      await createSuggestions(api, ALL_SUGGESTIONS, locale);
      await refreshCategories();
      await complete();
    });

  const saveCurrency = () =>
    run(async () => {
      if (currency !== profile.currency) {
        queryClient.setQueryData(queryKeys.me(), await patchCurrency(api, currency));
      }
      updateDraft({ currency });
      go("categories");
    });

  /** SALTAR: the preselected currency, set while the account is empty. */
  const skipCurrency = () =>
    run(async () => {
      const code = preset() ?? currency;
      if (!hasTransactions.data) await applyCurrency(code);
      setCurrency(code);
      go("categories");
    });

  /**
   * SIGUIENTE: creates the chosen suggestions they don't have, brings back archived ones, and
   * archives the suggestions and own categories they deselected.
   */
  const saveCategories = () =>
    run(async () => {
      const all = await allCategories(api);
      const archive = (id: string, archived: boolean) =>
        api.PATCH("/v1/categories/{id}", { params: { path: { id } }, body: { archived } });
      const writes: Promise<unknown>[] = [];
      for (const suggestion of SUGGESTED_CATEGORIES) {
        const mine = all.filter((c) => suggestionFor(c.name)?.key === suggestion.key);
        const wanted = selected.has(suggestion.key);
        if (wanted && mine.length > 0 && mine.every((c) => c.archived)) {
          writes.push(archive((mine[0] as Category).id, false));
        } else if (!wanted) {
          for (const c of mine.filter((m) => !m.archived)) writes.push(archive(c.id, true));
        }
      }
      for (const c of all.filter((c) => !c.archived && !suggestionFor(c.name))) {
        if (!selected.has(c.id)) writes.push(archive(c.id, true));
      }
      await Promise.all(writes);
      await createSuggestions(api, selected, locale);
      await refreshCategories();
      updateDraft({ categoriesDone: true });
      go("import");
    });

  /** SALTAR: creates the chosen suggestions they don't have yet, and never archives anything. */
  const skipCategories = () =>
    run(async () => {
      await createSuggestions(api, selected, locale);
      await refreshCategories();
      updateDraft({ categoriesDone: true });
      go("import");
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
    choose(new Set([...(selected ?? []), created.id]));
    // The sheet closes as soon as it is saved; the chip shows when the list comes back (a failed
    // read leaves the category saved, and the next step's write reads the list again).
    void refreshCategories().catch(() => {});
  }

  /** SALTAR on the import: never while it is busy; a pending preview is dropped first. */
  const skipImport = () =>
    run(async () => {
      if (await importFlow.skip()) go("budgets");
    });

  /** SIGUIENTE on the budgets: saves the ones typed or prefilled, then finishes. */
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

  const nav = { onBack, busy };
  switch (step) {
    case "welcome":
      return (
        <WelcomeStep
          currency={currency}
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
          onChange={(code) => {
            setCurrency(code);
            updateDraft({ currency: code });
          }}
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
          onToggle={(keyOrId) => {
            const next = new Set(selected);
            if (next.has(keyOrId)) next.delete(keyOrId);
            else next.add(keyOrId);
            choose(next);
          }}
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
          locked={importFlow.locked}
          state={importFlow.state}
          currency={profile.currency}
          onSource={importFlow.chooseSource}
          onFile={importFlow.readFile}
          onConfirm={importFlow.confirm}
          onDiscard={() => void importFlow.discard()}
          onRetry={importFlow.retry}
          prefillBasis={importFlow.prefillBasis()}
          onSkip={skipImport}
          onNext={() => go("budgets")}
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
          prefillBasis={importFlow.prefillBasis()}
          onSkip={() => run(complete)}
          onNext={finish}
          error={error}
        />
      );
  }
}
