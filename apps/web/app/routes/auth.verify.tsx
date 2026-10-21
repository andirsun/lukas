import { liveSignInAuth } from "../features/sign-in/auth.ts";
import { signInMeta } from "../features/sign-in/meta.ts";
import { Verify } from "../features/sign-in/Verify.tsx";
import type { Route } from "./+types/auth.verify";

export const meta = ({ location }: Route.MetaArgs) => signInMeta("verify", location.search);

/** `/auth/verify?email&code`: the magic link. No guard: it works signed in or not. */
export default function VerifyRoute() {
  return <Verify auth={liveSignInAuth} />;
}
