import { existsSync, renameSync, rmSync } from "node:fs";
import { join } from "node:path";
import type { Config } from "@react-router/dev/config";
import { LOCALES } from "./app/i18n/format.ts";
import { readBuildEnv } from "./app/site/build-env.ts";
import { isLandingOnly, resolveAppOrigin, resolveSiteOrigin } from "./app/site/origin.ts";
import { PAGE_PATH, SITE_PAGES } from "./app/site/paths.ts";
import { finalizeBuild } from "./scripts/finalize-build.ts";

/**
 * Build-time switches (see app/site/config.ts for what they do in the app):
 * - VITE_SITE_URL: the site's public origin, for robots.txt and sitemap.xml written after the build.
 * - VITE_LANDING_ONLY=true: only the landing and a 404 page ship (docs/deploy/landing.md).
 * - VITE_APP_URL: with VITE_LANDING_ONLY, the live app's origin; the calls to action open it.
 * All are read the way Vite reads them for the app code (`import.meta.env`): from the real
 * environment and from the `.env` files of apps/web, so a flag set in either builds the same site.
 */
const env = readBuildEnv();
const origin = resolveSiteOrigin(env.siteUrl);
const landingOnly = isLandingOnly(env.landingOnly);
// Not used here, but a typo should stop the build before it prerenders broken links.
resolveAppOrigin(env.appUrl);

/** The public pages, in every language (the landing and the roadmap). */
const PUBLIC_PAGES = SITE_PAGES.flatMap((page) => LOCALES.map((locale) => PAGE_PATH[page][locale]));

/**
 * Where the build goes: `build` (apps/web/build) unless LUKAS_BUILD_DIR says otherwise. The
 * personal install builds the full app elsewhere (deploy/personal/up.sh), so it does not replace
 * the landing release that sits in build/client.
 */
const buildDirectory = process.env.LUKAS_BUILD_DIR || "build";

export default {
  buildDirectory,
  // The landing and roadmap pages are static HTML; everything else is a client-side SPA.
  ssr: false,
  // Landing-only: the unknown-path page too, which buildEnd turns into the top-level 404.html.
  prerender: landingOnly ? [...PUBLIC_PAGES, "/404"] : PUBLIC_PAGES,
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
