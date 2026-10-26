import { InvalidAmountError, type IsoDate, type Month, parseDecimalToMinor } from "@lukas/core";

export type Locale = "es" | "en" | "it" | "pt";

export const DEFAULT_LOCALE: Locale = "es";

/** Every locale, Spanish (the default) first. */
export const LOCALES: readonly Locale[] = ["es", "en", "it", "pt"];

/** Whether a value is one of the app's locales. */
export const isLocale = (value: unknown): value is Locale =>
  typeof value === "string" && (LOCALES as readonly string[]).includes(value);

/** Languages that write the decimal comma (and so group with a point or a space). */
const decimalComma = (locale: Locale) => locale !== "en";

/**
 * The tag `Intl` formats with. A bare `pt` is Brazilian in CLDR (`€ 1.234,50`); Lukitas writes
 * European Portuguese (`1234,50 €`), and `it` is Italy's Italian.
 */
export function intlTag(locale: string): string {
  return locale === "it" ? "it-IT" : locale === "pt" ? "pt-PT" : locale;
}

const MINUS = "−";

/** `es*` maps to Spanish, `it*` to Italian, `pt*` (Brazil too) to Portuguese, the rest to English. */
export function detectLocale(navigatorLanguage: string | undefined): Locale {
  const language = navigatorLanguage?.toLowerCase().split(/[-_]/)[0];
  return language === "es" || language === "it" || language === "pt" ? language : "en";
}

/** Public pages: `/en`, `/it` and `/pt` (and below) have their language, everything else is Spanish. */
export function localeFromPathname(pathname: string): Locale {
  for (const locale of ["en", "it", "pt"] as const) {
    if (pathname === `/${locale}` || pathname.startsWith(`/${locale}/`)) return locale;
  }
  return "es";
}

/**
 * Every amount is stored in hundredths of the currency, whatever the currency's own ISO exponent:
 * `parseDecimalToMinor` and `formatMinorAsDecimal` in core, the importer and the API all use 100.
 * So 50.000 COP is stored as 5.000.000. Dividing by `Intl`'s own digit count instead would show
 * COP 100x too large, and that count is not even stable: it is 2 or 0 depending on the ICU
 * version of the browser or Node.
 */
const MINOR_UNIT = 100;

/** Currencies shown without decimals; stored in hundredths like the rest. */
const WHOLE_UNIT_CURRENCIES = new Set(["COP", "CLP"]);

/** Whether a currency is counted in whole units only (no cents to type or show): COP, CLP. */
export function isWholeUnit(currency: string): boolean {
  return WHOLE_UNIT_CURRENCIES.has(currency);
}

/** The formatter `formatMoney` uses for a currency and locale (before its own fix-ups). */
function moneyFormat(
  currency: string,
  locale: Locale,
  extra: Intl.NumberFormatOptions = {},
): { format: Intl.NumberFormat; colombian: boolean } {
  // Colombians write pesos as "$50.000": `es-CO` with the narrow symbol, scoped to COP so the
  // other currencies keep the plain `es` conventions (EUR stays "562,92 €"). In English the COP
  // code stays, because "$50,000" would read as dollars.
  const colombian = currency === "COP" && locale === "es";
  const format = new Intl.NumberFormat(colombian ? "es-CO" : intlTag(locale), {
    style: "currency",
    currency,
    ...(colombian ? { currencyDisplay: "narrowSymbol" as const } : {}),
    ...(WHOLE_UNIT_CURRENCIES.has(currency)
      ? { minimumFractionDigits: 0, maximumFractionDigits: 0 }
      : {}),
    ...extra,
  });
  return { format, colombian };
}

/** `es-CO` puts a (non-breaking) space after the symbol; the spec writes "$50.000". */
const tightPeso = (text: string, colombian: boolean) =>
  colombian ? text.replace(/\$\s/, "$") : text;

/**
 * Formats integer minor units (hundredths). Negatives use the real minus sign (U+2212) rather
 * than the hyphen-minus `Intl` emits, so "−6,08 €" never breaks or reads as a dash.
 */
export function formatMoney(
  cents: number,
  currency: string,
  locale: Locale,
  opts: { sign?: "auto" | "always" } = {},
): string {
  const { format, colombian } = moneyFormat(currency, locale, {
    signDisplay: opts.sign === "always" ? "exceptZero" : "negative",
  });
  return tightPeso(format.format(cents / MINOR_UNIT).replaceAll("-", MINUS), colombian);
}

/**
 * What is being typed on the keypad (`6,0`, raw, in the locale's decimal separator) shown as
 * money, the way `formatMoney` writes it (`6,0 €`, `$50.000`, `€6.5`): the whole part is grouped
 * and the decimals stay exactly as typed, a trailing separator or zero included. Empty is 0.
 */
export function formatAmountInput(raw: string, currency: string, locale: Locale): string {
  const separator = decimalComma(locale) ? "," : ".";
  const [whole = "", decimals] = raw.split(separator);
  const { format, colombian } = moneyFormat(currency, locale, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  });
  let text = "";
  let placed = false;
  const parts = format.formatToParts(Number(whole || "0"));
  parts.forEach((part, index) => {
    text += part.value;
    const lastNumber =
      (part.type === "integer" || part.type === "group") &&
      !parts.slice(index + 1).some((p) => p.type === "integer");
    if (lastNumber && decimals !== undefined && !placed) {
      text += separator + decimals;
      placed = true;
    }
  });
  return tightPeso(text, colombian);
}

/**
 * The "lukas hint" for COP: 1 luka = $1.000 and 1 palo = $1.000.000 (es), "k" and "M" (en).
 * `cents` is the stored amount, as `formatMoney` takes it. Returns `null` for any other currency
 * and under 1.000 pesos. Lukas show at most one decimal, palos at most two; the palos
 * threshold applies after rounding, so 999.990 pesos is "1 palo". The sign is ignored.
 */
export function lukasHint(cents: number, currency: string, locale: Locale): string | null {
  // The slang is Colombian Spanish (and its k/M in English); Italian and Portuguese have none.
  if (currency !== "COP" || locale === "it" || locale === "pt") return null;
  const abs = Math.abs(cents);
  if (abs < 1000 * MINOR_UNIT) return null;

  // Integer divisions only: tenths of a luka (pesos / 100) and hundredths of a palo (pesos / 10.000).
  const lukaTenths = Math.round(abs / (100 * MINOR_UNIT));
  const number = new Intl.NumberFormat(locale, { maximumFractionDigits: 2 });
  if (lukaTenths < 10_000) {
    const lukas = lukaTenths / 10;
    return locale === "es"
      ? `${number.format(lukas)} ${lukas === 1 ? "luka" : "lukas"}`
      : `${number.format(lukas)}k`;
  }
  const palos = Math.round(abs / (10_000 * MINOR_UNIT)) / 100;
  return locale === "es"
    ? `${number.format(palos)} ${palos === 1 ? "palo" : "palos"}`
    : `${number.format(palos)}M`;
}

function utcDate(iso: string): Date {
  return new Date(`${iso}T00:00:00Z`);
}

/** Short weekday plus day of month: es `mié 21`, en `Wed 21`. */
export function formatDay(date: IsoDate, locale: Locale): string {
  const d = utcDate(date);
  const tag = intlTag(locale);
  const weekday = new Intl.DateTimeFormat(tag, { weekday: "short", timeZone: "UTC" })
    .format(d)
    .replace(/\.$/, "");
  const day = new Intl.DateTimeFormat(tag, { day: "numeric", timeZone: "UTC" }).format(d);
  return `${weekday} ${day}`;
}

/** Full month name, capitalized: es `Octubre`, en `October`. */
export function formatMonth(month: Month, locale: Locale): string {
  const name = new Intl.DateTimeFormat(intlTag(locale), { month: "long", timeZone: "UTC" }).format(
    utcDate(`${month}-01`),
  );
  return name.charAt(0).toLocaleUpperCase(locale) + name.slice(1);
}

/** A month's name mid-sentence: lowercase in Spanish, Italian and Portuguese (`desde octubre`), as is in English. */
export function monthInSentence(month: Month, locale: Locale): string {
  const name = formatMonth(month, locale);
  return locale === "en" ? name : name.toLocaleLowerCase(locale);
}

/**
 * Parses what a person types into an amount field, using the locale's decimal separator
 * (es `,`, en `.`). The other locale's separator is rejected rather than guessed at.
 */
export function parseAmountInput(text: string, locale: Locale): number {
  const trimmed = text.trim();
  const [decimal, other] = decimalComma(locale) ? [",", "."] : [".", ","];
  if (trimmed.includes(other)) throw new InvalidAmountError(text);
  return parseDecimalToMinor(trimmed.replace(decimal, "."));
}
