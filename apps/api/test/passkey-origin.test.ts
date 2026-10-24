import { createHash, generateKeyPairSync, randomBytes, sign } from "node:crypto";
import { afterAll, beforeAll, describe, expect, test } from "vitest";
import { androidApkKeyHashOrigin, passkeyOrigins } from "../src/auth.ts";
import { loadConfig } from "../src/config.ts";
import { createTestApp, type TestApp } from "./harness.ts";

// Two fingerprints as release.sh prints them, and their base64url (no padding) worked out
// independently (Python: base64.urlsafe_b64encode(bytes.fromhex(...)).rstrip("=")). The first ends
// in "_" and the second starts with "-": the URL-safe alphabet, not "/" and "+".
const FINGERPRINT_A =
  "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5";
const ORIGIN_A = "android:apk-key-hash:FG3pg8VzBlDY7rmVLzT8ZBagg0LmHb6oigSWsj_PROU";
const FINGERPRINT_B =
  "FA:C6:17:45:DC:09:03:78:6F:B9:ED:E6:2A:96:2B:39:9F:73:48:F0:BB:6F:89:9B:83:32:66:75:91:03:3B:9C";
const ORIGIN_B = "android:apk-key-hash:-sYXRdwJA3hvue3mKpYrOZ9zSPC7b4mbgzJmdZEDO5w";

describe("the Android app's passkey origin", () => {
  test("is android:apk-key-hash: and the signing certificate's SHA-256 in base64url, no padding", () => {
    expect(androidApkKeyHashOrigin(FINGERPRINT_A)).toBe(ORIGIN_A);
    expect(androidApkKeyHashOrigin(FINGERPRINT_B)).toBe(ORIGIN_B);
  });

  test("reads the fingerprint in either case", () => {
    expect(androidApkKeyHashOrigin(FINGERPRINT_A.toLowerCase())).toBe(ORIGIN_A);
  });

  test("passkeys accept only the web without ANDROID_CERT_SHA256, and the app's keys with it", () => {
    const web = { WEB_URL: "https://app-lukas.example.com" };
    expect(passkeyOrigins({ ...web, ANDROID_CERT_SHA256: undefined })).toEqual([
      "https://app-lukas.example.com",
    ]);
    expect(passkeyOrigins({ ...web, ANDROID_CERT_SHA256: [FINGERPRINT_A, FINGERPRINT_B] })).toEqual(
      ["https://app-lukas.example.com", ORIGIN_A, ORIGIN_B],
    );
  });
});

describe("ANDROID_CERT_SHA256 in the config", () => {
  const dev = {
    DATABASE_URL: "postgres://lukas_app:x@db:5432/lukas",
    DATABASE_ADMIN_URL: "postgres://lukas:x@db:5432/lukas",
    BETTER_AUTH_SECRET: "s".repeat(40),
    API_URL: "https://lukas.app/api",
    WEB_URL: "https://lukas.app",
    MAIL_FROM: "Lukitas <hola@lukas.app>",
    RESEND_API_KEY: "re_123",
    NODE_ENV: "development",
  };

  test("unset or blank (the compose default) means the web only", () => {
    expect(loadConfig(dev).ANDROID_CERT_SHA256).toBeUndefined();
    expect(loadConfig({ ...dev, ANDROID_CERT_SHA256: "" }).ANDROID_CERT_SHA256).toBeUndefined();
  });

  test("is a comma-separated list, read as the web container reads it (spaces, quotes, case)", () => {
    expect(
      loadConfig({
        ...dev,
        ANDROID_CERT_SHA256: ` ${FINGERPRINT_A.toLowerCase()} ,"${FINGERPRINT_B}",`,
      }).ANDROID_CERT_SHA256,
    ).toEqual([FINGERPRINT_A, FINGERPRINT_B]);
  });

  test("refuses a value that is not a SHA-256 fingerprint, rather than a passkey that never works", () => {
    expect(() => loadConfig({ ...dev, ANDROID_CERT_SHA256: "AB:CD" })).toThrow(
      /ANDROID_CERT_SHA256/,
    );
    expect(() =>
      loadConfig({ ...dev, ANDROID_CERT_SHA256: `${FINGERPRINT_A},SHA256: ${FINGERPRINT_B}` }),
    ).toThrow(/ANDROID_CERT_SHA256/);
  });
});

// A software authenticator: just enough WebAuthn (CBOR, authenticator data, ES256) to answer the
// passkey plugin as Android's Credential Manager does, with a chosen `origin` in the client data.

const b64url = (bytes: Uint8Array) => Buffer.from(bytes).toString("base64url");

function cborHead(major: number, length: number): Buffer {
  if (length < 24) return Buffer.from([(major << 5) | length]);
  if (length < 256) return Buffer.from([(major << 5) | 24, length]);
  return Buffer.from([(major << 5) | 25, length >> 8, length & 0xff]);
}

type Cbor = number | string | Uint8Array | Map<Cbor, Cbor>;

function cbor(value: Cbor): Buffer {
  if (typeof value === "number") {
    return value >= 0 ? cborHead(0, value) : cborHead(1, -1 - value);
  }
  if (typeof value === "string") {
    const text = Buffer.from(value, "utf8");
    return Buffer.concat([cborHead(3, text.length), text]);
  }
  if (value instanceof Uint8Array) return Buffer.concat([cborHead(2, value.length), value]);
  const parts = [cborHead(5, value.size)];
  for (const [key, entry] of value) parts.push(cbor(key), cbor(entry));
  return Buffer.concat(parts);
}

function softwarePasskey(rpId: string) {
  const { privateKey, publicKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
  const jwk = publicKey.export({ format: "jwk" });
  const credentialId = randomBytes(16);
  const rpIdHash = createHash("sha256").update(rpId).digest();
  let counter = 0;
  const counterBytes = () => {
    const bytes = Buffer.alloc(4);
    bytes.writeUInt32BE(counter);
    return bytes;
  };
  const clientData = (type: string, challenge: string, origin: string) =>
    Buffer.from(
      JSON.stringify({
        type,
        challenge,
        origin,
        androidPackageName: "com.andersonlaverde.lukitas",
      }),
    );

  return {
    id: b64url(credentialId),
    register(challenge: string, origin: string) {
      const coseKey = cbor(
        new Map<Cbor, Cbor>([
          [1, 2], // kty: EC2
          [3, -7], // alg: ES256
          [-1, 1], // crv: P-256
          [-2, Buffer.from(jwk.x ?? "", "base64url")],
          [-3, Buffer.from(jwk.y ?? "", "base64url")],
        ]),
      );
      const idLength = Buffer.from([0, credentialId.length]);
      const authData = Buffer.concat([
        rpIdHash,
        Buffer.from([0x45]), // user present, user verified, attested credential data
        counterBytes(),
        Buffer.alloc(16), // AAGUID
        idLength,
        credentialId,
        coseKey,
      ]);
      const attestationObject = cbor(
        new Map<Cbor, Cbor>([
          ["fmt", "none"],
          ["attStmt", new Map()],
          ["authData", authData],
        ]),
      );
      return {
        id: b64url(credentialId),
        rawId: b64url(credentialId),
        type: "public-key",
        authenticatorAttachment: "platform",
        clientExtensionResults: {},
        response: {
          clientDataJSON: b64url(clientData("webauthn.create", challenge, origin)),
          attestationObject: b64url(attestationObject),
          transports: ["internal", "hybrid"],
        },
      };
    },
    assert(challenge: string, origin: string) {
      counter += 1;
      const authData = Buffer.concat([rpIdHash, Buffer.from([0x05]), counterBytes()]);
      const clientDataJSON = clientData("webauthn.get", challenge, origin);
      const signed = Buffer.concat([
        authData,
        createHash("sha256").update(clientDataJSON).digest(),
      ]);
      return {
        id: b64url(credentialId),
        rawId: b64url(credentialId),
        type: "public-key",
        authenticatorAttachment: "platform",
        clientExtensionResults: {},
        response: {
          clientDataJSON: b64url(clientDataJSON),
          authenticatorData: b64url(authData),
          signature: b64url(sign("sha256", signed, privateKey)),
        },
      };
    },
  };
}

/**
 * The passkey plugin answers a registration it cannot verify (a wrong origin included) with a 500
 * and this code; nothing is stored.
 */
async function expectRegistrationRefused(res: Response) {
  expect(res.status).not.toBe(200);
  expect(((await res.json()) as { code: string }).code).toBe("FAILED_TO_VERIFY_REGISTRATION");
}

/** `name=value` of the challenge cookie an options response sets, for the verify call. */
function challengeCookie(res: Response): string {
  const cookie = res.headers
    .getSetCookie()
    .map((line) => line.split(";")[0] ?? "")
    .find((pair) => pair.includes("better-auth-passkey="));
  if (!cookie) throw new Error("no passkey challenge cookie");
  return cookie;
}

describe("a passkey from the Android app (end to end)", () => {
  let t: TestApp;
  beforeAll(async () => {
    t = await createTestApp({ ANDROID_CERT_SHA256: [FINGERPRINT_A] });
  });
  afterAll(() => t?.stop());

  /** Registers a new software passkey for a fresh user, answering with `origin`. */
  async function register(email: string, origin: string) {
    const { headers } = await t.signIn(email);
    const options = await t.request("GET", "/auth/passkey/generate-register-options", { headers });
    expect(options.status).toBe(200);
    const { challenge } = (await options.json()) as { challenge: string };
    const passkey = softwarePasskey("localhost");
    // The app sends the server's origin as Origin: a request carrying a cookie needs a trusted one.
    const res = await t.request("POST", "/auth/passkey/verify-registration", {
      headers: { ...headers, cookie: challengeCookie(options), origin: "http://localhost:5173" },
      body: { response: passkey.register(challenge, origin) },
    });
    return { res, passkey };
  }

  async function signInWith(passkey: ReturnType<typeof softwarePasskey>, origin: string) {
    const options = await t.request("GET", "/auth/passkey/generate-authenticate-options");
    expect(options.status).toBe(200);
    const { challenge } = (await options.json()) as { challenge: string };
    return t.request("POST", "/auth/passkey/verify-authentication", {
      headers: { cookie: challengeCookie(options), origin: "http://localhost:5173" },
      body: { response: passkey.assert(challenge, origin) },
    });
  }

  test("registers and signs in with the app's apk-key-hash origin, and gets a bearer token", async () => {
    const { res, passkey } = await register("app-passkey@lukas.test", ORIGIN_A);
    expect(res.status).toBe(200);

    const signedIn = await signInWith(passkey, ORIGIN_A);
    expect(signedIn.status).toBe(200);
    const token = signedIn.headers.get("set-auth-token");
    expect(token).toBeTruthy();
    const me = await t.request("GET", "/v1/me", { headers: { authorization: `Bearer ${token}` } });
    expect(me.status).toBe(200);
    expect(((await me.json()) as { email: string }).email).toBe("app-passkey@lukas.test");
  });

  test("the web's own origin still works", async () => {
    const { res, passkey } = await register("web-passkey@lukas.test", "http://localhost:5173");
    expect(res.status).toBe(200);
    expect((await signInWith(passkey, "http://localhost:5173")).status).toBe(200);
  });

  test("an app signed with another key is refused, at registration and at sign-in", async () => {
    await expectRegistrationRefused((await register("other-key@lukas.test", ORIGIN_B)).res);

    const { passkey } = await register("other-key-2@lukas.test", ORIGIN_A);
    const signedIn = await signInWith(passkey, ORIGIN_B);
    expect(signedIn.status).toBe(400);
    expect(((await signedIn.json()) as { code: string }).code).toBe("AUTHENTICATION_FAILED");
    expect(signedIn.headers.get("set-auth-token")).toBeNull();
  });
});

describe("without ANDROID_CERT_SHA256", () => {
  let t: TestApp;
  beforeAll(async () => {
    t = await createTestApp();
  });
  afterAll(() => t?.stop());

  test("an app passkey is refused: the web only", async () => {
    const { headers } = await t.signIn("no-app@lukas.test");
    const options = await t.request("GET", "/auth/passkey/generate-register-options", { headers });
    const { challenge } = (await options.json()) as { challenge: string };
    const res = await t.request("POST", "/auth/passkey/verify-registration", {
      headers: { ...headers, cookie: challengeCookie(options), origin: "http://localhost:5173" },
      body: { response: softwarePasskey("localhost").register(challenge, ORIGIN_A) },
    });
    await expectRegistrationRefused(res);
  });
});
