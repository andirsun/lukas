import type { Month } from "@lukas/core";
import { motion } from "motion/react";
import { lazy, Suspense } from "react";
import { useTranslations } from "use-intl";
import type { ByCategoryReport } from "../../api/queries.ts";
import { formatMoney } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { categoryLook } from "../../ui/category-look.ts";
import { Money } from "../../ui/Money.tsx";
import { durationToken, useReducedMotionPreference } from "../../ui/motion-tokens.ts";
import { SegmentedControl } from "../../ui/SegmentedControl.tsx";
import { formatShare, type Period, sharesOf } from "./insights-model.ts";
import {
  capitalize,
  InsightCard,
  Loading,
  SrTable,
  tileGround,
  useMarkColor,
  usePeriodPhrase,
} from "./parts.tsx";

const DonutChart = lazy(() => import("./charts.tsx").then((m) => ({ default: m.DonutChart })));

/** The donut's size, in px. */
const SIZE = 200;

export type Kind = "expense" | "income";
export type StatusFilter = "all" | "paid" | "pending";

export interface CategoryDonutProps {
  /**
   * Totals per category with the range, kind and status they answer; undefined while the first
   * one loads. Every label comes from `data.range`, so while another answer loads (`stale`) the
   * card keeps saying what its figures are.
   */
  data: ByCategoryReport | undefined;
  /** An older answer is on screen while the new one loads: the card dims and says it is busy. */
  stale: boolean;
  kind: Kind;
  onKind(kind: Kind): void;
  status: StatusFilter;
  onStatus(status: StatusFilter): void;
  /** The period asked for: the subtitle until the first answer lands. */
  period: Period;
  current: Month;
  currency: string;
  order: number;
  className?: string;
}

/**
 * Where the money went (or came from) in the period, by category (spec §2.7): spending or
 * income, all, paid or pending. A donut in the categories' tints with the total in its hole
 * (its sectors sweep in), and a legend with each category's share and amount (its bar grows);
 * screen readers get the same as a table. With nothing to show it says so in words.
 */
export function CategoryDonut({
  data,
  stale,
  kind,
  onKind,
  status,
  onStatus,
  period,
  current,
  currency,
  order,
  className,
}: CategoryDonutProps) {
  const t = useTranslations("insights.donut");
  const { locale } = useLocale();
  const reduce = useReducedMotionPreference();
  const markColor = useMarkColor();
  // What the figures on screen are: the answer's own range, kind and status.
  const shownKind: Kind = data?.range.kind ?? kind;
  const shownStatus: StatusFilter = data ? (data.range.status ?? "all") : status;
  const phrase = usePeriodPhrase(locale, current)(data?.range ?? period);
  const what = t(`what_${shownKind}_${shownStatus}`);
  const money = (cents: number) => formatMoney(cents, currency, locale);
  const items = data?.items ?? [];
  const shares = sharesOf(items.map((item) => item.total));
  const durationMs = Math.round(durationToken("--hop") * 1000);

  return (
    <InsightCard
      title={t("title")}
      subtitle={capitalize(phrase, locale)}
      order={order}
      busy={stale}
      className={className}
      controls={
        <div className="flex flex-col gap-(--space-2)">
          <SegmentedControl<Kind>
            label={t("kind_label")}
            value={kind}
            options={[
              { value: "expense", label: t("expense") },
              { value: "income", label: t("income") },
            ]}
            onChange={onKind}
          />
          <SegmentedControl<StatusFilter>
            label={t("status_label")}
            value={status}
            options={[
              { value: "all", label: t("all") },
              { value: "paid", label: t("paid") },
              { value: "pending", label: t("pending") },
            ]}
            onChange={onStatus}
          />
        </div>
      }
    >
      {!data ? (
        <Loading height={SIZE} />
      ) : items.length === 0 ? (
        <p className="m-0 py-(--space-4) text-center text-[15px] font-bold text-ink-muted">
          {t("empty", { what: what.toLocaleLowerCase(locale), period: phrase })}
        </p>
      ) : (
        <>
          <figure
            aria-hidden="true"
            data-animated={String(!reduce)}
            className="relative m-0 self-center"
            style={{ width: SIZE, height: SIZE }}
          >
            <Suspense fallback={<span className="lk-donut-placeholder" />}>
              <DonutChart
                size={SIZE}
                slices={items.map((item) => ({
                  id: item.categoryId,
                  value: item.total,
                  fill: markColor(categoryLook(item).tint),
                }))}
                animate={!reduce}
                durationMs={durationMs}
              />
            </Suspense>
            <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center text-center">
              <span className="text-[11px] font-extrabold uppercase tracking-[0.06em] text-ink-muted">
                {t(shownKind === "expense" ? "center_expense" : "center_income")}
              </span>
              <span data-testid="donut-total">
                <Money
                  cents={data.total}
                  currency={currency}
                  animate
                  countFrom={0}
                  className="font-display text-[18px] font-bold text-ink"
                />
              </span>
            </div>
          </figure>

          <ol
            data-testid="donut-legend"
            aria-hidden="true"
            className="m-0 flex list-none flex-col gap-(--space-3) p-0"
          >
            {items.map((item, index) => {
              const { glyph, tint } = categoryLook(item);
              return (
                <motion.li
                  key={item.categoryId}
                  className="flex items-center gap-(--space-3)"
                  initial={reduce ? { opacity: 0 } : { opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{
                    duration: durationToken("--sheet"),
                    delay: reduce ? 0 : Math.min(index, 8) * 0.04,
                    ease: "easeOut",
                  }}
                >
                  <span className="lk-tile" style={{ background: tileGround(tint) }}>
                    {glyph}
                  </span>
                  <span className="flex min-w-0 flex-1 flex-col gap-1">
                    <span className="flex items-baseline justify-between gap-(--space-2)">
                      <span className="truncate text-[14px] font-extrabold text-ink">
                        {item.name}
                      </span>
                      <span className="lk-amount text-ink">{money(item.total)}</span>
                    </span>
                    <span className="flex items-center gap-(--space-2)">
                      <span className="lk-bar lk-bar-sm flex-1">
                        <motion.span
                          style={{
                            width: `${Math.max((shares[index] ?? 0) * 100, 1)}%`,
                            background: markColor(tint),
                            transformOrigin: "left",
                          }}
                          initial={reduce ? false : { scaleX: 0 }}
                          animate={{ scaleX: 1 }}
                          transition={{
                            duration: durationToken("--hop"),
                            delay: Math.min(index, 8) * 0.04,
                            ease: "easeOut",
                          }}
                        />
                      </span>
                      <span className="w-[4.5em] text-right text-[12px] font-extrabold text-ink-muted tabular-nums">
                        {formatShare(shares[index] ?? 0, locale)}
                      </span>
                    </span>
                  </span>
                </motion.li>
              );
            })}
          </ol>

          <SrTable
            caption={t("caption", { what, period: phrase })}
            head={[t("col_category"), t("col_share"), t("col_amount")]}
            rows={items.map((item, index) => ({
              key: item.categoryId,
              cells: [item.name, formatShare(shares[index] ?? 0, locale), money(item.total)],
            }))}
            foot={[{ key: "total", cells: [t("total"), "", money(data.total)] }]}
          />
        </>
      )}
    </InsightCard>
  );
}
