import { describe, expect, it } from "vitest";
import {
  authErrorKey,
  destinationAfterSignIn,
  langFrom,
  passkeyErrorKey,
  retryAfterSeconds,
  signInLocale,
  verifyErrorKey,
} from "./auth.ts";

describe("authErrorKey", () => {
  it.each([
    [{ code: "INVALID_OTP", status: 400 }, "errors.invalid_code"],
    [{ code: "OTP_EXPIRED", status: 400 }, "errors.invalid_or_expired_code"],
    [{ code: "TOO_MANY_ATTEMPTS", status: 403 }, "errors.too_many_attempts"],
    [{ code: "INVALID_EMAIL", status: 400 }, "errors.invalid_email"],
    [{ code: "sign_in_not_allowed", status: 403 }, "errors.sign_in_not_allowed"],
    [{ status: 0 }, "errors.network_error"],
    [{ status: 502 }, "errors.internal_error"],
    [{ code: "SOMETHING_NEW", status: 400 }, "errors.generic"],
  ])("maps %j to %s", (error, key) => {
    expect(authErrorKey(error, "send")).toBe(key);
    expect(authErrorKey(error, "sign_in")).toBe(key);
  });

  it("tells a code-request limit (minutes) from a sign-in limit (seconds)", () => {
    expect(authErrorKey({ status: 429 }, "send")).toBe("errors.too_many_requests");
    expect(authErrorKey({ code: "TOO_MANY_REQUESTS", status: 429 }, "send")).toBe(
      "errors.too_many_requests",
    );
    expect(authErrorKey({ status: 429 }, "sign_in")).toBe("errors.too_many_sign_in_attempts");
  });
});

describe("verifyErrorKey", () => {
  it("reads every code problem on the magic link as invalid or expired", () => {
    for (const code of ["INVALID_OTP", "OTP_EXPIRED", "TOO_MANY_ATTEMPTS", "INVALID_EMAIL"]) {
      expect(verifyErrorKey({ code, status: 400 })).toBe("errors.invalid_or_expired_code");
    }
  });

  it("keeps what a retry of the same link can fix: connection, server, sign-in rate limit", () => {
    expect(verifyErrorKey({ status: 0 })).toBe("errors.network_error");
    expect(verifyErrorKey({ status: 503 })).toBe("errors.internal_error");
    expect(verifyErrorKey({ status: 429 })).toBe("errors.too_many_sign_in_attempts");
  });
});

describe("passkeyErrorKey", () => {
  it("says nothing when the person closed the browser's prompt", () => {
    expect(passkeyErrorKey({ code: "AUTH_CANCELLED", status: 400 })).toBeNull();
    expect(passkeyErrorKey({ code: "ERROR_CEREMONY_ABORTED", status: 400 })).toBeNull();
  });

  it("explains a passkey that did not work, and keeps transient problems", () => {
    expect(passkeyErrorKey({ code: "PASSKEY_NOT_FOUND", status: 400 })).toBe(
      "errors.passkey_failed",
    );
    expect(passkeyErrorKey({ status: 0 })).toBe("errors.network_error");
  });
});

describe("retryAfterSeconds", () => {
  it("reads Better Auth's X-Retry-After, or a standard Retry-After in seconds", () => {
    expect(retryAfterSeconds(new Headers({ "X-Retry-After": "7" }))).toBe(7);
    expect(retryAfterSeconds(new Headers({ "Retry-After": "2.2" }))).toBe(3);
    expect(retryAfterSeconds(new Headers({ "Retry-After": "Wed, 21 Oct 2026 07:28:00 GMT" }))).toBe(
      undefined,
    );
    expect(retryAfterSeconds(new Headers())).toBeUndefined();
  });
});

describe("destinationAfterSignIn", () => {
  it("sends someone who has not finished onboarding to /welcome", () => {
    expect(destinationAfterSignIn({ onboardingCompletedAt: null }, "/app/insights")).toBe(
      "/welcome",
    );
    expect(destinationAfterSignIn({}, null)).toBe("/welcome");
  });

  it("sends anyone to an assistant's consent first, onboarded or not", () => {
    const consent = "/oauth/consent?client_id=abc&sig=xyz";
    expect(destinationAfterSignIn({ onboardingCompletedAt: null }, consent)).toBe(consent);
  });

  it("sends an onboarded user to a same-origin next, or to /app", () => {
    const user = { onboardingCompletedAt: "2026-10-01T10:00:00.000Z" };
    expect(destinationAfterSignIn(user, "/app/insights")).toBe("/app/insights");
    expect(destinationAfterSignIn(user, null)).toBe("/app");
    expect(destinationAfterSignIn(user, "https://evil.example")).toBe("/app");
    expect(destinationAfterSignIn(user, "/.//evil.example")).toBe("/app");
  });
});

describe("langFrom", () => {
  it("accepts only the languages the app speaks", () => {
    expect(langFrom("en")).toBe("en");
    expect(langFrom("es")).toBe("es");
    expect(langFrom("it")).toBe("it");
    expect(langFrom("pt")).toBe("pt");
    expect(langFrom("fr")).toBeNull();
    expect(langFrom("EN")).toBeNull();
    expect(langFrom(null)).toBeNull();
  });
});

describe("signInLocale", () => {
  it("takes the landing's ?lang first, else the browser's language", () => {
    expect(signInLocale("es", "en-US")).toBe("es");
    expect(signInLocale("en", "es-CO")).toBe("en");
    expect(signInLocale(null, "es-CO")).toBe("es");
    expect(signInLocale(null, "en-GB")).toBe("en");
    expect(signInLocale("fr", "es-ES")).toBe("es");
  });
});
