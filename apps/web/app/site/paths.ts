import type { Locale } from "../i18n/format.ts";

/** Each locale's landing page. Spanish is the default (and `x-default`). */
export const LANDING_PATH: Record<Locale, string> = { es: "/", en: "/en" };

/** Each locale's roadmap page: English URLs, and Spanish has no prefix, like the landing. */
export const ROADMAP_PATH: Record<Locale, string> = { es: "/roadmap", en: "/en/roadmap" };

/** The public, prerendered pages of the site. */
export type SitePage = "landing" | "roadmap";

export const SITE_PAGES: readonly SitePage[] = ["landing", "roadmap"];

/** Where each public page lives, per language. */
export const PAGE_PATH: Record<SitePage, Record<Locale, string>> = {
  landing: LANDING_PATH,
  roadmap: ROADMAP_PATH,
};
