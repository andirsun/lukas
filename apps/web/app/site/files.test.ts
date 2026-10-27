import { describe, expect, it } from "vitest";
import { robotsTxt, sitemapXml } from "./files.ts";

const ORIGIN = "https://lukitas.andersonlaverde.com";

describe("sitemapXml", () => {
  const xml = sitemapXml(ORIGIN);

  it("lists the four landing pages and the four roadmap pages from the origin", () => {
    for (const path of [
      "/",
      "/en",
      "/it",
      "/pt",
      "/roadmap",
      "/en/roadmap",
      "/it/roadmap",
      "/pt/roadmap",
    ]) {
      expect(xml).toContain(`<loc>${ORIGIN}${path}</loc>`);
    }
    expect(xml.match(/<url>/g)).toHaveLength(8);
  });

  it("gives each roadmap page its own alternates, not the landing's", () => {
    const entry = (loc: string) => {
      const start = xml.indexOf(`<loc>${loc}</loc>`);
      return xml.slice(start, xml.indexOf("</url>", start));
    };
    for (const loc of [
      `${ORIGIN}/roadmap`,
      `${ORIGIN}/en/roadmap`,
      `${ORIGIN}/it/roadmap`,
      `${ORIGIN}/pt/roadmap`,
    ]) {
      const block = entry(loc);
      expect(block).toContain(`hreflang="es" href="${ORIGIN}/roadmap"`);
      expect(block).toContain(`hreflang="en" href="${ORIGIN}/en/roadmap"`);
      expect(block).toContain(`hreflang="it" href="${ORIGIN}/it/roadmap"`);
      expect(block).toContain(`hreflang="pt" href="${ORIGIN}/pt/roadmap"`);
      expect(block).toContain(`hreflang="x-default" href="${ORIGIN}/roadmap"`);
      expect(block).not.toContain(`href="${ORIGIN}/en"`);
    }
  });

  it("gives each page every language, itself included, plus x-default to Spanish", () => {
    const alternates = [
      `hreflang="es" href="${ORIGIN}/"`,
      `hreflang="en" href="${ORIGIN}/en"`,
      `hreflang="it" href="${ORIGIN}/it"`,
      `hreflang="pt" href="${ORIGIN}/pt"`,
      `hreflang="x-default" href="${ORIGIN}/"`,
    ];
    for (const alternate of alternates) {
      // Once in each of the landing's four entries.
      expect(xml.split(alternate)).toHaveLength(5);
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
