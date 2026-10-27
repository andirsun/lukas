import { LOCALES } from "../i18n/format.ts";
import { PAGE_PATH, SITE_PAGES } from "./paths.ts";

/**
 * `sitemap.xml`: the landing and the roadmap, each in every language, each entry listing every
 * language of its page (itself included) plus `x-default` → Spanish, all on `origin`.
 */
export function sitemapXml(origin: string): string {
  const urls = SITE_PAGES.flatMap((page) => {
    const href = (locale: (typeof LOCALES)[number]) => `${origin}${PAGE_PATH[page][locale]}`;
    const alternates = [
      ...LOCALES.map(
        (locale) => `    <xhtml:link rel="alternate" hreflang="${locale}" href="${href(locale)}"/>`,
      ),
      `    <xhtml:link rel="alternate" hreflang="x-default" href="${href("es")}"/>`,
    ];
    return LOCALES.map((locale) =>
      ["  <url>", `    <loc>${href(locale)}</loc>`, ...alternates, "  </url>"].join("\n"),
    );
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
