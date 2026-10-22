import { detectLocale, type Locale } from "../i18n/format.ts";

/** Where the tab remembers the demo's language, so a reload of `/demo/insights` keeps it. */
export const DEMO_LANG_KEY = "lukas.demo.lang";

const asLocale = (value: string | null | undefined): Locale | null =>
  value === "es" || value === "en" ? value : null;

function readStored(storage: Pick<Storage, "getItem"> | undefined): Locale | null {
  try {
    return asLocale(storage?.getItem(DEMO_LANG_KEY));
  } catch {
    return null;
  }
}

function sessionStore(): Storage | undefined {
  try {
    return typeof sessionStorage === "undefined" ? undefined : sessionStorage;
  } catch {
    return undefined;
  }
}

/**
 * The demo's language, which also picks Valentina's money (pesos in Spanish, euros in English):
 * the landing's `?lang=`, else what this tab chose earlier (sessionStorage, so a reload of a deep
 * link like `/demo/insights` keeps it), else the browser's language.
 */
export function demoLocale(
  search: string,
  storage: Pick<Storage, "getItem"> | undefined = sessionStore(),
  navigatorLanguage: string | undefined = typeof navigator === "undefined"
    ? undefined
    : navigator.language,
): Locale {
  return (
    asLocale(new URLSearchParams(search).get("lang")) ??
    readStored(storage) ??
    detectLocale(navigatorLanguage)
  );
}

/** Remembers the demo's language for this tab only; storage that is blocked is fine. */
export function rememberDemoLocale(
  locale: Locale,
  storage: Pick<Storage, "setItem"> | undefined = sessionStore(),
): void {
  try {
    storage?.setItem(DEMO_LANG_KEY, locale);
  } catch {
    // Blocked storage: a reload falls back to the browser's language.
  }
}
