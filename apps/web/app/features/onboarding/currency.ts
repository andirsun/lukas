import { SUPPORTED_CURRENCIES, type SupportedCurrency } from "@lukas/core";

/** Where each supported currency is used (COP, USD, EUR at launch); the euro for the eurozone. */
const BY_REGION: Record<string, SupportedCurrency> = {
  CO: "COP",
  US: "USD",
  ...Object.fromEntries(
    [
      "AT",
      "BE",
      "CY",
      "DE",
      "EE",
      "ES",
      "FI",
      "FR",
      "GR",
      "HR",
      "IE",
      "IT",
      "LT",
      "LU",
      "LV",
      "MT",
      "NL",
      "PT",
      "SI",
      "SK",
    ].map((region) => [region, "EUR" as const]),
  ),
};

/** New accounts start in euros (the API's default), and so does anyone we can't place. */
export const DEFAULT_CURRENCY: SupportedCurrency = "EUR";

function regionOf(tag: string): string | undefined {
  try {
    return new Intl.Locale(tag).region;
  } catch {
    return undefined;
  }
}

/**
 * The currency to preselect from the browser's languages (`navigator.languages`): the first one
 * that names a region we know (es-CO → COP, es-ES → EUR, en-US → USD), else EUR.
 */
export function currencyFromLanguages(languages: readonly string[]): SupportedCurrency {
  for (const tag of languages) {
    const region = regionOf(tag);
    const currency = region ? BY_REGION[region] : undefined;
    if (currency) return currency;
  }
  return DEFAULT_CURRENCY;
}

export function isSupportedCurrency(code: string | null | undefined): code is SupportedCurrency {
  return (SUPPORTED_CURRENCIES as readonly string[]).includes(code ?? "");
}
