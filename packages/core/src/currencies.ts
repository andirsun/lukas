/**
 * ISO 4217 codes an account can use: COP, USD and EUR at launch (spec §2.4). COP is first: it is
 * the launch market. Its own module, without zod, so the web app can read it without bundling the
 * schemas (package.json marks this package free of side effects).
 */
export const SUPPORTED_CURRENCIES = ["COP", "USD", "EUR"] as const;
export type SupportedCurrency = (typeof SUPPORTED_CURRENCIES)[number];
