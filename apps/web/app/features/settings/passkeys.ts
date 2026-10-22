import { authClient } from "../../auth/auth-client.ts";
import {
  addPasskey,
  forgetPasskeyUsed,
  type PasskeyOutcome,
  passkeysSupported,
} from "../../auth/passkey.ts";

/** One of the person's passkeys, as settings lists it. */
export interface PasskeyItem {
  id: string;
  /** The name it was given, if any. */
  name: string | null;
  /** When it was created (ISO). */
  createdAt: string;
  /** Saved in a synced password manager (Google, iCloud…), not only on one device. */
  synced: boolean;
}

/** What settings does with passkeys, as a prop so stories can stand in for Better Auth and WebAuthn. */
export interface PasskeysApi {
  /** Whether this browser can create one (WebAuthn). Listing and deleting work anyway. */
  supported(): boolean;
  /** The signed-in user's passkeys, oldest first; throws when they can't be read. */
  list(): Promise<PasskeyItem[]>;
  /** Creates one; the browser asks for the fingerprint or face. */
  add(): Promise<PasskeyOutcome>;
  /** Deletes one; throws when the server says no. With `last`, this browser forgets it used one. */
  remove(id: string, options: { last: boolean }): Promise<void>;
}

/** Better Auth's passkey plugin, for the signed-in user. */
export const livePasskeys: PasskeysApi = {
  supported: passkeysSupported,
  list: async () => {
    const { data, error } = await authClient.passkey.listUserPasskeys();
    if (error || !Array.isArray(data)) throw new Error("passkeys_unavailable");
    return data
      .map((passkey) => ({
        id: passkey.id,
        name: passkey.name ?? null,
        createdAt: new Date(passkey.createdAt).toISOString(),
        synced: Boolean(passkey.backedUp),
      }))
      .sort((a, b) => (a.createdAt < b.createdAt ? -1 : 1));
  },
  add: addPasskey,
  remove: async (id, { last }) => {
    const { error } = await authClient.passkey.deletePasskey({ id });
    if (error) throw new Error("passkey_delete_failed");
    // The sign-in screen offers the fingerprint only where one was used; with none left it can't work.
    if (last) forgetPasskeyUsed();
  },
};
