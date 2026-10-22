import { useState } from "react";
import { Outlet, useLocation } from "react-router";
import { ApiProvider } from "../api/ApiProvider.tsx";
import { demoGuards } from "../auth/session.ts";
import { DemoBanner } from "../demo/DemoBanner.tsx";
import { demoLocale, rememberDemoLocale } from "../demo/demo-locale.ts";
import { AppShell } from "../features/home/AppShell.tsx";
import { ScreenError } from "../features/home/ScreenError.tsx";
import { Celebration } from "../feedback/Celebration.tsx";
import { useFeedbackWarmup } from "../feedback/warmup.ts";
import { demoMeta } from "../i18n/screen-meta.ts";
import { ToastProvider } from "../ui/Toast.tsx";
import type { Route } from "./+types/demo";

/** "Demo · Lukitas" in the demo's language, while it loads (each screen then sets its own). */
export const meta = ({ location }: Route.MetaArgs) => demoMeta(location);

/**
 * The demo's guard (always "signed in", as the made-up user: no session call) and its backend,
 * loaded here so neither the landing nor `/app` downloads it.
 */
export async function clientLoader() {
  await demoGuards.requireOnboarded("/demo");
  const [{ createDemoBackend }, { DEMO_SEED }] = await Promise.all([
    import("../demo/demo-backend.ts"),
    import("../demo/demo-data.ts"),
  ]);
  return { createDemoBackend, DEMO_SEED };
}

/** Moving between the demo's screens keeps the same backend: nothing to load again. */
export function shouldRevalidate() {
  return false;
}

/** While the backend loads: the screen's background, nothing to read yet. */
export function HydrateFallback() {
  return <div className="lk-screen min-h-dvh" />;
}

/** As in the app: what went wrong and a retry. */
export function ErrorBoundary({ error }: Route.ErrorBoundaryProps) {
  return <ScreenError error={error} />;
}

/**
 * `/demo/*` (spec §2.6b): the app's own screens, as "Valentina (demo)", against a backend that
 * lives in this page. The same shell and screens as `/app/*` (routes.ts reuses their route
 * modules); links stay under `/demo` (`useAppPath`). Celebrations and toasts as in the app, a
 * sticky banner saying it's a demo. A reload starts over from the seed; nothing is saved anywhere.
 */
export default function DemoRoute({ loaderData }: Route.ComponentProps) {
  const { createDemoBackend, DEMO_SEED } = loaderData;
  const { search } = useLocation();
  // Once per visit: the backend (and so the `fetch` the API client is bound to) never changes
  // while the demo is open, or every screen would start over with an empty cache. Its language
  // is remembered for the tab, so reloading a deep link (`/demo/insights`) keeps it.
  const [backend] = useState(() => {
    const locale = demoLocale(search);
    rememberDemoLocale(locale);
    return createDemoBackend(DEMO_SEED[locale]);
  });
  useFeedbackWarmup();
  return (
    <ApiProvider mode="demo" fetch={backend.fetch}>
      <ToastProvider>
        <AppShell banner={<DemoBanner />}>
          <Outlet />
        </AppShell>
        <Celebration />
      </ToastProvider>
    </ApiProvider>
  );
}
