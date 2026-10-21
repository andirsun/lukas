import { SUPPORTED_CURRENCIES, type SupportedCurrency } from "@lukas/core";

/** Countries of Europe (the EU, the EEA, the UK, Switzerland and the Balkans): their default is EUR. */
const EUROPE = new Set([
  "AD",
  "AL",
  "AT",
  "BA",
  "BE",
  "BG",
  "CH",
  "CY",
  "CZ",
  "DE",
  "DK",
  "EE",
  "ES",
  "FI",
  "FR",
  "GB",
  "GR",
  "HR",
  "HU",
  "IE",
  "IS",
  "IT",
  "LI",
  "LT",
  "LU",
  "LV",
  "MC",
  "MD",
  "ME",
  "MK",
  "MT",
  "NL",
  "NO",
  "PL",
  "PT",
  "RO",
  "RS",
  "SE",
  "SI",
  "SK",
  "SM",
  "UA",
  "VA",
  "XK",
]);

function regionOf(tag: string): string | undefined {
  try {
    return new Intl.Locale(tag).region;
  } catch {
    return undefined;
  }
}

/**
 * The currency a new account starts with (founder's rule, 2026-10-21), from the browser's languages
 * (`navigator.languages`) and time zone:
 * - Colombia (any language's region is CO, or the zone is America/Bogota) → COP;
 * - Europe (the first language's region is European, or the zone is Europe/*) → EUR;
 * - anywhere else → USD: the rest of Latin America (MX, AR, CL, PE…), a bare `es` in an America/*
 *   zone, the US, and anyone we can't place.
 * The account's currency locks at its first transaction, so a wrong euro for a peso earner would
 * stick: USD is the safer unknown.
 */
export function defaultCurrency(
  languages: readonly string[],
  timeZone: string | undefined,
): SupportedCurrency {
  const regions = languages.map(regionOf).filter((r): r is string => r !== undefined);
  if (regions.includes("CO") || timeZone === "America/Bogota") return "COP";
  const first = regions[0];
  if ((first && EUROPE.has(first)) || timeZone?.startsWith("Europe/")) return "EUR";
  return "USD";
}

export function isSupportedCurrency(code: string | null | undefined): code is SupportedCurrency {
  return (SUPPORTED_CURRENCIES as readonly string[]).includes(code ?? "");
}
