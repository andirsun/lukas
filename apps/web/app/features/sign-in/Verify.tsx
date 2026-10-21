import { useEffect, useLayoutEffect, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router";
import { useTranslations } from "use-intl";
import { safeNext } from "../../auth/next.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { cx } from "../../ui/cx.ts";
import { PressButton } from "../../ui/PressButton.tsx";
import {
  type AuthErrorKey,
  authErrorKey,
  DEFAULT_SIGN_IN_WAIT_S,
  EMAIL,
  RETRYABLE_ERRORS,
  type SignInAuth,
  signInLocale,
  verifyErrorKey,
} from "./auth.ts";
import { CODE_LENGTH } from "./CodeInput.tsx";
import type { SignInState } from "./SignIn.tsx";
import { FieldError, ScreenTitle, SignInScreen } from "./SignInScreen.tsx";
import { useFinishSignIn } from "./use-finish-sign-in.ts";
import { useSecondsUntil } from "./use-seconds-until.ts";

const CODE = new RegExp(`^\\d{${CODE_LENGTH}}$`);

/** The path of this page; the address bar is only cleaned on it (not in a story's iframe). */
const VERIFY_PATH = "/auth/verify";

type Status =
  | { kind: "confirm" }
  | { kind: "checking" }
  | { kind: "failed"; error: AuthErrorKey; retryAt: number };

/** What the magic link carries, read once from the address bar. */
interface MagicLink {
  email: string;
  code: string;
  lang: "es" | "en";
  next: string | null;
}

/**
 * `/auth/verify?email=…&code=…&lang=…&next=…`: the magic link from the sign-in email. It works in
 * any browser (no state from the page that asked for the code) and whether someone is signed in
 * here or not, then goes on to onboarding, `next` or the app.
 *
 * Opening it spends nothing: it shows which account is about to sign in and waits for one tap.
 * So a mail scanner that opens (or even runs) the link leaves the code for its owner, and a link
 * someone else sent can't sign this browser into their account unnoticed. The code leaves the
 * address bar as soon as it is read, and the route sends no referrer.
 */
export function Verify({ auth }: { auth: SignInAuth }) {
  const t = useTranslations("verify");
  const tRoot = useTranslations();
  const navigate = useNavigate();
  const finish = useFinishSignIn();
  const [params] = useSearchParams();
  const { locale, setLocale } = useLocale();
  const [link] = useState<MagicLink>(() => ({
    email: (params.get("email") ?? "").trim().toLowerCase(),
    code: (params.get("code") ?? "").trim(),
    lang: signInLocale(
      params.get("lang"),
      typeof navigator === "undefined" ? undefined : navigator.language,
    ),
    next: params.get("next"),
  }));
  const usable = EMAIL.test(link.email) && CODE.test(link.code);

  const [status, setStatus] = useState<Status>(
    usable
      ? { kind: "confirm" }
      : { kind: "failed", error: "errors.invalid_or_expired_code", retryAt: 0 },
  );
  const [sending, setSending] = useState(false);
  const retryIn = useSecondsUntil(status.kind === "failed" ? status.retryAt : 0);

  // In the link's language before paint: the email was written in it.
  useLayoutEffect(() => {
    if (link.lang !== locale) setLocale(link.lang);
  }, [link.lang, locale, setLocale]);

  // The code is in state now: take it (and the address) out of the address bar and history.
  useEffect(() => {
    if (window.location.pathname !== VERIFY_PATH) return;
    window.history.replaceState(window.history.state, "", `${VERIFY_PATH}?lang=${link.lang}`);
  }, [link.lang]);

  async function signIn() {
    if (status.kind === "checking") return;
    setStatus({ kind: "checking" });
    const result = await auth.verifyCode(link.email, link.code);
    if (result.error) {
      const error = verifyErrorKey(result.error);
      const wait =
        error === "errors.too_many_sign_in_attempts"
          ? (result.error.retryAfter ?? DEFAULT_SIGN_IN_WAIT_S)
          : 0;
      setStatus({ kind: "failed", error, retryAt: Date.now() + wait * 1000 });
      return;
    }
    await finish({ user: result.data, next: link.next, lang: link.lang });
  }

  const signInSearch = () => {
    const search = new URLSearchParams({ lang: link.lang });
    if (link.next) search.set("next", safeNext(link.next));
    return `?${search}`;
  };

  async function sendNewCode() {
    const search = signInSearch();
    if (!EMAIL.test(link.email)) {
      navigate({ pathname: "/sign-in", search });
      return;
    }
    setSending(true);
    const result = await auth.sendCode(link.email, { locale: link.lang, next: link.next });
    setSending(false);
    if (result.error) {
      setStatus({ kind: "failed", error: authErrorKey(result.error, "send"), retryAt: 0 });
      return;
    }
    const state: SignInState = { email: link.email, codeSent: true };
    navigate({ pathname: "/sign-in", search }, { state });
  }

  if (status.kind !== "failed") {
    const checking = status.kind === "checking";
    return (
      <SignInScreen>
        <ScreenTitle>
          {t.rich("confirm_title", {
            email: link.email,
            strong: (chunks) => <span className="wrap-anywhere">{chunks}</span>,
          })}
        </ScreenTitle>
        <p className="text-center text-ink-muted">{t("confirm_lead")}</p>
        <PressButton className="w-full" disabled={checking} onClick={signIn}>
          {checking ? tRoot("sign_in.verifying") : t("continue")}
        </PressButton>
        <Link
          to={{ pathname: "/sign-in", search: `?lang=${link.lang}` }}
          className={cx(
            "lk-btn lk-btn-ghost inline-flex min-h-11 min-w-11 items-center justify-center",
            checking && "pointer-events-none opacity-50",
          )}
          aria-disabled={checking || undefined}
        >
          {t("not_me")}
        </Link>
      </SignInScreen>
    );
  }

  const retryable = RETRYABLE_ERRORS.has(status.error);
  return (
    <SignInScreen mood="worried">
      <ScreenTitle>{t("failed_title")}</ScreenTitle>
      <div className="w-full text-center">
        <FieldError id="verify-error">{tRoot(status.error)}</FieldError>
      </div>
      {retryable && (
        <PressButton className="w-full" disabled={retryIn > 0 || sending} onClick={signIn}>
          {retryIn > 0 ? t("retry_in", { seconds: retryIn }) : tRoot("common.retry")}
        </PressButton>
      )}
      <PressButton
        variant={retryable ? "secondary" : "primary"}
        className="w-full"
        disabled={sending}
        onClick={sendNewCode}
      >
        {t("send_new_code")}
      </PressButton>
    </SignInScreen>
  );
}
