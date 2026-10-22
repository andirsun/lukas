import type { CategoryDto, Month } from "@lukas/core";
import { motion } from "motion/react";
import { useTranslations } from "use-intl";
import { useCostOfLiving, useTrend } from "../../api/queries.ts";
import { formatMoney } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { CATEGORY_TINTS, categoryLook } from "../../ui/category-look.ts";
import { cx } from "../../ui/cx.ts";
import { Money } from "../../ui/Money.tsx";
import { durationToken, useReducedMotionPreference } from "../../ui/motion-tokens.ts";
import { fraction, livingPeriod, livingWindow } from "./insights-model.ts";
import { InsightCard, Loading, SrTable, tileGround } from "./parts.tsx";

const tint = (name: string) => CATEGORY_TINTS.find((c) => c.name === name)?.value as string;
/** The split bar's two colors: category tint tokens (3:1 on the card in both themes). */
const FIXED_TINT = "var(--tint-indigo)";
const VARIABLE_TINT = "var(--tint-teal)";

export interface CostOfLivingProps {
  /** The current month in the person's time zone: the averages use the complete months before it. */
  current: Month;
  currency: string;
  /** Every category, archived ones too (past months can be in them). */
  categories: CategoryDto[] | undefined;
  order: number;
  className?: string;
}

/**
 * "¿Cuánto me cuesta vivir?" (spec §2.7, §4.2): what a normal month costs, as the average
 * monthly spending over the last six complete months, split into fixed (categories with a
 * recurrence) and variable, and per category. A short history is averaged over the months it
 * has (from the first complete month with transactions), not divided by six. Screen readers get
 * the figures as a table; without a complete month to go on, it says so.
 */
export function CostOfLiving({
  current,
  currency,
  categories,
  order,
  className,
}: CostOfLivingProps) {
  const t = useTranslations("insights.living");
  const { locale } = useLocale();
  const reduce = useReducedMotionPreference();
  const history = useTrend(livingPeriod(current));
  const months = history.data ? livingWindow(history.data.months) : undefined;
  const living = useCostOfLiving(months || 1, { enabled: months !== undefined && months > 0 });
  if (history.error && !history.data) throw history.error;
  if (living.error && !living.data) throw living.error;

  const money = (cents: number) => formatMoney(cents, currency, locale);
  const byId = new Map((categories ?? []).map((c) => [c.id, c]));
  const data = months ? living.data : undefined;
  const empty =
    months === 0 || (data !== undefined && (data.total <= 0 || data.categories.length === 0));
  const grow = (delay: number) => ({
    initial: reduce ? false : ({ scaleX: 0 } as const),
    animate: { scaleX: 1 },
    transition: { duration: durationToken("--hop"), delay, ease: "easeOut" as const },
  });
  const typeName = (type: "fixed" | "variable") =>
    t(type === "fixed" ? "type_fixed" : "type_variable");

  return (
    <InsightCard title={t("title")} order={order} className={className}>
      {empty ? (
        <p className="m-0 py-(--space-2) text-[15px] font-bold text-ink-muted">{t("empty")}</p>
      ) : !data || !categories ? (
        <Loading height={180} />
      ) : (
        <>
          <p className="m-0 text-[14px] font-bold text-ink-muted">
            {t("lead", { count: data.months })}
          </p>
          <p className="m-0 flex flex-wrap items-baseline gap-x-(--space-2)">
            <Money
              cents={data.total}
              currency={currency}
              animate
              countFrom={0}
              className="font-display text-[34px] font-bold leading-none text-ink"
            />{" "}
            <span className="text-[15px] font-extrabold text-ink-muted">{t("per_month")}</span>
          </p>

          <div
            data-testid="living-split"
            aria-hidden="true"
            className="flex flex-col gap-(--space-3)"
          >
            <div className="flex h-3.5 overflow-hidden rounded-(--radius-pill) bg-surface-sunken">
              <motion.span
                className="h-full"
                style={{
                  width: `${fraction(data.fixed, data.total) * 100}%`,
                  background: FIXED_TINT,
                  transformOrigin: "left",
                }}
                {...grow(0.1)}
              />
              <motion.span
                className="h-full"
                style={{
                  width: `${fraction(data.variable, data.total) * 100}%`,
                  background: VARIABLE_TINT,
                  transformOrigin: "left",
                }}
                {...grow(0.3)}
              />
            </div>
            <div className="grid grid-cols-2 gap-(--space-3)">
              {(
                [
                  ["fixed", data.fixed, FIXED_TINT],
                  ["variable", data.variable, VARIABLE_TINT],
                ] as const
              ).map(([type, cents, color]) => (
                <div key={type} className="flex min-w-0 flex-col gap-0.5">
                  <span className="flex items-center gap-(--space-1) text-[13px] font-extrabold text-ink">
                    <span className="lk-swatch" style={{ background: color }} />
                    {t(type)}
                  </span>
                  <span className="lk-amount text-[16px] text-ink">{money(cents)}</span>
                  <span className="text-[12px] font-bold text-ink-muted">{t(`${type}_hint`)}</span>
                </div>
              ))}
            </div>
          </div>

          <ul aria-hidden="true" className="m-0 flex list-none flex-col gap-(--space-2) p-0">
            {data.categories.map((row, index) => {
              const category = byId.get(row.categoryId);
              const look = category ? categoryLook(category) : { glyph: "🏷️", tint: tint("gray") };
              return (
                <motion.li
                  key={row.categoryId}
                  className="flex items-center gap-(--space-3)"
                  initial={reduce ? { opacity: 0 } : { opacity: 0, y: 6 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{
                    duration: durationToken("--sheet"),
                    delay: reduce ? 0 : Math.min(index, 10) * 0.03,
                    ease: "easeOut",
                  }}
                >
                  <span className="lk-tile" style={{ background: tileGround(look.tint) }}>
                    {look.glyph}
                  </span>
                  <span className="flex min-w-0 flex-1 flex-col">
                    <span className="truncate text-[14px] font-extrabold text-ink">
                      {category?.name ?? "—"}
                      {category?.archived && (
                        <span className="font-bold text-ink-muted"> · {t("archived")}</span>
                      )}
                    </span>
                    <span
                      className={cx(
                        "text-[12px] font-bold",
                        row.type === "fixed" ? "text-ink" : "text-ink-muted",
                      )}
                    >
                      {typeName(row.type)}
                    </span>
                  </span>
                  <span className="lk-amount text-ink">{money(row.average)}</span>
                </motion.li>
              );
            })}
          </ul>

          <SrTable
            caption={t("caption")}
            head={[t("col_category"), t("col_type"), t("col_average")]}
            rows={data.categories.map((row) => {
              const category = byId.get(row.categoryId);
              const name = category
                ? category.archived
                  ? `${category.name} (${t("archived")})`
                  : category.name
                : "—";
              return { key: row.categoryId, cells: [name, typeName(row.type), money(row.average)] };
            })}
            foot={[
              { key: "fixed", cells: [t("fixed"), "", money(data.fixed)] },
              { key: "variable", cells: [t("variable"), "", money(data.variable)] },
              { key: "total", cells: [t("total"), "", money(data.total)] },
            ]}
          />
        </>
      )}
    </InsightCard>
  );
}
