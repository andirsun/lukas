import { existsSync, renameSync, rmSync } from "node:fs";
import { join } from "node:path";
import type { Config } from "@react-router/dev/config";

export default {
  // The landing pages are static HTML; everything else is a client-side SPA.
  ssr: false,
  prerender: ["/", "/en"],
  /**
   * Vite's manifest (`build.manifest` in vite.config.ts) is for the landing e2e's JavaScript budget,
   * not for visitors: move it out of `build/client` (what ships) to `build/vite-manifest.json`.
   */
  buildEnd({ reactRouterConfig }) {
    const build = reactRouterConfig.buildDirectory;
    const viteDir = join(build, "client", ".vite");
    const manifest = join(viteDir, "manifest.json");
    if (existsSync(manifest)) renameSync(manifest, join(build, "vite-manifest.json"));
    rmSync(viteDir, { recursive: true, force: true });
  },
} satisfies Config;
