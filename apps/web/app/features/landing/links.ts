import type { Locale } from "../../i18n/format.ts";
import { APP_ORIGIN, LANDING_ONLY } from "../../site/config.ts";

/** The demo without an account ("Pruébalo sin cuenta"), built in Task 18a. */
export const DEMO_PATH = "/demo";

/** The source code: Lukitas is open source (AGPL-3.0). Opened in a new tab. */
export const GITHUB_HREF = "https://github.com/andirsun/lukas";

/**
 * Where "Empieza ahora" and "Entrar" go: sign-in, told which language the visitor came from
 * (spread onto a `PressLink`). In the landing-only release the app lives on another origin:
 * with `VITE_APP_URL` they open its sign-in there; without it there is no app to open yet, so
 * they lead to the GitHub repo in a new tab.
 */
export function appLinkProps(
  locale: Locale,
  landingOnly: boolean = LANDING_ONLY,
  appOrigin: string | undefined = APP_ORIGIN,
): { to: string; target?: "_blank"; rel?: string } {
  const signIn = `/sign-in?lang=${locale}`;
  if (!landingOnly) return { to: signIn };
  if (appOrigin) return { to: `${appOrigin}${signIn}` };
  return { to: GITHUB_HREF, target: "_blank", rel: "noopener" };
}

/**
 * The privacy policy. A placeholder anchor on the landing page itself (the FAQ answer about your
 * data) until the policy has its own page.
 */
export const PRIVACY_HREF = "#privacy";

/** The copyright year: the landing page's first publication. */
export const COPYRIGHT_YEAR = 2026;
