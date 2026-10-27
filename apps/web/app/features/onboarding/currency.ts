import { defaultCurrencyFor, SUPPORTED_CURRENCIES, type SupportedCurrency } from "@lukas/core";

function regionOf(tag: string): string | undefined {
  try {
    return new Intl.Locale(tag).region;
  } catch {
    return undefined;
  }
}

function languageOf(tag: string): string | undefined {
  try {
    return new Intl.Locale(tag).language;
  } catch {
    return undefined;
  }
}

/**
 * The currency a new account starts with, from the browser's languages (`navigator.languages`) and
 * time zone. The rule itself is `defaultCurrencyFor` in @lukas/core (the API's guest sign-up uses
 * it too); this picks the region it reads: CO if any language names Colombia, else the first
 * language's region. So `es-CO` anywhere → COP, a European first language → EUR, and a bare `es`
 * in an America/* zone → USD.
 */
export function defaultCurrency(
  languages: readonly string[],
  timeZone: string | undefined,
): SupportedCurrency {
  const regions = languages.map(regionOf).filter((r): r is string => r !== undefined);
  // A bare Italian or Portuguese language reads as Italy or Portugal: euros (spec §2.3).
  const first = languages[0] ? languageOf(languages[0]) : undefined;
  const home = first === "it" ? "IT" : first === "pt" ? "PT" : undefined;
  const region = regions.includes("CO") ? "CO" : (regions[0] ?? home);
  return defaultCurrencyFor(timeZone ?? "", region);
}

export function isSupportedCurrency(code: string | null | undefined): code is SupportedCurrency {
  return (SUPPORTED_CURRENCIES as readonly string[]).includes(code ?? "");
}
