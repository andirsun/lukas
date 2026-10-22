import { type Month, monthOf, todayIn } from "@lukas/core";
import { useState } from "react";
import { useTranslations } from "use-intl";
import { useAllCategories, useMe, useReportByCategory, useTrend } from "../../api/queries.ts";
import { formatMoney } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { LukasBubble } from "../../ui/LukasBubble.tsx";
import { MonthPicker } from "../../ui/MonthPicker.tsx";
import { SegmentedControl } from "../../ui/SegmentedControl.tsx";
import { CategoryDonut, type Kind, type StatusFilter } from "./CategoryDonut.tsx";
import { CostOfLiving } from "./CostOfLiving.tsx";
import { isSpan, periodOf, SPANS, type Span, trendPeriod } from "./insights-model.ts";
import { usePeriodPhrase } from "./parts.tsx";
import { TrendChart } from "./TrendChart.tsx";

/**
 * Insights (`/app/insights`, spec §2.7): the month on screen (the person's current one first,
 * earlier ones browsable) or a run of months ending at it; Lukitas saying what took the biggest
 * bite; where the money went by category (CategoryDonut); income, spending and budget month by
 * month (TrendChart); and what living costs (CostOfLiving). One column on phones; on wide screens
 * the donut takes the left column and the trend and what living costs stack on the right.
 */
export function Insights() {
  const me = useMe().data;
  if (!me) throw new Error("Insights renders inside AppShell, which waits for the profile");
  const current = monthOf(todayIn(me.timezone));
  return <InsightsView key={me.id} current={current} currency={me.currency} />;
}

function InsightsView({ current, currency }: { current: Month; currency: string }) {
  const t = useTranslations("insights");
  const { locale } = useLocale();
  const [end, setEnd] = useState<Month>(current);
  const [span, setSpan] = useState<Span>(1);
  const [kind, setKind] = useState<Kind>("expense");
  const [status, setStatus] = useState<StatusFilter>("all");
  const period = periodOf(end, span);
  const trendRange = trendPeriod(end, span);

  const byCategory = useReportByCategory({
    ...period,
    kind,
    ...(status === "all" ? {} : { status }),
  });
  // Lukitas talks about the period's spending, whatever the donut shows.
  const spending = useReportByCategory({ ...period, kind: "expense" });
  const trend = useTrend(trendRange);
  const categories = useAllCategories();
  for (const query of [byCategory, spending, trend, categories]) {
    if (query.error && !query.data) throw query.error;
  }

  const phrase = usePeriodPhrase(locale, current)(period);
  const top = spending.data?.items[0];
  const line = !spending.data
    ? null
    : top
      ? t("lukas_top", {
          name: top.name,
          period: phrase,
          amount: formatMoney(top.total, currency, locale),
        })
      : t("lukas_empty", { period: phrase });

  return (
    <div className="mx-auto flex w-full max-w-[480px] flex-col gap-(--space-3) px-(--space-4) pt-(--space-3) lg:max-w-[1040px] lg:px-(--space-6) lg:pt-(--space-5)">
      <header className="flex flex-wrap items-center justify-between gap-x-(--space-2) gap-y-(--space-1)">
        <h1 className="m-0 font-display text-[28px] font-bold text-ink">{t("title")}</h1>
        <div className="order-last flex w-full justify-center min-[400px]:order-none min-[400px]:w-auto">
          <MonthPicker month={end} onChange={setEnd} max={current} />
        </div>
      </header>
      <div className="lg:max-w-[480px]">
        <SegmentedControl
          label={t("period_label")}
          value={String(span)}
          options={SPANS.map((s) => ({ value: String(s), label: t(`span_${s}`) }))}
          onChange={(value) => {
            const next = Number(value);
            if (isSpan(next)) setSpan(next);
          }}
        />
      </div>
      <main className="grid grid-cols-1 items-start gap-(--space-3) lg:grid-cols-2">
        <div className="min-h-[72px] lg:col-span-2 lg:max-w-[640px]">
          {line && <LukasBubble message={line} mood="happy" />}
        </div>
        <CategoryDonut
          className="lg:row-span-2"
          data={byCategory.data}
          stale={byCategory.isPlaceholderData}
          kind={kind}
          onKind={setKind}
          status={status}
          onStatus={setStatus}
          period={period}
          current={current}
          currency={currency}
          order={0}
        />
        <TrendChart
          data={trend.data}
          stale={trend.isPlaceholderData}
          period={trendRange}
          current={current}
          currency={currency}
          order={1}
        />
        <CostOfLiving
          current={current}
          currency={currency}
          categories={categories.data}
          order={2}
        />
      </main>
    </div>
  );
}
