/**
 * Builds the landing-only release (`pnpm build:landing`): the prerendered landing pages plus a 404
 * page, and nothing that leads to the app. VITE_SITE_URL (the site's public origin, used in the
 * canonical, hreflang, Open Graph, sitemap and robots) is required; there is no placeholder to fall
 * back on for something you are about to publish.
 *
 *   VITE_SITE_URL=https://lukitas.andersonlaverde.com pnpm --filter @lukas/web build:landing
 *
 * The output stays in build/client.
 */
import { spawnSync } from "node:child_process";
import { readBuildEnv } from "../app/site/build-env.ts";
import { resolveSiteOrigin } from "../app/site/origin.ts";

// The environment or a `.env` file of apps/web, as the build itself reads it.
const raw = readBuildEnv().siteUrl;
if (!raw?.trim()) {
  console.error(
    "VITE_SITE_URL is not set (environment or apps/web/.env). Pass the site's public origin, e.g.\n" +
      "  VITE_SITE_URL=https://lukitas.andersonlaverde.com pnpm --filter @lukas/web build:landing",
  );
  process.exit(1);
}

let origin: string;
try {
  origin = resolveSiteOrigin(raw);
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}

console.log(`Building the landing-only release for ${origin}`);
const result = spawnSync("react-router", ["build"], {
  stdio: "inherit",
  env: { ...process.env, VITE_SITE_URL: origin, VITE_LANDING_ONLY: "true" },
});
process.exit(result.status ?? 1);
