import { redirectIfSignedIn } from "../auth/session.ts";
import { liveSignInAuth } from "../features/sign-in/auth.ts";
import { signInMeta } from "../features/sign-in/meta.ts";
import { SignIn } from "../features/sign-in/SignIn.tsx";
import type { Route } from "./+types/sign-in";

export const meta = ({ location }: Route.MetaArgs) => signInMeta("sign_in", location.search);

/** Someone already signed in goes on to `next`, the app, or onboarding. */
export const clientLoader = ({ request }: Route.ClientLoaderArgs) =>
  redirectIfSignedIn({ request });

/** While the session is checked: the screen's background, nothing to read yet. */
export function HydrateFallback() {
  return <div className="lk-screen min-h-dvh" />;
}

/** `/sign-in`: email code or magic link, or a passkey. */
export default function SignInRoute() {
  return <SignIn auth={liveSignInAuth} />;
}
