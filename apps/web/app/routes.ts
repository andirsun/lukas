import { index, layout, type RouteConfig, route } from "@react-router/dev/routes";
import { readBuildEnv } from "./site/build-env.ts";
import { isLandingOnly } from "./site/origin.ts";

export default [
  // The landing page, prerendered per language (react-router.config.ts).
  index("routes/_index.tsx"),
  route("en", "routes/en._index.tsx"),
  // Every screen of the app (sign-in, welcome, /app/*) nests under this layout, which holds the
  // API client, its cache and the toasts. The landing stays outside it, so visitors do not download
  // that code. (The demo has its own layout with a demo ApiProvider, not nested in this one.)
  layout("routes/app-layout.tsx", []),
  // The landing-only release has no app: any other path is a prerendered 404 (react-router.config.ts).
  ...(isLandingOnly(readBuildEnv().landingOnly) ? [route("*", "routes/not-found.tsx")] : []),
] satisfies RouteConfig;
