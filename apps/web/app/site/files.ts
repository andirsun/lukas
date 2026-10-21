import { LANDING_PATH } from "./paths.ts";

/**
 * `sitemap.xml`: both landing pages, each listing every language (itself included) plus
 * `x-default` → Spanish, all on `origin`.
 */
export function sitemapXml(origin: string): string {
  const es = `${origin}${LANDING_PATH.es}`;
  const en = `${origin}${LANDING_PATH.en}`;
  const alternates = [
    `    <xhtml:link rel="alternate" hreflang="es" href="${es}"/>`,
    `    <xhtml:link rel="alternate" hreflang="en" href="${en}"/>`,
    `    <xhtml:link rel="alternate" hreflang="x-default" href="${es}"/>`,
  ].join("\n");
  const url = (loc: string) => `  <url>\n    <loc>${loc}</loc>\n${alternates}\n  </url>`;
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${url(es)}
${url(en)}
</urlset>
`;
}

/**
 * `robots.txt`: everything is open to crawlers, except the app's own routes when the app exists
 * (the landing-only build has none), and the sitemap on `origin`.
 */
export function robotsTxt(origin: string, { landingOnly }: { landingOnly: boolean }): string {
  const lines = ["User-agent: *", "Allow: /"];
  if (!landingOnly) lines.push("Disallow: /app", "Disallow: /welcome", "Disallow: /auth/");
  lines.push("", `Sitemap: ${origin}/sitemap.xml`, "");
  return lines.join("\n");
}
