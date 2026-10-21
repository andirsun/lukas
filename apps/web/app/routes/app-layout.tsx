import { Outlet } from "react-router";
import { ApiProvider } from "../api/ApiProvider.tsx";
import { Celebration } from "../feedback/Celebration.tsx";
import { useFeedbackWarmup } from "../feedback/warmup.ts";
import { ToastProvider } from "../ui/Toast.tsx";

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
