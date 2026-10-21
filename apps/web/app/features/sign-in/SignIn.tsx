import {
  type FormEvent,
  useCallback,
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { useLocation, useSearchParams } from "react-router";
import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { cx } from "../../ui/cx.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import { useToast } from "../../ui/Toast.tsx";
import {
  type AuthErrorKey,
  type AuthResult,
  type AuthUser,
  authErrorKey,
  langFrom,
  passkeyErrorKey,
  type SignInAuth,
} from "./auth.ts";
import { CODE_LENGTH, CodeInput, type CodeInputHandle } from "./CodeInput.tsx";
import { FieldError, ScreenTitle, SignInScreen } from "./SignInScreen.tsx";
import { useFinishSignIn } from "./use-finish-sign-in.ts";

/** How long "resend" waits after a code was sent. */
export const RESEND_DELAY_MS = 30_000;

/** Good enough to catch typos; the server has the final word. */
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** What `/auth/verify` passes when it sends a new code: open at the code step for this email. */
export interface SignInState {
  email: string;
  codeSent: true;
}

function isSignInState(state: unknown): state is SignInState {
  return (
    typeof state === "object" &&
    state !== null &&
    typeof (state as SignInState).email === "string" &&
    (state as SignInState).codeSent === true
  );
}

/** Seconds left until `at`, ticking every second while there are any. */
function useSecondsUntil(at: number): number {
  const [now, setNow] = useState(() => Date.now());
  const left = Math.max(0, Math.ceil((at - now) / 1000));
  useEffect(() => {
    if (left === 0) return;
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [left]);
  // A new deadline counts from now, not from the last tick (before paint: no stale number shows).
  useLayoutEffect(() => setNow(Date.now()), [at]);
  return left;
}

export interface SignInProps {
  auth: SignInAuth;
  /** Shortened by stories. */
  resendDelayMs?: number;
}

type Busy = "send" | "verify" | "passkey" | "resend" | null;

/**
 * `/sign-in`: no passwords. With a passkey-capable browser, "Sign in with fingerprint" comes
 * first; otherwise (or as well) the email step sends a 6-digit code, and the code step takes it.
 * The same email carries a magic link to `/auth/verify`. `?next=` is where to go afterwards (same
 * origin only) and `?lang=` (from the landing) the language of the page and of a new profile.
 */
export function SignIn({ auth, resendDelayMs = RESEND_DELAY_MS }: SignInProps) {
  const t = useTranslations("sign_in");
  const tRoot = useTranslations();
  const toast = useToast();
  const finish = useFinishSignIn();
  const location = useLocation();
  const [params] = useSearchParams();
  const next = params.get("next");
  const lang = langFrom(params.get("lang"));
  const { locale, setLocale } = useLocale();

  // Before paint, so a visitor from the English landing never sees a Spanish frame.
  useLayoutEffect(() => {
    if (lang && lang !== locale) setLocale(lang);
  }, [lang, locale, setLocale]);

  const arrived = isSignInState(location.state) ? location.state : null;
  const [step, setStep] = useState<"email" | "code">(arrived ? "code" : "email");
  const [email, setEmail] = useState(arrived?.email ?? "");
  const [code, setCode] = useState("");
  const [error, setError] = useState<AuthErrorKey | null>(null);
  const [busy, setBusy] = useState<Busy>(null);
  const [resendAt, setResendAt] = useState(() => (arrived ? Date.now() + resendDelayMs : 0));
  const [passkeys] = useState(() => auth.passkeysAvailable());
  const resendIn = useSecondsUntil(resendAt);
  // A ref, not state: Enter and the 6th digit can both submit within one render.
  const inFlight = useRef(false);
  const emailInput = useRef<HTMLInputElement>(null);
  const codeInput = useRef<CodeInputHandle>(null);
  const focusEmailOnShow = useRef(false);
  const emailId = useId();
  const errorId = useId();

  const signedIn = useCallback(
    (user: AuthUser) => finish({ user, next, lang }),
    [finish, next, lang],
  );

  /** Runs one auth call at a time; on failure shows `toKey(error)` and returns null. */
  async function run<T>(
    kind: Exclude<Busy, null>,
    call: () => Promise<AuthResult<T>>,
    toKey: (error: { code?: string | undefined; status: number }) => AuthErrorKey = authErrorKey,
  ): Promise<T | null> {
    if (inFlight.current) return null;
    inFlight.current = true;
    setBusy(kind);
    setError(null);
    try {
      const result = await call();
      if (result.error) {
        setError(toKey(result.error));
        return null;
      }
      return result.data;
    } finally {
      inFlight.current = false;
      setBusy(null);
    }
  }

  async function sendCode(event: FormEvent) {
    event.preventDefault();
    const address = email.trim().toLowerCase();
    if (!EMAIL.test(address)) {
      setError("errors.invalid_email");
      emailInput.current?.focus();
      return;
    }
    const sent = await run("send", () => auth.sendCode(address));
    if (!sent) {
      emailInput.current?.focus();
      return;
    }
    setEmail(address);
    setCode("");
    setResendAt(Date.now() + resendDelayMs);
    setStep("code");
  }

  async function verify(candidate: string) {
    if (candidate.length !== CODE_LENGTH) return;
    const user = await run("verify", () => auth.verifyCode(email, candidate));
    if (!user) {
      // Start over in the first box; the error stays until the next try.
      setCode("");
      codeInput.current?.focus(0);
      return;
    }
    // Stays busy while the profile is read and the next page loads.
    inFlight.current = true;
    setBusy("verify");
    await signedIn(user);
  }

  async function resend() {
    const sent = await run("resend", () => auth.sendCode(email));
    if (!sent) return;
    setCode("");
    setResendAt(Date.now() + resendDelayMs);
    toast.show({ message: t("resent") });
    codeInput.current?.focus(0);
  }

  async function passkey() {
    const user = await run("passkey", () => auth.signInWithPasskey(), passkeyErrorKey);
    if (!user) return;
    inFlight.current = true;
    setBusy("passkey");
    await signedIn(user);
  }

  function changeEmail() {
    focusEmailOnShow.current = true;
    setStep("email");
    setCode("");
    setError(null);
  }

  // Back from the code step: the email field, ready to fix. (Not on first load: on a phone the
  // keyboard would cover Lukitas and the fingerprint button before anyone chose.)
  useEffect(() => {
    if (step !== "email" || !focusEmailOnShow.current) return;
    focusEmailOnShow.current = false;
    emailInput.current?.focus();
  }, [step]);

  const errorText = error ? tRoot(error) : null;

  if (step === "code") {
    return (
      <SignInScreen>
        <ScreenTitle>{t("code_title")}</ScreenTitle>
        <p className="text-center text-ink-muted">
          {t.rich("code_lead", {
            email,
            strong: (chunks) => <strong className="wrap-anywhere text-ink">{chunks}</strong>,
          })}
        </p>
        <form
          noValidate
          className="flex w-full flex-col gap-(--space-3)"
          onSubmit={(event) => {
            event.preventDefault();
            void verify(code);
          }}
        >
          <CodeInput
            ref={codeInput}
            value={code}
            onChange={(value) => {
              setCode(value);
              if (error) setError(null);
            }}
            onComplete={(value) => void verify(value)}
            invalid={error !== null}
            readOnly={busy === "verify"}
            describedBy={errorText ? errorId : undefined}
            autoFocus
          />
          {errorText && <FieldError id={errorId}>{errorText}</FieldError>}
          <PressButton
            type="submit"
            className="w-full"
            disabled={busy !== null || code.length !== CODE_LENGTH}
          >
            {busy === "verify" ? t("verifying") : t("submit_code")}
          </PressButton>
        </form>
        {/* Stacked: the countdown changes width every second and must not reflow the row. */}
        <div className="flex flex-col items-center">
          <PressButton variant="ghost" disabled={resendIn > 0 || busy !== null} onClick={resend}>
            {resendIn > 0 ? t("resend_in", { seconds: resendIn }) : t("resend")}
          </PressButton>
          <PressButton variant="ghost" disabled={busy === "verify"} onClick={changeEmail}>
            {t("change_email")}
          </PressButton>
        </div>
      </SignInScreen>
    );
  }

  const passkeyError = error === "errors.passkey_failed";
  return (
    <SignInScreen>
      <ScreenTitle>{t("title")}</ScreenTitle>
      <p className="text-center text-ink-muted">{t("lead")}</p>
      {passkeys && (
        <>
          <PressButton
            variant="secondary"
            className="w-full"
            disabled={busy !== null}
            onClick={passkey}
          >
            <FingerprintIcon />
            {busy === "passkey" ? t("passkey_busy") : t("passkey")}
          </PressButton>
          {passkeyError && errorText && <FieldError id={errorId}>{errorText}</FieldError>}
          <p className="flex w-full items-center gap-(--space-3) text-sm text-ink-muted before:h-0.5 before:flex-1 before:bg-stroke after:h-0.5 after:flex-1 after:bg-stroke">
            {t("or_email")}
          </p>
        </>
      )}
      <form noValidate className="flex w-full flex-col gap-(--space-3)" onSubmit={sendCode}>
        <label htmlFor={emailId} className="text-sm text-ink-muted">
          {t("email_label")}
        </label>
        <div className={cx("lk-input min-h-11", error && !passkeyError && "border-over")}>
          <input
            ref={emailInput}
            id={emailId}
            type="email"
            name="email"
            autoComplete="email"
            autoCapitalize="none"
            spellCheck={false}
            enterKeyHint="send"
            placeholder={t("email_placeholder")}
            value={email}
            onChange={(event) => {
              setEmail(event.target.value);
              if (error && !passkeyError) setError(null);
            }}
            aria-invalid={(error !== null && !passkeyError) || undefined}
            aria-describedby={error && !passkeyError ? errorId : undefined}
            className="min-h-9 min-w-0 flex-1 border-0 bg-transparent p-0 font-text text-[16px] text-ink outline-none placeholder:font-normal placeholder:text-ink-muted"
          />
        </div>
        {!passkeyError && errorText && <FieldError id={errorId}>{errorText}</FieldError>}
        <PressButton type="submit" className="w-full" disabled={busy !== null}>
          {busy === "send" ? t("sending") : t("send_code")}
        </PressButton>
      </form>
    </SignInScreen>
  );
}

function FingerprintIcon() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      aria-hidden="true"
    >
      <path d="M12 11v3a8 8 0 0 1-1.2 4.2" />
      <path d="M8.5 12a3.5 3.5 0 0 1 7 0v1.5a11 11 0 0 1-.9 4.4" />
      <path d="M5.3 15.5A9.6 9.6 0 0 0 5.5 12a6.5 6.5 0 0 1 11.6-4" />
      <path d="M18.4 11a6.5 6.5 0 0 1 .1 1.5c0 2.6-.4 5-1.2 7" />
      <path d="M4.3 7.6A9.5 9.5 0 0 1 12 3.5a9.5 9.5 0 0 1 3.4.6" />
      <path d="M8.9 19.8c.6-1.5 1-3.1 1.1-4.8" />
    </svg>
  );
}
