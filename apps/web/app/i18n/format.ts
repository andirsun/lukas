import { InvalidAmountError, type IsoDate, type Month, parseDecimalToMinor } from "@lukas/core";

export type Locale = "es" | "en";

export const DEFAULT_LOCALE: Locale = "es";

const MINUS = "−";

/** `es*` maps to Spanish, anything else (or nothing) to English. */
export function detectLocale(navigatorLanguage: string | undefined): Locale {
  return navigatorLanguage?.toLowerCase().startsWith("es") ? "es" : "en";
}

/** Public pages: `/en` and `/en/...` are English, everything else is Spanish. */
export function localeFromPathname(pathname: string): Locale {
  return pathname === "/en" || pathname.startsWith("/en/") ? "en" : "es";
}

/**
 * Formats integer minor units. Negatives use the real minus sign (U+2212) rather than the
 * hyphen-minus `Intl` emits, so "−6,08 €" never breaks or reads as a dash.
 */
export function formatMoney(
  cents: number,
  currency: string,
  locale: Locale,
  opts: { sign?: "auto" | "always" } = {},
): string {
  const format = new Intl.NumberFormat(locale, {
    style: "currency",
    currency,
    signDisplay: opts.sign === "always" ? "exceptZero" : "negative",
  });
  const digits = format.resolvedOptions().maximumFractionDigits ?? 2;
  return format.format(cents / 10 ** digits).replaceAll("-", MINUS);
}

function utcDate(iso: string): Date {
  return new Date(`${iso}T00:00:00Z`);
}

/** Short weekday plus day of month: es `mié 21`, en `Wed 21`. */
export function formatDay(date: IsoDate, locale: Locale): string {
  const d = utcDate(date);
  const weekday = new Intl.DateTimeFormat(locale, { weekday: "short", timeZone: "UTC" })
    .format(d)
    .replace(/\.$/, "");
  const day = new Intl.DateTimeFormat(locale, { day: "numeric", timeZone: "UTC" }).format(d);
  return `${weekday} ${day}`;
}

/** Full month name, capitalized: es `Octubre`, en `October`. */
export function formatMonth(month: Month, locale: Locale): string {
  const name = new Intl.DateTimeFormat(locale, { month: "long", timeZone: "UTC" }).format(
    utcDate(`${month}-01`),
  );
  return name.charAt(0).toLocaleUpperCase(locale) + name.slice(1);
}

/**
 * Parses what a person types into an amount field, using the locale's decimal separator
 * (es `,`, en `.`). The other locale's separator is rejected rather than guessed at.
 */
export function parseAmountInput(text: string, locale: Locale): number {
  const trimmed = text.trim();
  const [decimal, other] = locale === "es" ? [",", "."] : [".", ","];
  if (trimmed.includes(other)) throw new InvalidAmountError(text);
  return parseDecimalToMinor(trimmed.replace(decimal, "."));
}
