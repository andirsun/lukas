import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef } from "react";
import { useTranslations } from "use-intl";
import { ApiProblem, problemMessage, type Translator } from "../../api/errors.ts";
import { queryKeys, useMe } from "../../api/queries.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { Lukas } from "../../lukas/Lukas.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { ImportPanel } from "./ImportStep.tsx";
import type { Category, Profile } from "./onboarding-api.ts";
import { useImportFlow } from "./use-import-flow.ts";

/**
 * `/app/import`: the onboarding's import on its own, for after onboarding (home's "Trae tu
 * historial"). Same sources, how-to, preview and confirm, with the same rules: the file's currency
 * wins on an empty account, a pending preview can be dropped, the confirm is race-safe on the API.
 * There are no budgets to prefill here.
 */
export function ImportPage() {
  const t = useTranslations("onboarding.import");
  const tRoot = useTranslations() as unknown as Translator;
  const { locale } = useLocale();
  const queryClient = useQueryClient();
  const me = useMe();
  const heading = useRef<HTMLHeadingElement>(null);

  useEffect(() => {
    heading.current?.focus();
  }, []);

  const flow = useImportFlow({
    // The shell waits for the profile; the placeholder only covers the very first render.
    profile: me.data ?? ({ currency: "", timezone: "UTC" } as Profile),
    locale,
    message: (problem) =>
      problem instanceof ApiProblem ? problemMessage(problem, tRoot) : tRoot("errors.generic"),
    refreshCategories: async () => {
      await queryClient.invalidateQueries(
        { queryKey: queryKeys.categories() },
        { throwOnError: true },
      );
      return queryClient.getQueryData<Category[]>(queryKeys.categories()) ?? [];
    },
    onCurrency: () => {},
    drafts: {},
    setDrafts: () => {},
    onImported: () => {},
  });

  return (
    <div className="mx-auto flex w-full max-w-[480px] flex-col gap-(--space-4) px-(--space-4) pt-(--space-4)">
      <div className="flex items-center gap-(--space-3)">
        <span className="shrink-0">
          <Lukas mood="happy" size={72} />
        </span>
        <h1
          ref={heading}
          tabIndex={-1}
          className="font-display text-[26px] leading-tight font-bold text-ink outline-none"
        >
          {t("page_title")}
        </h1>
      </div>
      {flow.state.phase === "sources" && <p className="text-ink-muted">{t("page_lead")}</p>}
      <main className="flex flex-col gap-(--space-4)">
        <ImportPanel
          state={flow.state}
          onFile={flow.readFile}
          onDiscard={() => void flow.discard()}
          onSource={flow.chooseSource}
          onRetry={flow.retry}
          onConfirm={flow.confirm}
        />
        {flow.state.phase === "imported" && !flow.state.retrying && (
          <PressLink to="/app" className="w-full">
            {t("go_home")}
          </PressLink>
        )}
      </main>
    </div>
  );
}
