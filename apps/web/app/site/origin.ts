/**
 * The origin used until the production domain is settled. Setting VITE_SITE_URL at build time
 * replaces it everywhere (canonical, hreflang, Open Graph, sitemap, robots).
 */
export const DEFAULT_SITE_ORIGIN = "https://lukas.app";

/**
 * A plain `http(s)` origin without surrounding whitespace or trailing slashes, or a clear error
 * naming the variable (`name`), so a typo fails the build instead of shipping broken URLs.
 */
function parseOrigin(raw: string, name: string): string {
  const value = raw.trim().replace(/\/+$/, "");
  const fail = () => new Error(`${name} must be an origin like https://example.com, got "${raw}"`);
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw fail();
  }
  const plain = url.pathname === "/" && !url.search && !url.hash && !url.username;
  if ((url.protocol !== "https:" && url.protocol !== "http:") || !plain) throw fail();
  return url.origin;
}

/**
 * The site's public origin from `VITE_SITE_URL`: the placeholder when unset or blank, otherwise
 * the value without surrounding whitespace or trailing slashes. Throws on anything that is not a
 * plain `http(s)` origin, so a typo fails the build instead of shipping broken absolute URLs.
 */
export function resolveSiteOrigin(raw: string | undefined): string {
  if (!raw?.trim()) return DEFAULT_SITE_ORIGIN;
  return parseOrigin(raw, "VITE_SITE_URL");
}

/**
 * The live app's origin from `VITE_APP_URL` (landing-only release): `undefined` when unset or
 * blank, which means there is no app to open yet. Same rules as the site origin otherwise.
 */
export function resolveAppOrigin(raw: string | undefined): string | undefined {
  if (!raw?.trim()) return undefined;
  return parseOrigin(raw, "VITE_APP_URL");
}

/**
 * `VITE_LANDING_ONLY=true` builds only the landing. Its calls to action lead to GitHub as "coming
 * soon" (see `isComingSoon`), or to the live app when `VITE_APP_URL` is set.
 */
export function isLandingOnly(raw: string | undefined): boolean {
  return raw === "true";
}

/**
 * The landing-only release with no app to open: calls to action say "coming soon" and lead to
 * GitHub. With an app origin (`VITE_APP_URL`) they are the normal ones and open the app.
 */
export function isComingSoon(landingOnly: boolean, appOrigin: string | undefined): boolean {
  return landingOnly && !appOrigin;
}
