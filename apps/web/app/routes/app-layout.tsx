import { Outlet } from "react-router";
import { ApiProvider } from "../api/ApiProvider.tsx";
import { ToastProvider } from "../ui/Toast.tsx";

/**
 * The layout of the app's own screens (sign-in, welcome, /app/*): the live API client with its cache,
 * and the toasts. It is not in `root.tsx`, so the landing does not pay for any of it.
 *
 * Screens nest under it in routes.ts: `layout("routes/app-layout.tsx", [route("sign-in", ...)])`.
 * The demo is not nested here: it wraps its own routes in `<ApiProvider mode="demo" fetch={...}>`.
 */
export default function AppLayout() {
  return (
    <ApiProvider>
      <ToastProvider>
        <Outlet />
      </ToastProvider>
    </ApiProvider>
  );
}
