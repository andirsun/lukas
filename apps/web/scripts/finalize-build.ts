import { existsSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { robotsTxt, sitemapXml } from "../app/site/files.ts";

export type FinalizeOptions = { origin: string; landingOnly: boolean };

/**
 * What `build/client` needs after the prerender, whatever the mode: `robots.txt` and `sitemap.xml`
 * written from the site's origin (they are not static files: they carry the domain).
 *
 * Landing-only: the prerendered `/404` becomes the top-level `404.html` that Cloudflare Pages
 * serves for unknown paths, and the SPA fallback goes, so no path ever falls back to the (absent)
 * app shell.
 */
export function finalizeBuild(client: string, { origin, landingOnly }: FinalizeOptions): void {
  writeFileSync(join(client, "robots.txt"), robotsTxt(origin, { landingOnly }));
  writeFileSync(join(client, "sitemap.xml"), sitemapXml(origin));
  if (!landingOnly) return;

  const notFound = join(client, "404", "index.html");
  if (!existsSync(notFound)) {
    throw new Error(`The landing-only build has no prerendered 404 page (${notFound}).`);
  }
  renameSync(notFound, join(client, "404.html"));
  rmSync(join(client, "404"), { recursive: true, force: true });
  rmSync(join(client, "__spa-fallback.html"), { force: true });
}
