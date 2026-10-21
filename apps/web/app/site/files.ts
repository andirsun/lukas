import { PAGE_PATH, SITE_PAGES } from "./paths.ts";

/**
 * `sitemap.xml`: the landing and the roadmap, each in both languages, each entry listing every
 * language of its page (itself included) plus `x-default` → Spanish, all on `origin`.
 */
export function sitemapXml(origin: string): string {
  const entry = (loc: string, es: string, en: string) =>
    [
      "  <url>",
      `    <loc>${loc}</loc>`,
      `    <xhtml:link rel="alternate" hreflang="es" href="${es}"/>`,
      `    <xhtml:link rel="alternate" hreflang="en" href="${en}"/>`,
      `    <xhtml:link rel="alternate" hreflang="x-default" href="${es}"/>`,
      "  </url>",
    ].join("\n");
  const urls = SITE_PAGES.flatMap((page) => {
    const es = `${origin}${PAGE_PATH[page].es}`;
    const en = `${origin}${PAGE_PATH[page].en}`;
    return [entry(es, es, en), entry(en, es, en)];
  });
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${urls.join("\n")}
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
