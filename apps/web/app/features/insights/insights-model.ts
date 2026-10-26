import { addMonths, type Month } from "@lukas/core";
import { formatMonth, intlTag, type Locale, monthInSentence } from "../../i18n/format.ts";

/** How many months the insights look at, ending at the month on screen. */
export const SPANS = [1, 3, 6, 12] as const;
export type Span = (typeof SPANS)[number];

export function isSpan(value: number): value is Span {
  return (SPANS as readonly number[]).includes(value);
}

/** A run of whole months, both ends included. */
export interface Period {
  from: Month;
  to: Month;
}

/** The `span` months ending at `end`. */
export function periodOf(end: Month, span: Span): Period {
  return { from: addMonths(end, 1 - span), to: end };
}

/** The trend covers the span on screen, the same months as the donut (founder, 2026-10-22). */
export function trendPeriod(end: Month, span: Span): Period {
  return periodOf(end, span);
}

/** How many complete months "¿Cuánto me cuesta vivir?" averages at most. */
export const LIVING_MONTHS = 6;

/** The last `LIVING_MONTHS` complete months before `current`. */
export function livingPeriod(current: Month): Period {
  const to = addMonths(current, -1);
  return { from: addMonths(to, 1 - LIVING_MONTHS), to };
}

/**
 * How many of those months to average: from the first one with any transaction up to the last
 * complete month, so a short history is not divided by months that had nothing in them (a person
 * who started in September has one complete month in October, not six). 0 when none has any.
 * `months` is the trend of `livingPeriod`, oldest first.
 */
export function livingWindow(months: { income: number; expenses: number }[]): number {
  const first = months.findIndex((m) => m.income !== 0 || m.expenses !== 0);
  return first === -1 ? 0 : months.length - first;
}

/** A month mid-sentence, with its year when it is not the current one's: `octubre`, `diciembre de 2025`. */
export function monthLabel(month: Month, current: Month, locale: Locale): string {
  const year = month.slice(0, 4);
  const sameYear = year === current.slice(0, 4);
  if (locale === "es" || locale === "pt")
    return sameYear
      ? monthInSentence(month, locale)
      : `${monthInSentence(month, locale)} de ${year}`;
  return sameYear ? formatMonth(month, locale) : `${formatMonth(month, locale)} ${year}`;
}

/** A share of the total (0.5944) as a percentage with at most one decimal: `59,4 %`, `59.4%`. */
export function formatShare(share: number, locale: Locale): string {
  return new Intl.NumberFormat(intlTag(locale), {
    style: "percent",
    maximumFractionDigits: 1,
  }).format(share);
}

/** A month's short name for an axis: `oct`, `Oct`. */
export function shortMonth(month: Month, locale: Locale): string {
  return new Intl.DateTimeFormat(intlTag(locale), { month: "short", timeZone: "UTC" })
    .format(new Date(`${month}-01T00:00:00Z`))
    .replace(/\.$/, "");
}

/** The part of a whole that `value` is, for bars: between 0 and 1, and 0 when there is no whole. */
export function fraction(value: number, whole: number): number {
  if (whole <= 0 || value <= 0) return 0;
  return Math.min(1, value / whole);
}

/**
 * Each total's share of their sum, rounded to a tenth of a percent so the shown shares add up to
 * exactly 100 % (largest remainder: round all down, then give the tenths left over to the ones
 * that lost the most). Returned as fractions (0.594) for `formatShare`; all 0 when the sum is not
 * positive.
 */
export function sharesOf(totals: number[]): number[] {
  const sum = totals.reduce((acc, t) => acc + Math.max(t, 0), 0);
  if (sum <= 0) return totals.map(() => 0);
  const exact = totals.map((t) => (Math.max(t, 0) / sum) * 1000);
  const tenths = exact.map(Math.floor);
  let left = 1000 - tenths.reduce((acc, t) => acc + t, 0);
  const order = exact
    .map((value, index) => ({ index, remainder: value - Math.floor(value) }))
    .sort((a, b) => b.remainder - a.remainder || a.index - b.index);
  for (const { index } of order) {
    if (left <= 0) break;
    tenths[index] = (tenths[index] ?? 0) + 1;
    left -= 1;
  }
  return tenths.map((t) => t / 1000);
}

/**
 * An amount (in hundredths) for a chart's axis, short and in the locale's words: `6 mil`,
 * `1,2 M` (es); `6k`, `1.2M` (en). No currency: the axis sits next to full amounts.
 */
export function compactAmount(cents: number, locale: Locale): string {
  const text = new Intl.NumberFormat(intlTag(locale), {
    notation: "compact",
    maximumFractionDigits: 1,
  }).format(cents / 100);
  return locale === "en" ? text.replace(/K$/, "k") : text;
}
