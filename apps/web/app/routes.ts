import { index, type RouteConfig, route } from "@react-router/dev/routes";
import { isLandingOnly } from "./site/origin.ts";

export default [
  // The landing page, prerendered per language (react-router.config.ts).
  index("routes/_index.tsx"),
  route("en", "routes/en._index.tsx"),
  // The landing-only release has no app: any other path is a prerendered 404 (react-router.config.ts).
  ...(isLandingOnly(process.env.VITE_LANDING_ONLY) ? [route("*", "routes/not-found.tsx")] : []),
] satisfies RouteConfig;
