import { monthOf, todayIn } from "@lukas/core";
import { useId } from "react";
import { useTranslations } from "use-intl";
import { useMe, useSummary } from "../api/queries.ts";
import { requireOnboarded } from "../auth/session.ts";
import { formatMoney } from "../i18n/format.ts";
import { useLocale } from "../i18n/IntlProvider.tsx";
import { Lukas } from "../lukas/Lukas.tsx";
import { Money } from "../ui/Money.tsx";
import { ThemeToggle } from "../ui/ThemeToggle.tsx";
import type { Route } from "./+types/app-placeholder";

/**
 * A stand-in for `/app` until the home screen exists (Task 12 replaces this route): somewhere for
 * onboarding to land, showing what was spent this month and against which budget.
 */
export async function clientLoader({ request }: Route.ClientLoaderArgs) {
  await requireOnboarded(new URL(request.url).pathname);
  return null;
}

export function HydrateFallback() {
  return <div className="lk-screen min-h-dvh" />;
}

export default function AppPlaceholder() {
  const me = useMe();
  if (me.error) throw me.error;
  if (!me.data) return <div className="lk-screen min-h-dvh" aria-busy="true" />;
  return <SpentThisMonth timezone={me.data.timezone} currency={me.data.currency} />;
}

function SpentThisMonth({ timezone, currency }: { timezone: string; currency: string }) {
  const t = useTranslations("home");
  const { locale } = useLocale();
  const labelId = useId();
  const summary = useSummary(monthOf(todayIn(timezone)));
  if (summary.error) throw summary.error;
  return (
    <div className="lk-screen flex min-h-dvh flex-col">
      <header className="mx-auto flex w-full max-w-[480px] items-center justify-between px-(--space-4) py-(--space-3)">
        <span className="lk-logo inline-flex min-h-11 items-center">Lukitas</span>
        <ThemeToggle />
      </header>
      <main className="mx-auto flex w-full max-w-[480px] flex-col items-center gap-(--space-4) px-(--space-4)">
        <Lukas mood="happy" size={96} />
        <section aria-labelledby={labelId} className="lk-hero w-full" aria-busy={!summary.data}>
          <h1 id={labelId} className="lk-hero-label text-[13px]">
            {t("spent_label")}
          </h1>
          {summary.data && (
            <>
              <p className="lk-hero-amount">
                <Money cents={summary.data.spent} currency={currency} animate />
              </p>
              {summary.data.budgetTotal > 0 && (
                <p className="lk-hero-meta">
                  {t("of_budget", {
                    amount: formatMoney(summary.data.budgetTotal, currency, locale),
                  })}
                </p>
              )}
            </>
          )}
        </section>
      </main>
    </div>
  );
}
