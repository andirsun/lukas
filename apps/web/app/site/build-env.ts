import { fileURLToPath } from "node:url";
import { loadEnv } from "vite";

/** `apps/web`: where Vite looks for `.env` files, and so do we. */
const WEB_ROOT = fileURLToPath(new URL("../..", import.meta.url));

/**
 * The mode Vite will use: `--mode`/`-m` on the command line, else `NODE_ENV`, else `development`
 * for `react-router dev` and `production` for everything else (`react-router build`, the scripts).
 */
export function resolveBuildMode(
  argv: readonly string[] = process.argv,
  env: NodeJS.ProcessEnv = process.env,
): string {
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i] ?? "";
    if (arg.startsWith("--mode=")) return arg.slice("--mode=".length);
    if ((arg === "--mode" || arg === "-m") && argv[i + 1]) return argv[i + 1] as string;
  }
  if (env.NODE_ENV) return env.NODE_ENV;
  return argv.includes("dev") ? "development" : "production";
}

export interface BuildEnv {
  /** `VITE_SITE_URL`, raw: pass it to `resolveSiteOrigin`. */
  siteUrl: string | undefined;
  /** `VITE_LANDING_ONLY`, raw: pass it to `isLandingOnly`. */
  landingOnly: string | undefined;
}

/**
 * The build-time switches as the app code sees them. `routes.ts` and `react-router.config.ts` run
 * in Node before Vite has loaded any `.env` file, so `process.env` alone would miss a flag that is
 * only in a `.env`; the app code (`import.meta.env`) would then build a different site. Vite's own
 * `loadEnv` reads `.env`, `.env.local`, `.env.[mode]` and `.env.[mode].local`, and lets the real
 * environment win, exactly as it does for `import.meta.env`.
 */
export function readBuildEnv(options: { root?: string; mode?: string } = {}): BuildEnv {
  const env = loadEnv(options.mode ?? resolveBuildMode(), options.root ?? WEB_ROOT, "VITE_");
  return { siteUrl: env.VITE_SITE_URL, landingOnly: env.VITE_LANDING_ONLY };
}
