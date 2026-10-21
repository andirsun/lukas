import { authClient } from "../../auth/auth-client.ts";
import { safeNext } from "../../auth/next.ts";
import { detectLocale, type Locale } from "../../i18n/format.ts";

/** Good enough to catch typos; the server has the final word. */
export const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Who signed in, as Better Auth returns them (with the extra fields the API declares). */
export interface AuthUser {
  id: string;
  email: string;
  onboardingCompletedAt?: string | Date | null;
}

/** A failed auth call: Better Auth's error `code` when it sent one, and the HTTP status (0: no response). */
export interface AuthFailure {
  code?: string | undefined;
  status: number;
  /** Seconds until a rate-limited call may be tried again (`X-Retry-After`), when the server said. */
  retryAfter?: number | undefined;
}

export type AuthResult<T> = { data: T; error: null } | { data: null; error: AuthFailure };

/** What the API needs to write the email: its language, and where the magic link goes after. */
export interface CodeHints {
  locale: Locale;
  /** Same-origin path; the API checks it again and the link's page screens it with `safeNext`. */
  next?: string | null | undefined;
}

/**
 * What the sign-in screens need from the auth server. The screens take it as a prop, so stories
 * can stand in for Better Auth; the routes pass `liveSignInAuth`.
 */
export interface SignInAuth {
  /** Emails a 6-digit code and a magic link (one email carries both). */
  sendCode(email: string, hints: CodeHints): Promise<AuthResult<true>>;
  /** Signs in (or up) with the code; sets the session cookie. */
  verifyCode(email: string, code: string): Promise<AuthResult<AuthUser>>;
  /** Whether this browser can use passkeys at all (WebAuthn). */
  passkeysAvailable(): boolean;
  /** Asks the browser for a passkey for this site and signs in with it. */
  signInWithPasskey(): Promise<AuthResult<AuthUser>>;
}

/** The catalog keys sign-in shows for a failure. */
export type AuthErrorKey =
  | "errors.invalid_code"
  | "errors.invalid_or_expired_code"
  | "errors.too_many_attempts"
  | "errors.invalid_email"
  | "errors.too_many_requests"
  | "errors.too_many_sign_in_attempts"
  | "errors.passkey_failed"
  | "errors.network_error"
  | "errors.internal_error"
  | "errors.generic";

/** Better Auth's error codes (emailOTP plugin and core) → the catalog's `errors.*` keys. */
const CODE_KEYS: Record<string, AuthErrorKey> = {
  INVALID_OTP: "errors.invalid_code",
  OTP_EXPIRED: "errors.invalid_or_expired_code",
  TOO_MANY_ATTEMPTS: "errors.too_many_attempts",
  INVALID_EMAIL: "errors.invalid_email",
};

/** Errors about the code itself: the boxes are marked invalid and emptied. */
export const CODE_ERRORS: ReadonlySet<AuthErrorKey> = new Set([
  "errors.invalid_code",
  "errors.invalid_or_expired_code",
  "errors.too_many_attempts",
]);

/** Errors that trying the same thing again (after a short wait) can fix. */
export const RETRYABLE_ERRORS: ReadonlySet<AuthErrorKey> = new Set([
  "errors.network_error",
  "errors.internal_error",
  "errors.too_many_sign_in_attempts",
]);

/** When the server gives no `X-Retry-After` on a sign-in 429 (its window is 10 s). */
export const DEFAULT_SIGN_IN_WAIT_S = 10;

/**
 * The message for a failed auth call. A 429 means different things per action: asking for a
 * code is limited per 10 minutes (and per email per 15), signing in per 10 seconds.
 */
export function authErrorKey(error: AuthFailure, action: "send" | "sign_in"): AuthErrorKey {
  if (error.status === 0) return "errors.network_error";
  if (error.status === 429) {
    return action === "send" ? "errors.too_many_requests" : "errors.too_many_sign_in_attempts";
  }
  if (error.status >= 500) return "errors.internal_error";
  return (error.code && CODE_KEYS[error.code]) || "errors.generic";
}

/**
 * The message for a passkey sign-in that did not work, or null when the person just closed the
 * browser's prompt (nothing to explain). Otherwise the browser's errors (no passkey for this site,
 * timed out) and the server's (unknown passkey) all mean the same: try again or use the email.
 */
export function passkeyErrorKey(error: AuthFailure): AuthErrorKey | null {
  if (error.code === "AUTH_CANCELLED" || error.code === "ERROR_CEREMONY_ABORTED") return null;
  const key = authErrorKey(error, "sign_in");
  return RETRYABLE_ERRORS.has(key) ? key : "errors.passkey_failed";
}

/**
 * The message for a magic link that did not sign in. Whatever the server said about the code
 * (wrong, expired, used up), the visitor can only ask for a new one; a lost connection, a server
 * error or the sign-in rate limit keep their own message, since retrying the link can fix those.
 */
export function verifyErrorKey(error: AuthFailure): AuthErrorKey {
  const key = authErrorKey(error, "sign_in");
  return RETRYABLE_ERRORS.has(key) ? key : "errors.invalid_or_expired_code";
}

/** Where to go once signed in: onboarding first, then `next` (same-origin only) or the app. */
export function destinationAfterSignIn(
  user: { onboardingCompletedAt?: string | Date | null | undefined },
  next: string | null,
): string {
  return user.onboardingCompletedAt == null ? "/welcome" : safeNext(next);
}

/** `?lang=` as set by the landing's call to action: only a language the app speaks. */
export function langFrom(value: string | null): Locale | null {
  return value === "es" || value === "en" ? value : null;
}

/**
 * The language of the sign-in pages and of a new profile: the page they came from (`?lang=`),
 * else the browser's (spec §2.1).
 */
export function signInLocale(lang: string | null, navigatorLanguage: string | undefined): Locale {
  return langFrom(lang) ?? detectLocale(navigatorLanguage);
}

interface BetterAuthResult<T> {
  data: T | null;
  error: { code?: string | undefined; status: number } | null;
}

/** What Better Auth's client passes through to `fetch`: here, to read the 429's retry header. */
interface FetchOptions {
  headers?: Record<string, string>;
  onError?: (context: { response: Response }) => void;
}

/** Seconds from `X-Retry-After` (Better Auth) or `Retry-After` (seconds form), if usable. */
export function retryAfterSeconds(headers: Headers): number | undefined {
  const raw = headers.get("x-retry-after") ?? headers.get("retry-after");
  const seconds = raw === null ? Number.NaN : Number(raw);
  return Number.isFinite(seconds) && seconds > 0 ? Math.ceil(seconds) : undefined;
}

/** Better Auth's `{ data, error }`, and a thrown `fetch` (no connection), as an `AuthResult`. */
async function settle<T, R>(
  call: (fetchOptions: FetchOptions) => Promise<BetterAuthResult<T>>,
  pick: (data: T) => R,
  headers?: Record<string, string>,
): Promise<AuthResult<R>> {
  let retryAfter: number | undefined;
  const fetchOptions: FetchOptions = {
    ...(headers ? { headers } : {}),
    onError: ({ response }) => {
      retryAfter = retryAfterSeconds(response.headers);
    },
  };
  try {
    const { data, error } = await call(fetchOptions);
    if (error || data == null) {
      return {
        data: null,
        error: { code: error?.code, status: error?.status ?? 500, retryAfter },
      };
    }
    return { data: pick(data), error: null };
  } catch {
    return { data: null, error: { status: 0 } };
  }
}

/** The headers the API reads to write the email (see apps/api/src/auth.ts). */
function hintHeaders({ locale, next }: CodeHints): Record<string, string> {
  return { "x-lukas-locale": locale, ...(next ? { "x-lukas-next": safeNext(next) } : {}) };
}

/** The real thing: Better Auth's emailOTP and passkey plugins under /api/auth. */
export const liveSignInAuth: SignInAuth = {
  sendCode: (email, hints) =>
    settle(
      (fetchOptions) =>
        authClient.emailOtp.sendVerificationOtp({ email, type: "sign-in", fetchOptions }),
      () => true as const,
      hintHeaders(hints),
    ),
  verifyCode: (email, code) =>
    settle(
      (fetchOptions) => authClient.signIn.emailOtp({ email, otp: code, fetchOptions }),
      (data) => data.user as AuthUser,
    ),
  passkeysAvailable: () =>
    typeof window !== "undefined" && typeof window.PublicKeyCredential === "function",
  signInWithPasskey: () =>
    settle(
      (fetchOptions) => authClient.signIn.passkey({ fetchOptions }),
      (data) => (data as { user: AuthUser }).user,
    ),
};
