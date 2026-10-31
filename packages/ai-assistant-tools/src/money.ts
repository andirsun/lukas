import { ToolError } from "./errors.ts";
import type { Profile } from "./lukitas.ts";

/**
 * Every amount is stored in hundredths of the currency, whatever its ISO exponent (COP too): core,
 * the API and the web all use 100.
 */
const MINOR_UNIT = 100;

/** Currencies shown without decimals; stored in hundredths like the rest. */
const WHOLE_UNIT_CURRENCIES = new Set(["COP", "CLP"]);

/**
 * An amount as the model sends it (currency units, maybe with decimals, maybe signed by mistake)
 * in signed minor units: rounded to hundredths, negative for expenses. The sign comes from `kind`
 * alone, so "-18000" for an expense does not turn into income.
 */
export function toMinor(amount: number, kind: "expense" | "income"): number {
  const minor = Math.round(Math.abs(amount) * MINOR_UNIT);
  if (!Number.isSafeInteger(minor) || minor === 0) {
    throw new ToolError(
      "invalid_amount",
      `The amount must be a number above zero, in currency units (got ${amount})`,
    );
  }
  return kind === "expense" ? -minor : minor;
}

/** Minor units back to currency units for a structured answer, without the sign: 1800000 → 18000. */
export function fromMinor(minor: number): number {
  return Math.abs(minor) / MINOR_UNIT;
}

/** `pt` alone is Brazilian in CLDR; Lukitas writes European Portuguese, and Italy's Italian. */
function intlTag(locale: Profile["locale"]): string {
  return locale === "it" ? "it-IT" : locale === "pt" ? "pt-PT" : locale;
}

/**
 * Formats signed minor units the way the web does ("$18.000" for pesos in Spanish, "562,92 €"),
 * except the minus: a plain hyphen here, since this text is read by a model, not laid out.
 */
export function formatMoney(minor: number, currency: string, locale: Profile["locale"]): string {
  // Colombians write pesos as "$18.000": es-CO with the narrow symbol, scoped to COP. In English
  // the code stays, because "$18,000" would read as dollars.
  const colombian = currency === "COP" && locale === "es";
  const format = new Intl.NumberFormat(colombian ? "es-CO" : intlTag(locale), {
    style: "currency",
    currency,
    ...(colombian ? { currencyDisplay: "narrowSymbol" as const } : {}),
    ...(WHOLE_UNIT_CURRENCIES.has(currency)
      ? { minimumFractionDigits: 0, maximumFractionDigits: 0 }
      : {}),
    signDisplay: "negative",
  });
  const text = format.format(minor / MINOR_UNIT).replaceAll("−", "-");
  // es-CO puts a (non-breaking) space after the symbol.
  return colombian ? text.replace(/\$\s/, "$") : text;
}
