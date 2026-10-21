import { useNavigate } from "react-router";
import { useTranslations } from "use-intl";
import { useClearSession } from "../../api/ApiProvider.tsx";
import { authClient } from "../../auth/auth-client.ts";
import { useToast } from "../../ui/Toast.tsx";

/** Ends the session; Better Auth answers `{ error }` rather than throwing on an HTTP failure. */
export type SignOutRequest = () => Promise<{ error: unknown }>;

const liveSignOut: SignOutRequest = () => authClient.signOut();

/**
 * Signs out, safely: only once the server says the session is over does it go to /sign-in and
 * empty the cache (in that order, so nothing on home refetches with the ended session). On a
 * failure (an error answer, no connection) it stays, with an error toast: a person on a shared
 * device must never believe they signed out when they did not.
 */
export function useSignOut(request: SignOutRequest = liveSignOut): () => Promise<void> {
  const t = useTranslations("home");
  const toast = useToast();
  const navigate = useNavigate();
  const clearSession = useClearSession();
  return async () => {
    let failed: boolean;
    try {
      failed = Boolean((await request()).error);
    } catch {
      failed = true;
    }
    if (failed) {
      toast.show({ tone: "error", message: t("sign_out_failed") });
      return;
    }
    navigate("/sign-in", { replace: true });
    clearSession();
  };
}
