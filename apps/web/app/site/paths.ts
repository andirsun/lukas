import type { Locale } from "../i18n/format.ts";

/** Each locale's landing page. Spanish is the default (and `x-default`). */
export const LANDING_PATH: Record<Locale, string> = { es: "/", en: "/en" };
