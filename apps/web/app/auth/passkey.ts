import { authClient } from "./auth-client.ts";

/**
 * Passkeys, as the web app uses them: what this browser remembers about them (a flag that gates
 * the sign-in screen's fingerprint button, and the offer's decision per user), whether to offer
 * one after a sign-in, and creating one. The sign-in itself is in `features/sign-in/auth.ts`.
 *
 * Everything remembered lives in `localStorage`, which can be missing or blocked (private mode):
 * then nothing is remembered and nothing breaks.
 */

/** What adding a passkey came to; `cancelled` is the person closing the browser's prompt. */
export type PasskeyOutcome = "added" | "cancelled" | "failed";

/** The part of `localStorage` used here. */
export type MemoryStorage = Pick<Storage, "getItem" | "setItem">;

/** Set once a passkey signed in, or was registered, in this browser. */
export const PASSKEY_USED_KEY = "lukas.passkey.used";
/** The ids of the users who made their choice about the offer ("Crear mi huella" or "Ahora no"). */
export const PASSKEY_OFFERED_KEY = "lukas.passkey.offered";

/** `localStorage`, or null where it is missing or blocked. */
function browserStorage(): MemoryStorage | null {
  try {
    return typeof localStorage === "undefined" ? null : localStorage;
  } catch {
    return null;
  }
}

function read(storage: MemoryStorage | null, key: string): string | null {
  try {
    return storage?.getItem(key) ?? null;
  } catch {
    return null;
  }
}

function write(storage: MemoryStorage | null, key: string, value: string): void {
  try {
    storage?.setItem(key, value);
  } catch {
    // Not remembered; see above.
  }
}

/** Whether this browser can use passkeys at all (WebAuthn). */
export function passkeysSupported(): boolean {
  return typeof window !== "undefined" && typeof window.PublicKeyCredential === "function";
}

/**
 * Whether the browser can offer passkeys in a text field's autofill (WebAuthn conditional
 * mediation). Checked before asking, so a browser without it makes no request at all.
 */
export async function conditionalMediationAvailable(): Promise<boolean> {
  try {
    return (
      passkeysSupported() &&
      typeof PublicKeyCredential.isConditionalMediationAvailable === "function" &&
      (await PublicKeyCredential.isConditionalMediationAvailable())
    );
  } catch {
    return false;
  }
}

/** Whether a passkey has signed in, or been registered, in this browser before. */
export function hasUsedPasskey(storage: MemoryStorage | null = browserStorage()): boolean {
  return read(storage, PASSKEY_USED_KEY) === "1";
}

/** Called after a successful passkey sign-in or registration. */
export function rememberPasskeyUsed(storage: MemoryStorage | null = browserStorage()): void {
  write(storage, PASSKEY_USED_KEY, "1");
}

function decidedIds(storage: MemoryStorage | null): string[] {
  try {
    const parsed: unknown = JSON.parse(read(storage, PASSKEY_OFFERED_KEY) ?? "[]");
    return Array.isArray(parsed) ? parsed.filter((id) => typeof id === "string") : [];
  } catch {
    return [];
  }
}

/** Whether this user already made their choice about the offer on this device. */
export function offerDecided(
  userId: string,
  storage: MemoryStorage | null = browserStorage(),
): boolean {
  return decidedIds(storage).includes(userId);
}

/** The offer is shown once per user per device: call this on either answer. */
export function rememberOfferDecided(
  userId: string,
  storage: MemoryStorage | null = browserStorage(),
): void {
  const ids = decidedIds(storage);
  if (!ids.includes(userId)) write(storage, PASSKEY_OFFERED_KEY, JSON.stringify([...ids, userId]));
}

/** What `shouldOfferPasskey` asks about; the live ones are `liveOfferDeps`. */
export interface OfferDeps {
  supported(): boolean;
  decided(userId: string): boolean;
  /** How many passkeys the signed-in user has, or null when the list can't be read. */
  passkeyCount(): Promise<number | null>;
}

/**
 * Whether to offer a passkey right after an email sign-in: this browser can use one, the person
 * has not answered the offer on this device, and they have no passkey yet (on any device). The
 * cheap local checks come first; if the list can't be read, the offer is skipped, not blocked on.
 */
export async function shouldOfferPasskey(userId: string, deps: OfferDeps): Promise<boolean> {
  if (!deps.supported() || deps.decided(userId)) return false;
  try {
    return (await deps.passkeyCount()) === 0;
  } catch {
    return false;
  }
}

export const liveOfferDeps: OfferDeps = {
  supported: passkeysSupported,
  decided: (userId) => offerDecided(userId),
  passkeyCount: async () => {
    const { data, error } = await authClient.passkey.listUserPasskeys();
    return error || !Array.isArray(data) ? null : data.length;
  },
};

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

/** Creates a passkey for the signed-in user (the browser asks for the fingerprint or face). */
export async function addPasskey(): Promise<PasskeyOutcome> {
  try {
    const { error } = await authClient.passkey.addPasskey();
    const outcome = passkeyOutcome(
      error ? { code: "code" in error ? error.code : undefined } : null,
    );
    if (outcome === "added") rememberPasskeyUsed();
    return outcome;
  } catch {
    return "failed";
  }
}
