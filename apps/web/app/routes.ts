import { index, layout, type RouteConfig, route } from "@react-router/dev/routes";
import { readBuildEnv } from "./site/build-env.ts";
import { isLandingOnly } from "./site/origin.ts";

const landingOnly = isLandingOnly(readBuildEnv().landingOnly);

export default [
  // The landing page, prerendered per language (react-router.config.ts).
  index("routes/_index.tsx"),
  route("en", "routes/en._index.tsx"),
  // The public roadmap, prerendered per language like the landing (react-router.config.ts).
  route("roadmap", "routes/roadmap.tsx"),
  route("en/roadmap", "routes/en.roadmap.tsx"),
  // Every screen of the app (sign-in, welcome, /app/*) nests under this layout, which holds the
  // API client, its cache and the toasts. The landing stays outside it, so visitors do not download
  // that code. (The demo has its own layout with a demo ApiProvider, not nested in this one.)
  // The landing-only release has no app, so the layout (and its code and sounds) is left out, and
  // any other path is a prerendered 404 (react-router.config.ts).
  ...(landingOnly
    ? [route("*", "routes/not-found.tsx")]
    : [
        layout("routes/app-layout.tsx", [
          route("sign-in", "routes/sign-in.tsx"),
          route("auth/verify", "routes/auth.verify.tsx"),
          // After an email sign-in: "¿Entrar con tu huella la próxima vez?", once per user per device.
          route("passkey-offer", "routes/passkey-offer.tsx"),
          route("welcome/:step?", "routes/welcome.tsx"),
          // The signed-in app: its shell (bottom bar or sidebar, the add sheet) and home.
          route("app", "routes/app.tsx", [
            index("routes/app._index.tsx"),
            // The import on its own, after onboarding (home's "Trae tu historial").
            route("import", "routes/app.import.tsx"),
            route("categories", "routes/app.categories.tsx"),
            route("categories/:id", "routes/app.categories.$id.tsx"),
            route("recurring", "routes/app.recurring.tsx"),
            route("insights", "routes/app.insights.tsx"),
          ]),
        ]),
      ]),
] satisfies RouteConfig;
