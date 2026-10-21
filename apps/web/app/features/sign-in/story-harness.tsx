import { useState } from "react";
import { MemoryRouter, Route, Routes, useLocation } from "react-router";
import { fn } from "storybook/test";
import { ApiProvider } from "../../api/ApiProvider.tsx";
import { ToastProvider } from "../../ui/Toast.tsx";
import type { AuthFailure, AuthResult, AuthUser, CodeHints, SignInAuth } from "./auth.ts";
import { SignIn } from "./SignIn.tsx";
import { Verify } from "./Verify.tsx";

/** The code the fake backend accepts. */
export const GOOD_CODE = "424242";

export const NEW_USER: AuthUser = {
  id: "u-new",
  email: "ana@example.com",
  onboardingCompletedAt: null,
};

export const ONBOARDED_USER: AuthUser = {
  id: "u-old",
  email: "ana@example.com",
  onboardingCompletedAt: "2026-10-01T10:00:00.000Z",
};

export const ok = <T,>(data: T): AuthResult<T> => ({ data, error: null });
export const fail = (error: AuthFailure): AuthResult<never> => ({ data: null, error });

/**
 * A stand-in for Better Auth: `sendCode` always works, `verifyCode` accepts `GOOD_CODE` (and says
 * INVALID_OTP otherwise), passkeys are off unless a story turns them on. Every method is a spy.
 */
export function fakeAuth(overrides: Partial<SignInAuth> & { user?: AuthUser } = {}): SignInAuth {
  const { user = NEW_USER, ...rest } = overrides;
  return {
    sendCode: fn(async (_email: string, _hints: CodeHints) => ok(true as const)),
    verifyCode: fn(async (_email: string, code: string) =>
      code === GOOD_CODE ? ok(user) : fail({ code: "INVALID_OTP", status: 400 }),
    ),
    passkeysAvailable: () => false,
    signInWithPasskey: fn(async () => ok(user)),
    ...rest,
  };
}

/** `GET/PATCH /api/v1/me` for the given profile; PATCH bodies go to `onPatch`. */
function profileFetch(user: AuthUser, onPatch: (body: unknown) => void): typeof fetch {
  let profile = {
    id: user.id,
    email: user.email,
    timezone: "Europe/Lisbon",
    locale: "es",
    onboardingCompletedAt: (user.onboardingCompletedAt as string | null | undefined) ?? null,
  };
  return async (input) => {
    const request = input instanceof Request ? input : new Request(input);
    const path = new URL(request.url).pathname;
    if (path !== "/api/v1/me") return new Response(null, { status: 404 });
    if (request.method === "PATCH") {
      const body = (await request.json()) as Partial<typeof profile>;
      onPatch(body);
      profile = { ...profile, ...body };
    }
    return Response.json(profile);
  };
}

/** Shows where the router ended up, so a play test can read it. */
function WhereAmI() {
  const location = useLocation();
  return (
    <output aria-label="Current page" className="sr-only">
      {location.pathname}
    </output>
  );
}

function Landed({ label }: { label: string }) {
  return <p className="p-(--space-4) text-ink">{label}</p>;
}

export interface SignInStageProps {
  auth: SignInAuth;
  /** Where the router starts: a path, or a location with `state` (e.g. the code step). */
  initialEntry: string | { pathname: string; search?: string; state?: unknown };
  /** The signed-in user's profile, as `GET /v1/me` returns it. */
  profileUser?: AuthUser;
  onPatchMe?: (body: unknown) => void;
  resendDelayMs?: number;
}

/**
 * The sign-in screens inside a memory router, an API provider with a fake `/v1/me` and the
 * toasts, with stand-in pages for where sign-in leads (`/welcome`, `/app/*`).
 */
export function SignInStage({
  auth,
  initialEntry,
  profileUser = NEW_USER,
  onPatchMe = () => {},
  resendDelayMs,
}: SignInStageProps) {
  const [fetchImpl] = useState(() => profileFetch(profileUser, onPatchMe));
  return (
    <MemoryRouter initialEntries={[initialEntry]}>
      <ApiProvider fetch={fetchImpl}>
        <ToastProvider>
          <Routes>
            <Route
              path="/sign-in"
              element={
                <SignIn auth={auth} {...(resendDelayMs !== undefined ? { resendDelayMs } : {})} />
              }
            />
            <Route path="/auth/verify" element={<Verify auth={auth} />} />
            <Route path="/welcome" element={<Landed label="Welcome (stand-in)" />} />
            <Route path="/app/*" element={<Landed label="App (stand-in)" />} />
          </Routes>
          <WhereAmI />
        </ToastProvider>
      </ApiProvider>
    </MemoryRouter>
  );
}
