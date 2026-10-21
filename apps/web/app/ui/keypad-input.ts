import { isWholeUnit, type Locale } from "../i18n/format.ts";

/**
 * What the add sheet's amount accepts, as raw text in the locale (`6,08` es, `6.08` en), from the
 * keypad, a physical keyboard or a paste. Pure, so every rule is unit-tested.
 *
 * - The locale's decimal separator (es `,`, en `.`) starts the decimals, at most two.
 * - The other separator is a thousands separator and is ignored: in Spanish `15.000` is 15000.
 * - Whole-unit currencies (COP, CLP) take no decimals at all: there are no fractional pesos.
 * - The amount is capped by value, at 999.999.999,99 (999.999.999 for whole-unit currencies).
 */

/** The largest whole part an amount can have. */
export const MAX_WHOLE = 999_999_999;
const MAX_DECIMALS = 2;

export type KeypadKey =
  | { kind: "digit"; digit: string }
  | { kind: "decimal" }
  | { kind: "backspace" };

export interface AmountFormat {
  locale: Locale;
  /** ISO 4217 code; without one, decimals are allowed. */
  currency?: string | undefined;
}

export function decimalSeparator(locale: Locale): string {
  return locale === "es" ? "," : ".";
}

/** Whether this amount takes decimals (and the keypad shows its decimal key). */
export function takesDecimals(currency: string | undefined): boolean {
  return !(currency && isWholeUnit(currency));
}

/** The value after pressing `key`, or the same value when the key does not apply. */
export function pressKey(
  value: string,
  key: KeypadKey,
  { locale, currency }: AmountFormat,
): string {
  const separator = decimalSeparator(locale);
  if (key.kind === "backspace") return value.slice(0, -1);
  const [whole = "", decimals] = value.split(separator);
  if (key.kind === "decimal") {
    if (!takesDecimals(currency) || decimals !== undefined) return value;
    return `${whole || "0"}${separator}`;
  }
  if (decimals !== undefined) {
    return decimals.length < MAX_DECIMALS ? value + key.digit : value;
  }
  if (whole === "0" || whole === "") return key.digit;
  const next = whole + key.digit;
  return Number(next) <= MAX_WHOLE ? next : value;
}

/**
 * A physical key (`KeyboardEvent.key`) as a keypad key: digits, the locale's decimal separator
 * (only when the currency takes decimals) and Backspace. Null for anything else, the thousands
 * separator included, so it is ignored.
 */
export function keyFromKeyboard(key: string, { locale, currency }: AmountFormat): KeypadKey | null {
  if (/^[0-9]$/.test(key)) return { kind: "digit", digit: key };
  if (key === "Backspace") return { kind: "backspace" };
  if (key === decimalSeparator(locale) && takesDecimals(currency)) return { kind: "decimal" };
  return null;
}

/** The value after typing `key` on a physical keyboard, or null when the key is not for the amount. */
export function typeOnKeypad(value: string, key: string, format: AmountFormat): string | null {
  const pressed = keyFromKeyboard(key, format);
  return pressed ? pressKey(value, pressed, format) : null;
}

/**
 * A pasted amount (`$50.000`, `50.000,50`, `€1,234.56`, `6,08 €`) as raw keypad text, or null
 * when it is not a usable amount (no digits, two decimal separators, more than two decimals, over
 * the cap). Symbols, letters, spaces and a sign are dropped; the thousands separator is ignored.
 * For whole-unit currencies the decimals are dropped, so no fractional pesos are ever stored.
 */
export function pasteAmount(text: string, { locale, currency }: AmountFormat): string | null {
  const separator = decimalSeparator(locale);
  const thousands = locale === "es" ? "." : ",";
  const kept = text
    .replace(/[^0-9.,]/g, "")
    .split(thousands)
    .join("");
  const parts = kept.split(separator);
  if (parts.length > 2) return null;
  const [rawWhole = "", decimals] = parts;
  if (!/\d/.test(kept)) return null;
  const whole = rawWhole.replace(/^0+(?=\d)/, "") || "0";
  if (Number(whole) > MAX_WHOLE) return null;
  if (decimals === undefined || decimals === "" || !takesDecimals(currency)) return whole;
  if (decimals.length > MAX_DECIMALS) return null;
  return `${whole}${separator}${decimals}`;
}
