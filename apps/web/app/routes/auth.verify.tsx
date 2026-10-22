import { liveSignInAuth } from "../features/sign-in/auth.ts";
import { signInMeta } from "../features/sign-in/meta.ts";
import { Verify } from "../features/sign-in/Verify.tsx";
import type { Route } from "./+types/auth.verify";

/** The link carries a sign-in code: this page never sends a referrer anywhere. */
export const meta = ({ location }: Route.MetaArgs) => [
  ...signInMeta("verify", location.search),
  { name: "referrer", content: "no-referrer" },
];

/** `/auth/verify?email&code`: the magic link. No guard: it works signed in or not. */
export default function VerifyRoute() {
  return <Verify auth={liveSignInAuth} />;
}
