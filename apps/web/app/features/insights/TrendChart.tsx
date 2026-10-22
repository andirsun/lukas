import type { Month } from "@lukas/core";
import { lazy, Suspense } from "react";
import { useTranslations } from "use-intl";
import { formatMoney } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { durationToken, useReducedMotionPreference } from "../../ui/motion-tokens.ts";
import type { TrendPoint } from "./charts.tsx";
import { monthLabel, type Period, shortMonth } from "./insights-model.ts";
import { capitalize, InsightCard, Loading, SrTable, usePeriodPhrase } from "./parts.tsx";

const TrendBars = lazy(() => import("./charts.tsx").then((m) => ({ default: m.TrendBars })));

/** The chart's height, in px. */
const HEIGHT = 190;

export interface Trend {
  months: { month: string; income: number; expenses: number; budget: number }[];
}

export interface TrendChartProps {
  /** One entry per month of `period`, oldest first; undefined while loading. */
  data: Trend | undefined;
  stale: boolean;
  period: Period;
  current: Month;
  currency: string;
  order: number;
}

/**
 * Month by month (spec §2.7): income and spending as bars that rise from the axis, the budget as
 * a dashed line, over the last six months up to the one on screen (a year for a year). Tapping a
 * month shows its figures; screen readers get them as a table. With no transactions in those
 * months it says so instead of drawing empty bars.
 */
export function TrendChart({ data, stale, period, current, currency, order }: TrendChartProps) {
  const t = useTranslations("insights.trend");
  const { locale } = useLocale();
  const reduce = useReducedMotionPreference();
  const phrase = usePeriodPhrase(locale, current)(period);
  const money = (cents: number) => formatMoney(cents, currency, locale);
  const months = data?.months ?? [];
  const empty = months.every((m) => m.income === 0 && m.expenses === 0);
  const name = (month: Month) => capitalize(monthLabel(month, current, locale), locale);

  const points: TrendPoint[] = months.map((m) => ({
    ...m,
    label: shortMonth(m.month, locale),
  }));

  return (
    <InsightCard
      title={t("title")}
      subtitle={capitalize(phrase, locale)}
      order={order}
      busy={stale}
    >
      {!data ? (
        <Loading height={HEIGHT + 28} />
      ) : empty ? (
        <p className="m-0 py-(--space-4) text-center text-[15px] font-bold text-ink-muted">
          {t("empty", { period: phrase })}
        </p>
      ) : (
        <>
          <ul
            aria-hidden="true"
            className="m-0 flex list-none flex-wrap gap-x-(--space-4) gap-y-(--space-1) p-0 text-[12px] font-extrabold text-ink-muted"
          >
            <li className="flex items-center gap-(--space-1)">
              <span className="lk-swatch bg-good" />
              {t("income")}
            </li>
            <li className="flex items-center gap-(--space-1)">
              <span className="lk-swatch bg-over" />
              {t("expenses")}
            </li>
            {months.some((m) => m.budget > 0) && (
              <li className="flex items-center gap-(--space-1)">
                <span className="lk-swatch-line" />
                {t("budget")}
              </li>
            )}
          </ul>
          <div
            aria-hidden="true"
            data-animated={String(!reduce)}
            className="-mx-(--space-1)"
            style={{ height: HEIGHT }}
          >
            <Suspense fallback={<Loading height={HEIGHT} />}>
              <TrendBars
                points={points}
                height={HEIGHT}
                animate={!reduce}
                durationMs={Math.round(durationToken("--hop") * 1000)}
                tooltip={(point) => (
                  <div className="lk-chart-tip">
                    <p className="m-0 font-display text-[14px] font-semibold text-ink">
                      {name(point.month)}
                    </p>
                    <p className="m-0">
                      {t("income")}: <span className="lk-num text-ink">{money(point.income)}</span>
                    </p>
                    <p className="m-0">
                      {t("expenses")}:{" "}
                      <span className="lk-num text-ink">{money(point.expenses)}</span>
                    </p>
                    {point.budget > 0 && (
                      <p className="m-0">
                        {t("budget")}:{" "}
                        <span className="lk-num text-ink">{money(point.budget)}</span>
                      </p>
                    )}
                  </div>
                )}
              />
            </Suspense>
          </div>
          <SrTable
            caption={t("caption", { period: phrase })}
            head={[t("col_month"), t("income"), t("expenses"), t("budget")]}
            rows={months.map((m) => ({
              key: m.month,
              cells: [name(m.month), money(m.income), money(m.expenses), money(m.budget)],
            }))}
          />
        </>
      )}
    </InsightCard>
  );
}
