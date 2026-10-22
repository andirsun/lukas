import { Outlet } from "react-router";
import { ApiProvider } from "../api/ApiProvider.tsx";
import { ScreenError } from "../features/home/ScreenError.tsx";
import { Celebration } from "../feedback/Celebration.tsx";
import { useFeedbackWarmup } from "../feedback/warmup.ts";
import { AppMessages } from "../i18n/AppMessages.tsx";
import { ToastProvider } from "../ui/Toast.tsx";
import type { Route } from "./+types/app-layout";

/**
 * The layout of the app's own screens (sign-in, welcome, /app/*): the live API client with its cache,
 * the toasts, the celebration overlay (confetti and Lukitas when `feedback()` fires) and the app's
 * messages (`AppMessages`). It is not in `root.tsx`, so the landing does not pay for any of it.
 *
 * Screens nest under it in routes.ts: `layout("routes/app-layout.tsx", [route("sign-in", ...)])`.
 * The demo is not nested here: routes/demo.tsx wraps the same screens in
 * `<ApiProvider mode="demo" fetch={...}>`, with its own toasts and celebration.
 */
export default function AppLayout() {
  useFeedbackWarmup();
  return (
    <AppMessages>
      <ApiProvider>
        <ToastProvider>
          <Outlet />
          <Celebration />
        </ToastProvider>
      </ApiProvider>
    </AppMessages>
  );
}

/**
 * What a screen shows when its loader or render fails, e.g. a session check with no connection
 * or a server error: what went wrong and a retry (`ScreenError`).
 */
export function ErrorBoundary({ error }: Route.ErrorBoundaryProps) {
  return (
    <AppMessages>
      <ScreenError error={error} />
    </AppMessages>
  );
}
