import { index, type RouteConfig, route } from "@react-router/dev/routes";

export default [
  // The landing page, prerendered per language (react-router.config.ts).
  index("routes/_index.tsx"),
  route("en", "routes/en._index.tsx"),
] satisfies RouteConfig;
