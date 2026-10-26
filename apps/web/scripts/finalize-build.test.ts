import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { finalizeBuild } from "./finalize-build.ts";

const ORIGIN = "https://lukitas.andersonlaverde.com";
let dir: string;

beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "lukas-build-"));
  writeFileSync(join(dir, "index.html"), "<html>es</html>");
  writeFileSync(join(dir, "__spa-fallback.html"), "<html>fallback</html>");
});
afterEach(() => rmSync(dir, { recursive: true, force: true }));

describe("finalizeBuild", () => {
  it("writes robots.txt and sitemap.xml from the origin", () => {
    finalizeBuild(dir, { origin: ORIGIN, landingOnly: false });
    expect(readFileSync(join(dir, "robots.txt"), "utf8")).toContain(
      `Sitemap: ${ORIGIN}/sitemap.xml`,
    );
    expect(readFileSync(join(dir, "sitemap.xml"), "utf8")).toContain(`<loc>${ORIGIN}/en</loc>`);
  });

  it("lists the roadmap pages in sitemap.xml, in both modes", () => {
    for (const landingOnly of [false, true]) {
      if (landingOnly) {
        mkdirSync(join(dir, "404"));
        writeFileSync(join(dir, "404", "index.html"), "<html>not found</html>");
      }
      finalizeBuild(dir, { origin: ORIGIN, landingOnly });
      const sitemap = readFileSync(join(dir, "sitemap.xml"), "utf8");
      expect(sitemap).toContain(`<loc>${ORIGIN}/roadmap</loc>`);
      expect(sitemap).toContain(`<loc>${ORIGIN}/en/roadmap</loc>`);
      expect(sitemap).toContain(`<loc>${ORIGIN}/it/roadmap</loc>`);
      expect(sitemap).toContain(`<loc>${ORIGIN}/pt/roadmap</loc>`);
    }
  });

  it("keeps the SPA fallback when the app exists", () => {
    finalizeBuild(dir, { origin: ORIGIN, landingOnly: false });
    expect(existsSync(join(dir, "__spa-fallback.html"))).toBe(true);
  });

  it("in landing-only mode drops the SPA fallback and turns the prerendered 404 into 404.html", () => {
    mkdirSync(join(dir, "404"));
    writeFileSync(join(dir, "404", "index.html"), "<html>not found</html>");
    finalizeBuild(dir, { origin: ORIGIN, landingOnly: true });
    expect(existsSync(join(dir, "__spa-fallback.html"))).toBe(false);
    expect(readFileSync(join(dir, "404.html"), "utf8")).toBe("<html>not found</html>");
    expect(existsSync(join(dir, "404"))).toBe(false);
    expect(readFileSync(join(dir, "index.html"), "utf8")).toBe("<html>es</html>");
  });

  it("in landing-only mode fails when the 404 page was not prerendered", () => {
    expect(() => finalizeBuild(dir, { origin: ORIGIN, landingOnly: true })).toThrow(/404/);
  });
});
