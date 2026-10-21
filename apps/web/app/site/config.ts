import { isLandingOnly, resolveSiteOrigin } from "./origin.ts";

/** The public origin used in absolute URLs. `VITE_SITE_URL` at build time, else the placeholder. */
export const SITE_ORIGIN = resolveSiteOrigin(import.meta.env.VITE_SITE_URL);

/**
 * Landing-only release (`VITE_LANDING_ONLY=true`): the app does not exist yet, so everything that
 * would lead to it leads to the GitHub repo instead, marked as coming soon. Off by default.
 */
export const LANDING_ONLY = isLandingOnly(import.meta.env.VITE_LANDING_ONLY);
