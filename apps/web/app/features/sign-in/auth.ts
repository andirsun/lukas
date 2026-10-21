import { authClient } from "../../auth/auth-client.ts";
import { safeNext } from "../../auth/next.ts";
import type { Locale } from "../../i18n/format.ts";

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
}

export type AuthResult<T> = { data: T; error: null } | { data: null; error: AuthFailure };

/**
 * What the sign-in screens need from the auth server. The screens take it as a prop, so stories
 * can stand in for Better Auth; the routes pass `liveSignInAuth`.
 */
export interface SignInAuth {
  /** Emails a 6-digit code and a magic link (one email carries both). */
  sendCode(email: string): Promise<AuthResult<true>>;
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

/** The message for a failed code request or code check. */
export function authErrorKey(error: AuthFailure): AuthErrorKey {
  if (error.status === 0) return "errors.network_error";
  if (error.status === 429) return "errors.too_many_requests";
  if (error.status >= 500) return "errors.internal_error";
  return (error.code && CODE_KEYS[error.code]) || "errors.generic";
}

/**
 * The message for a passkey sign-in that did not work. The browser's own errors (cancelled, no
 * passkey for this site, timed out) and the server's (unknown passkey) all mean the same to the
 * visitor: try again or use the email.
 */
export function passkeyErrorKey(error: AuthFailure): AuthErrorKey {
  const key = authErrorKey(error);
  return key === "errors.network_error" || key === "errors.internal_error"
    ? key
    : "errors.passkey_failed";
}

/**
 * The message for a magic link that did not sign in. Whatever the server said about the code
 * (wrong, expired, used up), the visitor can only ask for a new one; a lost connection, a server
 * error or the rate limit keep their own message, since waiting or retrying can fix those.
 */
export function verifyErrorKey(error: AuthFailure): AuthErrorKey {
  const key = authErrorKey(error);
  return key === "errors.network_error" ||
    key === "errors.internal_error" ||
    key === "errors.too_many_requests"
    ? key
    : "errors.invalid_or_expired_code";
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

interface BetterAuthResult<T> {
  data: T | null;
  error: { code?: string | undefined; status: number } | null;
}

/** Better Auth's `{ data, error }`, and a thrown `fetch` (no connection), as an `AuthResult`. */
async function settle<T, R>(
  call: () => Promise<BetterAuthResult<T>>,
  pick: (data: T) => R,
): Promise<AuthResult<R>> {
  try {
    const { data, error } = await call();
    if (error || data == null) {
      return { data: null, error: { code: error?.code, status: error?.status ?? 500 } };
    }
    return { data: pick(data), error: null };
  } catch {
    return { data: null, error: { status: 0 } };
  }
}

/** The real thing: Better Auth's emailOTP and passkey plugins under /api/auth. */
export const liveSignInAuth: SignInAuth = {
  sendCode: (email) =>
    settle(
      () => authClient.emailOtp.sendVerificationOtp({ email, type: "sign-in" }),
      () => true as const,
    ),
  verifyCode: (email, code) =>
    settle(
      () => authClient.signIn.emailOtp({ email, otp: code }),
      (data) => data.user as AuthUser,
    ),
  passkeysAvailable: () =>
    typeof window !== "undefined" && typeof window.PublicKeyCredential === "function",
  signInWithPasskey: () =>
    settle(
      () => authClient.signIn.passkey(),
      (data) => (data as { user: AuthUser }).user,
    ),
};
