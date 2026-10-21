import { index, type RouteConfig, route } from "@react-router/dev/routes";

export default [
  index("routes/home-placeholder.tsx"),
  route("en", "routes/home-placeholder.tsx", { id: "routes/home-placeholder-en" }),
] satisfies RouteConfig;
