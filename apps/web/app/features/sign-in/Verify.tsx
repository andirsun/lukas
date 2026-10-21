import { useEffect, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router";
import { useTranslations } from "use-intl";
import { safeNext } from "../../auth/next.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { type AuthErrorKey, authErrorKey, type SignInAuth, verifyErrorKey } from "./auth.ts";
import { CODE_LENGTH } from "./CodeInput.tsx";
import type { SignInState } from "./SignIn.tsx";
import { FieldError, ScreenTitle, SignInScreen } from "./SignInScreen.tsx";
import { useFinishSignIn } from "./use-finish-sign-in.ts";

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const CODE = new RegExp(`^\\d{${CODE_LENGTH}}$`);

/** Failures a retry of the same link can fix; anything else needs a new code. */
const TRANSIENT: AuthErrorKey[] = ["errors.network_error", "errors.internal_error"];

type Status = { kind: "checking" } | { kind: "failed"; error: AuthErrorKey };

/**
 * `/auth/verify?email=…&code=…`: the magic link from the sign-in email. It signs in on its own
 * with the email and code from the URL, so it works in any browser (no state from the page that
 * asked for the code) and whether someone is signed in here or not. Then on to onboarding, `next`
 * or the app. A code that no longer works says so and offers a new one.
 */
export function Verify({ auth }: { auth: SignInAuth }) {
  const t = useTranslations("verify");
  const tRoot = useTranslations();
  const navigate = useNavigate();
  const finish = useFinishSignIn();
  const [params] = useSearchParams();
  const email = (params.get("email") ?? "").trim().toLowerCase();
  const code = (params.get("code") ?? "").trim();
  const next = params.get("next");
  const usable = EMAIL.test(email) && CODE.test(code);

  const [status, setStatus] = useState<Status>(
    usable ? { kind: "checking" } : { kind: "failed", error: "errors.invalid_or_expired_code" },
  );
  const [attempt, setAttempt] = useState(0);
  const [sending, setSending] = useState(false);
  // One submission per attempt, even when effects run twice (React's StrictMode in development):
  // a code works once, so a second submission would fail and show "expired" after signing in.
  const submitted = useRef(-1);

  useEffect(() => {
    if (!usable || submitted.current === attempt) return;
    submitted.current = attempt;
    void (async () => {
      const result = await auth.verifyCode(email, code);
      if (result.error) setStatus({ kind: "failed", error: verifyErrorKey(result.error) });
      else await finish({ user: result.data, next, lang: null });
    })();
  }, [attempt, usable, auth, email, code, next, finish]);

  async function sendNewCode() {
    const search = next ? `?next=${encodeURIComponent(safeNext(next))}` : "";
    if (!EMAIL.test(email)) {
      navigate({ pathname: "/sign-in", search });
      return;
    }
    setSending(true);
    const result = await auth.sendCode(email);
    setSending(false);
    if (result.error) {
      setStatus({ kind: "failed", error: authErrorKey(result.error) });
      return;
    }
    const state: SignInState = { email, codeSent: true };
    navigate({ pathname: "/sign-in", search }, { state });
  }

  if (status.kind === "checking") {
    return (
      <SignInScreen>
        <div aria-busy="true" className="contents">
          <ScreenTitle>{t("checking")}</ScreenTitle>
        </div>
      </SignInScreen>
    );
  }

  const transient = TRANSIENT.includes(status.error);
  return (
    <SignInScreen mood="worried">
      <ScreenTitle>{t("failed_title")}</ScreenTitle>
      <div className="w-full text-center">
        <FieldError id="verify-error">{tRoot(status.error)}</FieldError>
      </div>
      <PressButton className="w-full" disabled={sending} onClick={sendNewCode}>
        {t("send_new_code")}
      </PressButton>
      {transient && (
        <PressButton
          variant="secondary"
          className="w-full"
          disabled={sending}
          onClick={() => {
            setStatus({ kind: "checking" });
            setAttempt((n) => n + 1);
          }}
        >
          {tRoot("common.retry")}
        </PressButton>
      )}
    </SignInScreen>
  );
}
