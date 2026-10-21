import { existsSync, renameSync, rmSync } from "node:fs";
import { join } from "node:path";
import type { Config } from "@react-router/dev/config";
import { isLandingOnly, resolveSiteOrigin } from "./app/site/origin.ts";
import { finalizeBuild } from "./scripts/finalize-build.ts";

/**
 * Build-time switches (see app/site/config.ts for what they do in the app):
 * - VITE_SITE_URL: the site's public origin, for robots.txt and sitemap.xml written after the build.
 * - VITE_LANDING_ONLY=true: only the landing and a 404 page ship (docs/deploy/landing.md).
 */
const origin = resolveSiteOrigin(process.env.VITE_SITE_URL);
const landingOnly = isLandingOnly(process.env.VITE_LANDING_ONLY);

export default {
  // The landing pages are static HTML; everything else is a client-side SPA.
  ssr: false,
  // Landing-only: the unknown-path page too, which buildEnd turns into the top-level 404.html.
  prerender: landingOnly ? ["/", "/en", "/404"] : ["/", "/en"],
  /**
   * Vite's manifest (`build.manifest` in vite.config.ts) is for the landing e2e's JavaScript budget,
   * not for visitors: move it out of `build/client` (what ships) to `build/vite-manifest.json`.
   * Then the files that carry the origin (robots.txt, sitemap.xml) and the landing-only extras.
   */
  buildEnd({ reactRouterConfig }) {
    const build = reactRouterConfig.buildDirectory;
    const viteDir = join(build, "client", ".vite");
    const manifest = join(viteDir, "manifest.json");
    if (existsSync(manifest)) renameSync(manifest, join(build, "vite-manifest.json"));
    rmSync(viteDir, { recursive: true, force: true });
    finalizeBuild(join(build, "client"), { origin, landingOnly });
  },
} satisfies Config;
