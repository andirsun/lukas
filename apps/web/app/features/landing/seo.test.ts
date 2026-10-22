import { describe, expect, it } from "vitest";
import { SITE_ORIGIN } from "../../site/config.ts";
import { landingLinks, landingMeta, roadmapLinks, roadmapMeta } from "./seo.ts";

function metaContent(
  tags: ReturnType<typeof roadmapMeta>,
  key: "name" | "property",
  value: string,
) {
  const tag = tags.find((t) => (t as Record<string, unknown>)[key] === value);
  return (tag as { content?: string } | undefined)?.content;
}

describe("roadmapMeta", () => {
  it("gives each language its own title, description and URL", () => {
    const es = roadmapMeta("es");
    const en = roadmapMeta("en");
    expect(es).toContainEqual({ title: "Lukitas · Lo que viene" });
    expect(en).toContainEqual({ title: "Lukitas · What's next" });
    expect(metaContent(es, "name", "description")?.length).toBeGreaterThan(60);
    expect(metaContent(en, "name", "description")?.length).toBeGreaterThan(60);
    expect(metaContent(es, "property", "og:url")).toBe(`${SITE_ORIGIN}/roadmap`);
    expect(metaContent(en, "property", "og:url")).toBe(`${SITE_ORIGIN}/en/roadmap`);
    expect(metaContent(es, "property", "og:title")).toBe("Lukitas · Lo que viene");
    expect(metaContent(es, "property", "og:image")).toBe(`${SITE_ORIGIN}/og-es.png`);
    expect(metaContent(en, "property", "og:site_name")).toBe("Lukitas");
  });

  it("does not repeat the landing's description", () => {
    expect(metaContent(roadmapMeta("es"), "name", "description")).not.toBe(
      metaContent(landingMeta("es"), "name", "description"),
    );
  });
});

describe("roadmapLinks", () => {
  it("is canonical to itself and lists every language plus x-default to Spanish", () => {
    const links = roadmapLinks("en");
    expect(links).toContainEqual({ rel: "canonical", href: `${SITE_ORIGIN}/en/roadmap` });
    expect(links).toContainEqual({
      rel: "alternate",
      hrefLang: "es",
      href: `${SITE_ORIGIN}/roadmap`,
    });
    expect(links).toContainEqual({
      rel: "alternate",
      hrefLang: "en",
      href: `${SITE_ORIGIN}/en/roadmap`,
    });
    expect(links).toContainEqual({
      rel: "alternate",
      hrefLang: "x-default",
      href: `${SITE_ORIGIN}/roadmap`,
    });
  });

  it("leaves the landing's own links alone", () => {
    expect(landingLinks("es")).toContainEqual({ rel: "canonical", href: `${SITE_ORIGIN}/` });
  });
});
