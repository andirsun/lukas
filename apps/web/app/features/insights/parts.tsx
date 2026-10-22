import type { Month } from "@lukas/core";
import { motion } from "motion/react";
import { type ReactNode, useId } from "react";
import { useTranslations } from "use-intl";
import type { Locale } from "../../i18n/format.ts";
import { cx } from "../../ui/cx.ts";
import { durationToken, useReducedMotionPreference } from "../../ui/motion-tokens.ts";
import { monthLabel, type Period } from "./insights-model.ts";

/**
 * One section of the insights screen: a card (`lk-hero`) named by its heading, so it is a region
 * screen readers can jump to. It rises into place over `--sheet`, a beat after the one before it
 * (`order`); under reduced motion it only fades in.
 */
export function InsightCard({
  title,
  subtitle,
  order,
  busy = false,
  className,
  children,
}: {
  title: string;
  subtitle?: string | undefined;
  /** Its place on the screen, for the staggered entrance. */
  order: number;
  /** Showing an older answer while the new one loads. */
  busy?: boolean;
  className?: string;
  children: ReactNode;
}) {
  const id = useId();
  const reduce = useReducedMotionPreference();
  return (
    <motion.section
      aria-labelledby={id}
      aria-busy={busy || undefined}
      className={cx("lk-hero flex min-w-0 flex-col gap-(--space-3)", className)}
      initial={reduce ? { opacity: 0 } : { opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{
        duration: durationToken("--sheet"),
        delay: reduce ? 0 : order * 0.07,
        ease: "easeOut",
      }}
    >
      <div className="flex flex-col gap-(--space-1)">
        <h2 id={id} className="m-0 font-display text-[20px] font-bold leading-tight text-ink">
          {title}
        </h2>
        {subtitle && <p className="m-0 text-[13px] font-bold text-ink-muted">{subtitle}</p>}
      </div>
      {children}
    </motion.section>
  );
}

export interface TableRow {
  key: string;
  /** The first cell heads the row. */
  cells: string[];
}

/**
 * What a chart shows, as a table only screen readers get (`sr-only`): the chart and its visual
 * legend are hidden from them, so this is the one place they read the figures.
 */
export function SrTable({
  caption,
  head,
  rows,
  foot = [],
}: {
  caption: string;
  head: string[];
  rows: TableRow[];
  foot?: TableRow[];
}) {
  const line = (row: TableRow) => (
    <tr key={row.key}>
      {row.cells.map((cell, i) =>
        i === 0 ? (
          <th key={i} scope="row">
            {cell}
          </th>
        ) : (
          <td key={i}>{cell}</td>
        ),
      )}
    </tr>
  );
  return (
    <table className="sr-only">
      <caption>{caption}</caption>
      <thead>
        <tr>
          {head.map((cell) => (
            <th key={cell} scope="col">
              {cell}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>{rows.map(line)}</tbody>
      {foot.length > 0 && <tfoot>{foot.map(line)}</tfoot>}
    </table>
  );
}

/** A period mid-sentence: `en octubre`, `de agosto a octubre` (`in October`, `from August to October`). */
export function usePeriodPhrase(locale: Locale, current: Month) {
  const t = useTranslations("insights");
  return ({ from, to }: Period) =>
    from === to
      ? t("period_one", { month: monthLabel(to, current, locale) })
      : t("period_range", {
          from: monthLabel(from, current, locale),
          to: monthLabel(to, current, locale),
        });
}

/** The first letter in upper case, for a phrase that starts a line: `De agosto a octubre`. */
export function capitalize(text: string, locale: Locale): string {
  return text.charAt(0).toLocaleUpperCase(locale) + text.slice(1);
}

/** A tile's ground: the tint mixed into the sunken surface, so it reads in both themes. */
export const tileGround = (tint: string) =>
  `color-mix(in srgb, ${tint} 45%, var(--surface-sunken))`;

/** A placeholder of the right height while a section's figures load. */
export function Loading({ height }: { height: number }) {
  return <div className="rounded-(--radius-lg) bg-surface-sunken" style={{ height }} />;
}
