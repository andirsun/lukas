import { describe, expect, it, vi } from "vitest";
import {
  forgetPasskeyUsed,
  hasUsedPasskey,
  type OfferDeps,
  offerDecided,
  passkeyOutcome,
  rememberOfferDecided,
  rememberPasskeyUsed,
  shouldOfferPasskey,
} from "./passkey.ts";

/** A `Storage` stand-in: the unit tests run in Node, which has none. */
function memoryStorage(initial: Record<string, string> = {}) {
  const data = new Map(Object.entries(initial));
  return {
    getItem: (key: string) => data.get(key) ?? null,
    setItem: (key: string, value: string) => void data.set(key, value),
    data,
  };
}

const blockedStorage = {
  getItem: () => {
    throw new Error("blocked");
  },
  setItem: () => {
    throw new Error("blocked");
  },
};

describe("the passkey flag of this browser", () => {
  it("is off until a passkey signed in or was registered here", () => {
    const storage = memoryStorage();
    expect(hasUsedPasskey(storage)).toBe(false);
    rememberPasskeyUsed(storage);
    expect(hasUsedPasskey(storage)).toBe(true);
  });

  it("is off, and nothing throws, when storage is missing or blocked", () => {
    expect(hasUsedPasskey(null)).toBe(false);
    expect(() => rememberPasskeyUsed(null)).not.toThrow();
    expect(hasUsedPasskey(blockedStorage)).toBe(false);
    expect(() => rememberPasskeyUsed(blockedStorage)).not.toThrow();
  });

  it("is off again once the last passkey is deleted", () => {
    const storage = memoryStorage({ "lukas.passkey.used": "1" });
    forgetPasskeyUsed(storage);
    expect(hasUsedPasskey(storage)).toBe(false);
    expect(() => forgetPasskeyUsed(blockedStorage)).not.toThrow();
  });
});

describe("the offer's memory", () => {
  it("remembers a decision per user, on this device", () => {
    const storage = memoryStorage();
    expect(offerDecided("u1", storage)).toBe(false);
    rememberOfferDecided("u1", storage);
    expect(offerDecided("u1", storage)).toBe(true);
    expect(offerDecided("u2", storage)).toBe(false);
    rememberOfferDecided("u2", storage);
    rememberOfferDecided("u2", storage);
    expect(offerDecided("u1", storage)).toBe(true);
    expect(JSON.parse(storage.data.get("lukas.passkey.offered") ?? "[]")).toEqual(["u1", "u2"]);
  });

  it("treats damaged or blocked storage as nothing decided", () => {
    expect(offerDecided("u1", memoryStorage({ "lukas.passkey.offered": "{oops" }))).toBe(false);
    expect(offerDecided("u1", memoryStorage({ "lukas.passkey.offered": '{"a":1}' }))).toBe(false);
    expect(offerDecided("u1", null)).toBe(false);
    expect(offerDecided("u1", blockedStorage)).toBe(false);
    expect(() => rememberOfferDecided("u1", blockedStorage)).not.toThrow();
    // Damaged data is replaced, not appended to.
    const storage = memoryStorage({ "lukas.passkey.offered": "{oops" });
    rememberOfferDecided("u1", storage);
    expect(offerDecided("u1", storage)).toBe(true);
  });
});

describe("shouldOfferPasskey", () => {
  const deps = (overrides: Partial<OfferDeps> = {}): OfferDeps => ({
    supported: () => true,
    decided: () => false,
    passkeyCount: vi.fn(async () => 0),
    ...overrides,
  });

  it("offers to someone with no passkey who has not decided yet", async () => {
    expect(await shouldOfferPasskey("u1", deps())).toBe(true);
  });

  it("does not offer where WebAuthn is unsupported, and does not even ask the server", async () => {
    const d = deps({ supported: () => false });
    expect(await shouldOfferPasskey("u1", d)).toBe(false);
    expect(d.passkeyCount).not.toHaveBeenCalled();
  });

  it("does not offer twice: a decision on this device is final", async () => {
    const d = deps({ decided: (id) => id === "u1" });
    expect(await shouldOfferPasskey("u1", d)).toBe(false);
    expect(d.passkeyCount).not.toHaveBeenCalled();
    expect(await shouldOfferPasskey("u2", d)).toBe(true);
  });

  it("does not offer once a passkey exists", async () => {
    expect(await shouldOfferPasskey("u1", deps({ passkeyCount: async () => 1 }))).toBe(false);
  });

  it("does not offer, and does not throw, when the passkey list can't be read", async () => {
    expect(await shouldOfferPasskey("u1", deps({ passkeyCount: async () => null }))).toBe(false);
    expect(
      await shouldOfferPasskey(
        "u1",
        deps({
          passkeyCount: async () => {
            throw new Error("offline");
          },
        }),
      ),
    ).toBe(false);
  });
});

describe("passkeyOutcome", () => {
  it("is added without an error, and for a passkey this device already has", () => {
    expect(passkeyOutcome(null)).toBe("added");
    expect(passkeyOutcome({ code: "ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED" })).toBe("added");
  });

  it("is cancelled when the person closed the browser's prompt", () => {
    for (const code of [
      "AUTH_CANCELLED",
      "ERROR_CEREMONY_ABORTED",
      "ERROR_PASSTHROUGH_SEE_CAUSE_PROPERTY",
    ]) {
      expect(passkeyOutcome({ code }), code).toBe("cancelled");
    }
  });

  it("is failed for anything else", () => {
    expect(passkeyOutcome({ code: "UNKNOWN_ERROR" })).toBe("failed");
    expect(passkeyOutcome({})).toBe("failed");
  });
});
