import { Outlet } from "react-router";
import { useTranslations } from "use-intl";
import { ApiProvider } from "../api/ApiProvider.tsx";
import { ApiProblem, problemMessage, type Translator } from "../api/errors.ts";
import { Celebration } from "../feedback/Celebration.tsx";
import { useFeedbackWarmup } from "../feedback/warmup.ts";
import { Lukas } from "../lukas/Lukas.tsx";
import { PressButton } from "../ui/PressButton.tsx";
import { ToastProvider } from "../ui/Toast.tsx";
import type { Route } from "./+types/app-layout";

/**
 * The layout of the app's own screens (sign-in, welcome, /app/*): the live API client with its cache,
 * the toasts, and the celebration overlay (confetti and Lukitas when `feedback()` fires). It is
 * not in `root.tsx`, so the landing does not pay for any of it.
 *
 * Screens nest under it in routes.ts: `layout("routes/app-layout.tsx", [route("sign-in", ...)])`.
 * The demo is not nested here: it wraps its own routes in `<ApiProvider mode="demo" fetch={...}>`.
 */
export default function AppLayout() {
  useFeedbackWarmup();
  return (
    <ApiProvider>
      <ToastProvider>
        <Outlet />
        <Celebration />
      </ToastProvider>
    </ApiProvider>
  );
}

/**
 * What a screen shows when its loader or render fails, e.g. a session check with no connection
 * or a server error (the guards throw those rather than sending anyone to sign-in): what went
 * wrong, in the catalog's words, and a retry that loads the page again.
 */
export function ErrorBoundary({ error }: Route.ErrorBoundaryProps) {
  const t = useTranslations() as unknown as Translator;
  const message = error instanceof ApiProblem ? problemMessage(error, t) : t("errors.generic");
  return (
    <main className="lk-screen flex min-h-dvh flex-col items-center justify-center gap-(--space-4) p-(--space-4) text-center">
      <Lukas mood="worried" size={96} />
      <p role="alert" className="max-w-[360px] text-ink">
        {message}
      </p>
      <PressButton onClick={() => window.location.reload()}>{t("common.retry")}</PressButton>
    </main>
  );
}
