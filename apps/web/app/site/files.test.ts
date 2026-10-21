import { describe, expect, it } from "vitest";
import { robotsTxt, sitemapXml } from "./files.ts";

const ORIGIN = "https://lukitas.andersonlaverde.com";

describe("sitemapXml", () => {
  const xml = sitemapXml(ORIGIN);

  it("lists both landing pages and both roadmap pages from the origin", () => {
    expect(xml).toContain(`<loc>${ORIGIN}/</loc>`);
    expect(xml).toContain(`<loc>${ORIGIN}/en</loc>`);
    expect(xml).toContain(`<loc>${ORIGIN}/roadmap</loc>`);
    expect(xml).toContain(`<loc>${ORIGIN}/en/roadmap</loc>`);
    expect(xml.match(/<url>/g)).toHaveLength(4);
  });

  it("gives each roadmap page its own alternates, not the landing's", () => {
    const entry = (loc: string) => {
      const start = xml.indexOf(`<loc>${loc}</loc>`);
      return xml.slice(start, xml.indexOf("</url>", start));
    };
    for (const loc of [`${ORIGIN}/roadmap`, `${ORIGIN}/en/roadmap`]) {
      const block = entry(loc);
      expect(block).toContain(`hreflang="es" href="${ORIGIN}/roadmap"`);
      expect(block).toContain(`hreflang="en" href="${ORIGIN}/en/roadmap"`);
      expect(block).toContain(`hreflang="x-default" href="${ORIGIN}/roadmap"`);
      expect(block).not.toContain(`href="${ORIGIN}/en"`);
    }
  });

  it("gives each page every language, itself included, plus x-default to Spanish", () => {
    const alternates = [
      `hreflang="es" href="${ORIGIN}/"`,
      `hreflang="en" href="${ORIGIN}/en"`,
      `hreflang="x-default" href="${ORIGIN}/"`,
    ];
    for (const alternate of alternates) {
      expect(xml.split(alternate)).toHaveLength(3);
    }
  });

  it("mentions no other origin", () => {
    expect(xml).not.toContain("lukas.app");
  });
});

describe("robotsTxt", () => {
  it("points at the sitemap on the origin", () => {
    expect(robotsTxt(ORIGIN, { landingOnly: false })).toContain(`Sitemap: ${ORIGIN}/sitemap.xml`);
    expect(robotsTxt(ORIGIN, { landingOnly: true })).toContain(`Sitemap: ${ORIGIN}/sitemap.xml`);
  });

  it("keeps crawlers out of the app's routes when the app exists", () => {
    const robots = robotsTxt(ORIGIN, { landingOnly: false });
    expect(robots).toContain("User-agent: *");
    expect(robots).toContain("Allow: /");
    for (const path of ["/app", "/welcome", "/auth/"])
      expect(robots).toContain(`Disallow: ${path}`);
  });

  it("has no app routes to hide in landing-only mode", () => {
    const robots = robotsTxt(ORIGIN, { landingOnly: true });
    expect(robots).toContain("Allow: /");
    expect(robots).not.toContain("Disallow");
  });
});
