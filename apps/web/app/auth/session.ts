import { redirect } from "react-router";
import { getApiMode } from "../api/mode.ts";
import { authClient } from "./auth-client.ts";
import { DEFAULT_NEXT, safeNext, signInPath } from "./next.ts";

/** What the guards need to know about the signed-in user. */
export interface SessionUser {
  id: string;
  email: string;
  /** When they finished onboarding; null until then. */
  onboardingCompletedAt: string | Date | null;
}

/** Who the demo is "signed in" as. */
export const DEMO_USER: SessionUser = {
  id: "demo",
  email: "demo@lukas.app",
  onboardingCompletedAt: "2026-01-01T00:00:00.000Z",
};

export interface GuardDeps {
  /** The current user, or null when signed out. */
  getSession(): Promise<SessionUser | null>;
  mode(): "live" | "demo";
}

const liveDeps: GuardDeps = {
  async getSession() {
    const { data } = await authClient.getSession();
    // Better Auth returns the extra user fields the API declares (see apps/api/src/auth.ts).
    return (data?.user as SessionUser | undefined) ?? null;
  },
  mode: getApiMode,
};

const isOnboarded = (user: SessionUser) => user.onboardingCompletedAt != null;

/**
 * Route guards, written as `clientLoader` helpers: they return what the loader may use, or throw a
 * redirect (React Router sends the browser there). The app is a client-side SPA, so the session
 * is read in the browser; the API still checks every request.
 *
 *   export const clientLoader = () => requireOnboarded("/app/insights");
 */
export function createGuards(deps: GuardDeps) {
  /** The signed-in user, or null (the demo always has one). */
  async function currentUser(): Promise<SessionUser | null> {
    if (deps.mode() === "demo") return DEMO_USER;
    return deps.getSession();
  }

  /** Signed in: returns the user. Signed out: sends them to sign-in, and back to `next` after. */
  async function requireSession(next: string): Promise<SessionUser> {
    const user = await currentUser();
    if (!user) throw redirect(signInPath(next));
    return user;
  }

  /** Signed in and done with onboarding. Not onboarded yet: /welcome. */
  async function requireOnboarded(next: string = DEFAULT_NEXT): Promise<SessionUser> {
    const user = await requireSession(next);
    if (!isOnboarded(user)) throw redirect("/welcome");
    return user;
  }

  /**
   * For sign-in and sign-up pages: a visitor who is already signed in goes on to `?next=` (when
   * it is a same-origin path), to the app, or to /welcome if onboarding is unfinished.
   */
  async function redirectIfSignedIn({ request }: { request: Request }): Promise<null> {
    const user = await currentUser();
    if (!user) return null;
    if (!isOnboarded(user)) throw redirect("/welcome");
    throw redirect(safeNext(new URL(request.url).searchParams.get("next")));
  }

  return { requireSession, requireOnboarded, redirectIfSignedIn };
}

export const { requireSession, requireOnboarded, redirectIfSignedIn } = createGuards(liveDeps);
