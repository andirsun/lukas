/**
 * The origin used until the production domain is settled. Setting VITE_SITE_URL at build time
 * replaces it everywhere (canonical, hreflang, Open Graph, sitemap, robots).
 */
export const DEFAULT_SITE_ORIGIN = "https://lukas.app";

/**
 * The site's public origin from `VITE_SITE_URL`: the placeholder when unset or blank, otherwise
 * the value without surrounding whitespace or trailing slashes. Throws on anything that is not a
 * plain `http(s)` origin, so a typo fails the build instead of shipping broken absolute URLs.
 */
export function resolveSiteOrigin(raw: string | undefined): string {
  const value = raw?.trim().replace(/\/+$/, "");
  if (!value) return DEFAULT_SITE_ORIGIN;
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`VITE_SITE_URL must be an origin like https://example.com, got "${raw}"`);
  }
  const plain = url.pathname === "/" && !url.search && !url.hash && !url.username;
  if ((url.protocol !== "https:" && url.protocol !== "http:") || !plain) {
    throw new Error(`VITE_SITE_URL must be an origin like https://example.com, got "${raw}"`);
  }
  return url.origin;
}

/** `VITE_LANDING_ONLY=true` builds only the landing: its calls to action lead to GitHub. */
export function isLandingOnly(raw: string | undefined): boolean {
  return raw === "true";
}
