import type { SupportedCurrency } from "./currencies.ts";

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

/**
 * The currency a new account starts with (founder's rule, 2026-10-21), from the device's time zone
 * and, when known, its region (ISO 3166 alpha-2, from the language tag):
 * - Colombia (the region is CO, or the zone is America/Bogota) → COP;
 * - Europe (the region is European, or the zone is Europe/*) → EUR;
 * - anywhere else → USD: the rest of Latin America, the US, and anyone we can't place.
 * The account's currency locks at its first transaction, so a wrong euro for a peso earner would
 * stick: USD is the safer unknown. The web (onboarding) and the API (guest sign-up) both use it.
 */
export function defaultCurrencyFor(timezone: string, region?: string): SupportedCurrency {
  const country = region?.toUpperCase();
  if (country === "CO" || timezone === "America/Bogota") return "COP";
  if ((country && EUROPE.has(country)) || timezone.startsWith("Europe/")) return "EUR";
  return "USD";
}
