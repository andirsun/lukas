import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useId, useRef, useState } from "react";
import { useTranslations } from "use-intl";
import { useApi } from "../../api/ApiProvider.tsx";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { queryKeys, useCategories, useMe } from "../../api/queries.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { Lukas } from "../../lukas/Lukas.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { BudgetsList, BudgetsTotal, draftsTotal, readDraft } from "./BudgetsStep.tsx";
import { draftFromCents } from "./budget-input.ts";
import { ImportPanel } from "./ImportStep.tsx";
import { type Category, type Profile, saveBudgets } from "./onboarding-api.ts";
import { StepError } from "./StepFrame.tsx";
import { spendingOf, useImportFlow } from "./use-import-flow.ts";

/**
 * `/app/import`: the onboarding's import on its own, for after onboarding (home's "Trae tu
 * historial"), ending with the budgets as onboarding does. Same sources, how-to, preview and
 * confirm, with the same rules: an empty account takes the file's currency on confirm (the API does
 * it atomically, and drops budgets in the old currency, which the preview warns about); leaving
 * before confirming changes nothing. After the import, the budgets are prefilled from the file's
 * recent months and saved only with "Guardar presupuestos".
 */
export function ImportPage() {
  const t = useTranslations("onboarding");
  const tRoot = useTranslations() as unknown as Translator;
  const { locale } = useLocale();
  const api = useApi();
  const queryClient = useQueryClient();
  const me = useMe();
  const categories = useCategories();
  const heading = useRef<HTMLHeadingElement>(null);
  const budgetsHeading = useRef<HTMLHeadingElement>(null);
  const budgetsId = useId();
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [budgets, setBudgets] = useState<"editing" | "saving" | "saved">("editing");
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    heading.current?.focus();
  }, []);

  const message = (problem: unknown) =>
    problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic");

  async function refreshCategories(): Promise<Category[]> {
    await queryClient.invalidateQueries(
      { queryKey: queryKeys.categories() },
      { throwOnError: true },
    );
    return queryClient.getQueryData<Category[]>(queryKeys.categories()) ?? [];
  }

  const flow = useImportFlow({
    // The shell waits for the profile; the placeholder only covers the very first render.
    profile: me.data ?? ({ currency: "", timezone: "UTC" } as Profile),
    locale,
    message,
    refreshCategories,
    onCurrency: () => {},
    drafts,
    setDrafts,
    // The budgets already saved start the form; the import's averages fill the empty ones.
    onImported: () => {},
  });

  const imported = flow.state.phase === "imported" && !flow.state.retrying && !flow.state.error;
  const shownCategories = categories.data ?? [];
  const spending = spendingOf(shownCategories);
  const currency = me.data?.currency ?? "";

  // Once imported, the budgets section takes focus: it's what to do next.
  useEffect(() => {
    if (imported) budgetsHeading.current?.focus();
  }, [imported]);

  // Saved budgets the import didn't fill show as they are.
  const withSaved: Record<string, string> = { ...drafts };
  for (const c of shownCategories) {
    if (withSaved[c.id] === undefined && c.currentBudget) {
      withSaved[c.id] = draftFromCents(c.currentBudget, locale);
    }
  }
  const invalid = spending.some((c) => readDraft(withSaved[c.id], locale) === "invalid");

  async function save() {
    if (budgets === "saving" || !me.data) return;
    setBudgets("saving");
    setError(null);
    try {
      await saveBudgets(api, shownCategories, withSaved, locale, me.data.timezone);
      await queryClient.invalidateQueries({ queryKey: queryKeys.categories() });
      void queryClient.invalidateQueries({ predicate: (q) => q.queryKey[0] === "summary" });
      setBudgets("saved");
    } catch (problem) {
      setError(message(problem));
      setBudgets("editing");
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-[480px] flex-col gap-(--space-4) px-(--space-4) pt-(--space-4)">
      <main className="flex flex-col gap-(--space-4)">
        <div className="flex items-center gap-(--space-3)">
          <span className="shrink-0">
            <Lukas mood="happy" size={72} />
          </span>
          <h1
            ref={heading}
            tabIndex={-1}
            className="font-display text-[26px] leading-tight font-bold text-ink outline-none"
          >
            {t("import.page_title")}
          </h1>
        </div>
        {flow.state.phase === "sources" && (
          <p className="text-ink-muted">{t("import.page_lead")}</p>
        )}
        <ImportPanel
          state={flow.state}
          onFile={flow.readFile}
          onDiscard={() => void flow.discard()}
          onSource={flow.chooseSource}
          onRetry={flow.retry}
          onConfirm={flow.confirm}
          showPrefill={false}
        />

        {imported && (
          <section aria-labelledby={budgetsId} className="flex flex-col gap-(--space-3)">
            <h2
              ref={budgetsHeading}
              id={budgetsId}
              tabIndex={-1}
              className="font-display text-[22px] font-bold text-ink outline-none"
            >
              {t("import.page_budgets_title")}
            </h2>
            {budgets === "saved" ? (
              <p role="status" className="font-display text-[18px] font-bold text-good">
                {t("import.budgets_saved")}
              </p>
            ) : (
              <>
                <p className="text-ink-muted">{t("import.page_budgets_lead")}</p>
                {flow.prefillBasis() && (
                  <p className="text-[15px] text-ink-muted">{flow.prefillBasis()}</p>
                )}
                <BudgetsList
                  categories={spending}
                  drafts={withSaved}
                  onChange={(id, text) =>
                    setDrafts((current) => ({ ...withSaved, ...current, [id]: text }))
                  }
                  currency={currency}
                />
                <BudgetsTotal
                  total={draftsTotal(spending, withSaved, locale)}
                  currency={currency}
                />
                {error && <StepError>{error}</StepError>}
                <PressButton
                  className="w-full"
                  onClick={() => void save()}
                  disabled={invalid || budgets === "saving"}
                >
                  {budgets === "saving" ? t("saving") : t("import.save_budgets")}
                </PressButton>
              </>
            )}
            <PressLink
              to="/app"
              variant={budgets === "saved" ? "primary" : "secondary"}
              className="w-full"
            >
              {t("import.go_home")}
            </PressLink>
          </section>
        )}
      </main>
    </div>
  );
}
