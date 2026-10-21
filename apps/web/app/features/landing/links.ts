import type { Locale } from "../../i18n/format.ts";

/** Where "Empieza gratis" goes: sign-in, told which language the visitor came from. */
export function signInHref(locale: Locale): string {
  return `/sign-in?lang=${locale}`;
}

/**
 * The privacy policy. A placeholder anchor on the landing page itself (the FAQ answer about your
 * data) until the policy has its own page.
 */
export const PRIVACY_HREF = "#privacy";

/** The copyright year: the landing page's first publication. */
export const COPYRIGHT_YEAR = 2026;
