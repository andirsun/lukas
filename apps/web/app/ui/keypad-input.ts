import { isWholeUnit, type Locale, parseAmountInput } from "../i18n/format.ts";

/**
 * What the add sheet's amount accepts, as raw text in the locale (`6,08` es, `6.08` en), from the
 * keypad, a physical keyboard or a paste. Pure, so every rule is unit-tested. The rule above all:
 * an input that could be misread is never saved as a different amount.
 *
 * Typing:
 * - The locale's decimal separator (es `,`, en `.`) starts the decimals, at most two.
 * - The other separator is a thousands separator and is ignored: in Spanish `15.000` is 15000.
 * - Whole-unit currencies (COP, CLP) take no decimals: the decimal separator ends the amount, and
 *   nothing typed after it counts (`15.000,5` is 15000). The raw text keeps the separator so
 *   Backspace undoes it; `wholeAmount` and the display drop it.
 * - The amount is capped by value, at 999.999.999,99 (999.999.999 for whole-unit currencies).
 *
 * Pasting: see `pasteAmount`.
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

/**
 * The raw text as an amount: for whole-unit currencies, what comes before the decimal separator
 * (the separator only ends the amount); otherwise the text itself.
 */
export function wholeAmount(raw: string, { locale, currency }: AmountFormat): string {
  return takesDecimals(currency) ? raw : (raw.split(decimalSeparator(locale))[0] ?? "");
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
    if (decimals !== undefined) return value;
    // Pesos: the separator ends the amount (only after some digits, so it can be undone).
    if (!takesDecimals(currency)) return whole ? `${whole}${separator}` : value;
    return `${whole || "0"}${separator}`;
  }
  if (decimals !== undefined) {
    if (!takesDecimals(currency)) return value;
    return decimals.length < MAX_DECIMALS ? value + key.digit : value;
  }
  if (whole === "0" || whole === "") return key.digit;
  const next = whole + key.digit;
  return Number(next) <= MAX_WHOLE ? next : value;
}

/**
 * A physical key (`KeyboardEvent.key`) as a keypad key: digits, the locale's decimal separator and
 * Backspace. Null for anything else, the thousands separator included, so it is ignored.
 */
export function keyFromKeyboard(key: string, { locale }: AmountFormat): KeypadKey | null {
  if (/^[0-9]$/.test(key)) return { kind: "digit", digit: key };
  if (key === "Backspace") return { kind: "backspace" };
  if (key === decimalSeparator(locale)) return { kind: "decimal" };
  return null;
}

/** The value after typing `key` on a physical keyboard, or null when the key is not for the amount. */
export function typeOnKeypad(value: string, key: string, format: AmountFormat): string | null {
  const pressed = keyFromKeyboard(key, format);
  return pressed ? pressKey(value, pressed, format) : null;
}

/** Digits grouped by thousands separators: the first group 1–3 digits, the rest exactly 3. */
function wellGrouped(groups: string[]): boolean {
  return groups.every((group, index) =>
    index === 0 ? /^\d{1,3}$/.test(group) || groups.length === 1 : /^\d{3}$/.test(group),
  );
}

/**
 * A pasted amount (`$50.000`, `6,08 €`, `€1,234.56`, `US$ 1.250,75`) as raw keypad text, or null
 * when it is not one clear amount (no digits, several numbers such as a date, bad grouping, over
 * the cap). A sign, symbols, letters and spaces around the number are dropped.
 *
 * - Decimal currencies (EUR, USD), in either language: the last separator is the decimal one
 *   when it appears once and is followed by exactly 1–2 digits (`6.08`, `1,234.56`, `1.234,56`);
 *   otherwise every `.` and `,` is a thousands separator (`1.234`, `$ 50.000`).
 * - Whole-unit currencies (COP, CLP): the locale's decimal separator ends the amount, as when
 *   typing (es `50.000,50` is 50000); the other separator is a thousands separator.
 */
export function pasteAmount(text: string, format: AmountFormat): string | null {
  const numbers = (text.match(/[\d.,]+/g) ?? []).filter((run) => /\d/.test(run));
  if (numbers.length !== 1) return null;
  const run = (numbers[0] as string).replace(/^[.,]+|[.,]+$/g, "");
  const separator = decimalSeparator(format.locale);

  let whole: string;
  let decimals: string | undefined;
  if (!takesDecimals(format.currency)) {
    whole = run.split(separator)[0] ?? "";
  } else {
    const last = Math.max(run.lastIndexOf("."), run.lastIndexOf(","));
    const mark = last >= 0 ? (run[last] as string) : "";
    const tail = last >= 0 ? run.slice(last + 1) : "";
    const isDecimal = mark !== "" && run.split(mark).length === 2 && /^\d{1,2}$/.test(tail);
    whole = isDecimal ? run.slice(0, last) : run;
    decimals = isDecimal ? tail : undefined;
  }
  const groups = whole.split(/[.,]/);
  if (!wellGrouped(groups)) return null;
  const digits = groups.join("").replace(/^0+(?=\d)/, "") || "0";
  if (Number(digits) > MAX_WHOLE) return null;
  return decimals === undefined ? digits : `${digits}${separator}${decimals}`;
}

/**
 * Stored cents as keypad text in the locale (`26280` → `262,80`; `5000` → `50`). Whole-unit
 * currencies (COP) are rounded to whole pesos: the keypad never holds fractional pesos.
 */
export function keypadText(cents: number, locale: Locale, currency?: string): string {
  const abs = Math.abs(cents);
  if (currency && isWholeUnit(currency)) return String(Math.round(abs / 100));
  const whole = Math.floor(abs / 100);
  const rest = abs % 100;
  return rest === 0
    ? String(whole)
    : `${whole}${locale === "es" ? "," : "."}${String(rest).padStart(2, "0")}`;
}

/** The typed amount in cents, or 0 while it is empty or not a number yet. */
export function centsOf(raw: string, locale: Locale): number {
  if (!raw) return 0;
  try {
    return parseAmountInput(raw, locale);
  } catch {
    return 0;
  }
}

/** The keypad's text as cents (unsigned): whole pesos only for whole-unit currencies; 0 while empty. */
export function amountCents(raw: string, format: AmountFormat): number {
  return centsOf(wholeAmount(raw, format), format.locale);
}

/**
 * Whether pasted text is a negative amount (`-50.000`, `−6,08 €`): a minus sign before the first
 * digit. Forms that take only positive amounts refuse it instead of dropping the sign.
 */
export function pastedNegative(text: string): boolean {
  const beforeDigits = text.split(/\d/)[0] ?? "";
  return /[-−‐‑–]/.test(beforeDigits);
}
