import type { Locale } from "../../i18n/format.ts";

/** Where "Empieza ahora" goes: sign-in, told which language the visitor came from. */
export function signInHref(locale: Locale): string {
  return `/sign-in?lang=${locale}`;
}

/** The demo without an account ("Pruébalo sin cuenta"), built in Task 18a. */
export const DEMO_PATH = "/demo";

/** The source code: Lukas is open source (AGPL-3.0). Opened in a new tab. */
export const GITHUB_HREF = "https://github.com/andirsun/lukas";

/**
 * The privacy policy. A placeholder anchor on the landing page itself (the FAQ answer about your
 * data) until the policy has its own page.
 */
export const PRIVACY_HREF = "#privacy";

/** The copyright year: the landing page's first publication. */
export const COPYRIGHT_YEAR = 2026;
