import { authClient } from "../../auth/auth-client.ts";

/** What adding a passkey came to; `cancelled` is the person closing the browser's prompt. */
export type PasskeyOutcome = "added" | "cancelled" | "failed";

/** The onboarding's passkey offer, as a prop so stories can stand in for the browser. */
export interface PasskeyAdder {
  /** Whether this browser can use passkeys at all (WebAuthn). */
  available(): boolean;
  add(): Promise<PasskeyOutcome>;
}

/**
 * The browser's and Better Auth's error codes when registering. Closing the prompt (or letting it
 * time out: browsers report both as `NotAllowedError`, passed through by SimpleWebAuthn) is not a
 * failure worth a message, as on sign-in. A passkey this device already has counts as added.
 */
export function passkeyOutcome(error: { code?: string | undefined } | null): PasskeyOutcome {
  if (!error) return "added";
  switch (error.code) {
    case "AUTH_CANCELLED":
    case "ERROR_CEREMONY_ABORTED":
    case "ERROR_PASSTHROUGH_SEE_CAUSE_PROPERTY":
      return "cancelled";
    case "ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED":
      return "added";
    default:
      return "failed";
  }
}

/** The real thing: Better Auth's passkey plugin, for the signed-in user. */
export const livePasskeys: PasskeyAdder = {
  available: () =>
    typeof window !== "undefined" && typeof window.PublicKeyCredential === "function",
  add: async () => {
    try {
      const { error } = await authClient.passkey.addPasskey();
      if (!error) return "added";
      return passkeyOutcome("code" in error ? { code: error.code } : {});
    } catch {
      return "failed";
    }
  },
};
