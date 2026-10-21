import { Outlet } from "react-router";
import { requireOnboarded } from "../auth/session.ts";
import { AppShell } from "../features/home/AppShell.tsx";
import type { Route } from "./+types/app";

/**
 * `/app/*`: signed in and onboarded (a signed-out visit goes to sign-in and comes back; one not
 * onboarded yet goes to /welcome). The shell holds the bottom bar or sidebar and the add sheet.
 */
export async function clientLoader({ request }: Route.ClientLoaderArgs) {
  await requireOnboarded(new URL(request.url).pathname);
  return null;
}

/** While the session is checked: the screen's background, nothing to read yet. */
export function HydrateFallback() {
  return <div className="lk-screen min-h-dvh" />;
}

export default function AppRoute() {
  return (
    <AppShell>
      <Outlet />
    </AppShell>
  );
}
