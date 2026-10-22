import type { Locale } from "../../i18n/format.ts";
import { APP_ORIGIN, LANDING_ONLY } from "../../site/config.ts";

/** The demo without an account ("Pruébalo sin cuenta"): part of the app, not of the landing. */
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
 * Where "Pruébalo sin cuenta" goes: the demo, in the visitor's language. The demo is part of the
 * app, so the landing-only release opens it on the app's origin (`VITE_APP_URL`), like sign-in;
 * without an app to open there is no demo either, and the link is left out (null).
 */
export function demoLinkProps(
  locale: Locale,
  landingOnly: boolean = LANDING_ONLY,
  appOrigin: string | undefined = APP_ORIGIN,
): { to: string } | null {
  const demo = `${DEMO_PATH}?lang=${locale}`;
  if (!landingOnly) return { to: demo };
  return appOrigin ? { to: `${appOrigin}${demo}` } : null;
}

/**
 * The privacy policy. A placeholder anchor on the landing page itself (the FAQ answer about your
 * data) until the policy has its own page.
 */
export const PRIVACY_HREF = "#privacy";

/** The copyright year: the landing page's first publication. */
export const COPYRIGHT_YEAR = 2026;
