import { InvalidAmountError } from "@lukas/core";
import { type Locale, parseAmountInput } from "../../i18n/format.ts";

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
