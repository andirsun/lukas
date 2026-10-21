import type { Locale } from "../../i18n/format.ts";
import { LANDING_ONLY } from "../../site/config.ts";

/** The demo without an account ("Pruébalo sin cuenta"), built in Task 18a. */
export const DEMO_PATH = "/demo";

/** The source code: Lukas is open source (AGPL-3.0). Opened in a new tab. */
export const GITHUB_HREF = "https://github.com/andirsun/lukas";

/**
 * Where "Empieza ahora" and "Entrar" go: sign-in, told which language the visitor came from. In
 * the landing-only release there is no app yet, so they lead to the GitHub repo in a new tab
 * (`LANDING_ONLY`, spread onto a `PressLink`).
 */
export function appLinkProps(
  locale: Locale,
  landingOnly: boolean = LANDING_ONLY,
): { to: string; target?: "_blank"; rel?: string } {
  if (landingOnly) return { to: GITHUB_HREF, target: "_blank", rel: "noopener" };
  return { to: `/sign-in?lang=${locale}` };
}

/**
 * The privacy policy. A placeholder anchor on the landing page itself (the FAQ answer about your
 * data) until the policy has its own page.
 */
export const PRIVACY_HREF = "#privacy";

/** The copyright year: the landing page's first publication. */
export const COPYRIGHT_YEAR = 2026;
