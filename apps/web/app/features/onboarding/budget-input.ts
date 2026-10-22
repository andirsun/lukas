import { InvalidAmountError } from "@lukas/core";
import { formatAmountInput, type Locale, parseAmountInput } from "../../i18n/format.ts";
import {
  type AmountFormat,
  decimalSeparator,
  MAX_WHOLE,
  takesDecimals,
} from "../../ui/keypad-input.ts";

/** Whole numbers grouped by thousands, with optional decimals: es `1.250.000,50`, en `1,250,000.50`. */
const GROUPED: Record<Locale, RegExp> = {
  es: /^\d{1,3}(\.\d{3})+(,\d{1,2})?$/,
  en: /^\d{1,3}(,\d{3})+(\.\d{1,2})?$/,
};

/**
 * A budget as typed, in hundredths like every stored amount (`300.000` pesos → 30.000.000), or
 * null when the field is empty (no budget). Besides what `parseAmountInput` takes, it accepts
 * thousands separators (people write pesos as `300.000`) and a currency sign or spaces around the
 * number. Anything else, negatives included, throws `InvalidAmountError`.
 */
export function parseBudgetInput(text: string, locale: Locale): number | null {
  const bare = text.replace(/[\s$€]/g, "");
  if (bare === "") return null;
  const grouping = locale === "es" ? "." : ",";
  const ungrouped = GROUPED[locale].test(bare) ? bare.replaceAll(grouping, "") : bare;
  if (ungrouped.startsWith("-")) throw new InvalidAmountError(text);
  return parseAmountInput(ungrouped, locale);
}

/** Currencies people count in thousands; the example shows a round thousand amount. */
const THOUSANDS = new Set(["COP", "CLP", "ARS"]);

/** A valid example for the "type just the number" hint, in the way people write that currency. */
export function budgetExample(currency: string, locale: Locale): string {
  if (!THOUSANDS.has(currency)) return "300";
  return locale === "es" ? "300.000" : "300,000";
}

/** A stored amount as the field shows it: `300.000`, `35,89` (es) or `300,000`, `35.89` (en). */
export function draftFromCents(cents: number, locale: Locale): string {
  const whole = cents % 100 === 0;
  return new Intl.NumberFormat(locale, {
    minimumFractionDigits: whole ? 0 : 2,
    maximumFractionDigits: 2,
  }).format(cents / 100);
}

/** Digits only. */
const digitsOf = (text: string) => text.replace(/\D/g, "");

/**
 * A budget field as it is typed, formatted like the keypad's amount (`300000` → `300.000` in
 * es-CO, `1250.5` → `1,250.5` in en): the thousands separators are put in for the person, any
 * they typed are read as grouping, the locale's decimal separator starts at most two decimals
 * (none for pesos), and anything else is dropped, as on the keypad. `caret` is the cursor in the
 * typed text; the result's caret sits after the same digit in the formatted text.
 */
export function formatBudgetTyping(
  text: string,
  caret: number,
  format: Required<AmountFormat>,
): { text: string; caret: number } {
  const separator = decimalSeparator(format.locale);
  const cut = text.indexOf(separator);
  const decimal = cut >= 0 && takesDecimals(format.currency);
  const wholeDigits = digitsOf(cut >= 0 ? text.slice(0, cut) : text)
    .replace(/^0+(?=\d)/, "")
    .slice(0, String(MAX_WHOLE).length);
  if (wholeDigits === "" && !decimal) return { text: "", caret: 0 };
  const decimals = decimal ? digitsOf(text.slice(cut + 1)).slice(0, 2) : undefined;
  const raw = decimals === undefined ? wholeDigits : `${wholeDigits || "0"}${separator}${decimals}`;
  // The keypad's own formatting, without the currency sign and spaces.
  const formatted = formatAmountInput(raw, format.currency, format.locale).replace(/[^\d.,]/g, "");

  // The caret goes after as many digits as were before it (and after the decimal separator if
  // it was right after it).
  const before = text.slice(0, caret);
  const digitsBefore = digitsOf(before).length;
  let seen = 0;
  let at = 0;
  if (digitsBefore > 0) {
    for (; at < formatted.length; at++) {
      if (/\d/.test(formatted[at] as string)) seen += 1;
      if (seen === digitsBefore) {
        at += 1;
        break;
      }
    }
  }
  if (before.endsWith(separator) && formatted[at] === separator) at += 1;
  return { text: formatted, caret: Math.min(at, formatted.length) };
}
