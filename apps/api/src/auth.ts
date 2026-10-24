import { createHash, randomInt, randomUUID, timingSafeEqual } from "node:crypto";
import { oauthProvider } from "@better-auth/oauth-provider";
import { passkey } from "@better-auth/passkey";
import { defaultCurrencyFor, isValidTimeZone } from "@lukas/core";
import {
  accounts,
  emailThrottle,
  schema,
  user as userTable,
  verification,
  withUser,
} from "@lukas/db";
import { eq, sql } from "@lukas/db/orm";
import { APIError, betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { createAuthMiddleware } from "better-auth/api";
import { anonymous, bearer, emailOTP, jwt } from "better-auth/plugins";
import { apiPathPrefix, type Config } from "./config.ts";
import type { AppDeps } from "./deps.ts";
import { claimEmail, signInEmail } from "./emails/sign-in.ts";
import { stampGuestActivity } from "./services/guest-cleanup.ts";

export const OAUTH_SCOPES = ["finance:read", "finance:write", "offline_access"] as const;
export const CODE_TTL_SECONDS = 600;
/** Wrong tries a code survives: the third wrong one uses it up. */
export const CODE_ATTEMPTS = 3;
const EMAIL_WINDOW_MS = 15 * 60 * 1000;
const EMAILS_PER_WINDOW = 5;
/** ES256 then RS256 (COSE ids), offered when a passkey is created. */
const PASSKEY_ALGORITHMS = [
  { alg: -7, type: "public-key" },
  { alg: -257, type: "public-key" },
] as const;

/** Where guests' placeholder emails live: the `.invalid` TLD never resolves, and nothing is mailed there. */
export const GUEST_EMAIL_DOMAIN = "guest.lukitas.invalid";

/**
 * Whether `email` may ask for a sign-in code: always, unless an allowlist is configured; never for
 * an address under `.invalid` (a guest's placeholder, which can't receive the code anyway).
 */
export function isSignInAllowed(config: Pick<Config, "SIGN_IN_ALLOWLIST">, email: string): boolean {
  const address = email.trim().toLowerCase();
  if (address.replace(/\.+$/, "").endsWith(".invalid")) return false;
  const list = config.SIGN_IN_ALLOWLIST;
  return !list || list.includes(address);
}

/** The refusal: the web shows `errors.sign_in_not_allowed` for this code. */
const signInNotAllowed = () =>
  new APIError("FORBIDDEN", {
    code: "sign_in_not_allowed",
    message: "Sign-in is not open to this address",
  });

/** The refusal when GUEST_SIGNUP is off: the web and the app show `errors.guest_signup_disabled`. */
const guestSignupDisabled = () =>
  new APIError("FORBIDDEN", {
    code: "guest_signup_disabled",
    message: "Guest sign-up is turned off on this install",
  });

/** Counts sign-in emails per address in a 15-minute window; returns the count including this one. */
export async function bumpEmailThrottle(deps: AppDeps, email: string): Promise<number> {
  const now = new Date();
  // Raw SQL fragments need ISO strings; postgres-js does not serialize Date inside them.
  const nowSql = sql`${now.toISOString()}::timestamptz`;
  const windowOpen = sql`${new Date(now.getTime() - EMAIL_WINDOW_MS).toISOString()}::timestamptz`;
  const [row] = await deps.db
    .insert(emailThrottle)
    .values({ email, windowStart: now, count: 1 })
    .onConflictDoUpdate({
      target: emailThrottle.email,
      set: {
        windowStart: sql`case when ${emailThrottle.windowStart} < ${windowOpen} then ${nowSql} else ${emailThrottle.windowStart} end`,
        count: sql`case when ${emailThrottle.windowStart} < ${windowOpen} then 1 else ${emailThrottle.count} + 1 end`,
      },
    })
    .returning({ count: emailThrottle.count });
  return row?.count ?? 1;
}

/** Counts one more email to `email` and says whether that goes over the per-email limit. */
export async function overEmailLimit(deps: AppDeps, email: string): Promise<boolean> {
  return (await bumpEmailThrottle(deps, email)) > EMAILS_PER_WINDOW;
}

/**
 * Claim codes (spec §4.2): stored like emailOTP's sign-in codes, in Better Auth's `verification`
 * table as `<sha-256, base64url>:<wrong tries>` (what `storeOTP: "hashed"` writes), under an
 * identifier that ties the code to both the guest and the email.
 */
const claimCodeId = (userId: string, email: string) => `claim-email-otp-${userId}-${email}`;
const claimCodePrefix = (userId: string) => `claim-email-otp-${userId}-`;
const hashCode = (code: string) => createHash("sha256").update(code).digest("base64url");

/** Stores a fresh claim code for this guest and email (replacing any earlier one); returns it. */
export async function issueClaimCode(deps: AppDeps, userId: string, email: string) {
  const code = String(randomInt(0, 1_000_000)).padStart(6, "0");
  const identifier = claimCodeId(userId, email);
  await deps.db.transaction(async (tx) => {
    await tx.delete(verification).where(eq(verification.identifier, identifier));
    await tx.insert(verification).values({
      id: randomUUID(),
      identifier,
      value: `${hashCode(code)}:0`,
      expiresAt: new Date(Date.now() + CODE_TTL_SECONDS * 1000),
    });
  });
  return code;
}

/**
 * What became of a claim code, told apart as sign-in tells them apart: `ok` (it matched and is
 * now used), `wrong` (tries left), `exhausted` (this was the last wrong try, or there were none
 * left), `expired`, or `missing` (never sent, already used, or sent for another guest or email).
 */
export type ClaimCodeResult = "ok" | "wrong" | "exhausted" | "expired" | "missing";

/**
 * Uses up this guest's claim code for `email` if `code` matches, as emailOTP's atomic verify does:
 * the row is taken out first, so a code is accepted once however many requests race; a wrong
 * code puts it back with one more wrong try. A used-up code stays (and keeps answering
 * `exhausted`) until it expires or a new one replaces it.
 */
export async function consumeClaimCode(
  deps: AppDeps,
  userId: string,
  email: string,
  code: string,
): Promise<ClaimCodeResult> {
  const identifier = claimCodeId(userId, email);
  return deps.db.transaction(async (tx) => {
    const [row] = await tx
      .delete(verification)
      .where(eq(verification.identifier, identifier))
      .returning()
      .then((rows) => rows.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()));
    if (!row) return "missing";
    if (row.expiresAt.getTime() <= Date.now()) return "expired";
    const colon = row.value.lastIndexOf(":");
    const hash = row.value.slice(0, colon);
    const tries = Number.parseInt(row.value.slice(colon + 1), 10) || 0;
    const putBack = (wrongTries: number) =>
      tx.insert(verification).values({
        id: randomUUID(),
        identifier,
        value: `${hash}:${wrongTries}`,
        expiresAt: row.expiresAt,
      });
    if (tries >= CODE_ATTEMPTS) {
      await putBack(tries);
      return "exhausted";
    }
    const given = Buffer.from(hashCode(code));
    const stored = Buffer.from(hash);
    if (given.length === stored.length && timingSafeEqual(given, stored)) return "ok";
    await putBack(tries + 1);
    return tries + 1 >= CODE_ATTEMPTS ? "exhausted" : "wrong";
  });
}

/** Drops every claim code this user still has (once an email is claimed, none is needed). */
export async function dropClaimCodes(deps: AppDeps, userId: string) {
  await deps.db
    .delete(verification)
    .where(sql`starts_with(${verification.identifier}, ${claimCodePrefix(userId)})`);
}

/** Mails a claim code, in the guest's language, with the sign-in email's layout and no link. */
export async function sendClaimCode(
  deps: AppDeps,
  input: { email: string; code: string; locale: string },
) {
  const mail = claimEmail({
    code: input.code,
    locale: asLocale(input.locale) ?? "es",
    webUrl: deps.config.WEB_URL,
    expiresInMinutes: Math.ceil(CODE_TTL_SECONDS / 60),
  });
  await deps.mailer.send({ to: input.email, ...mail });
}

type Locale = "es" | "en";

/** Headers the web app sends with a code request: the page's language and where to go after. */
export const LOCALE_HINT_HEADER = "x-lukas-locale";
export const NEXT_HINT_HEADER = "x-lukas-next";
/** The device's IANA time zone, which the app sends with guest sign-up (and every request). */
export const TIMEZONE_HINT_HEADER = "x-lukas-timezone";
/**
 * `x-lukas-client: android`: the request is made by the Android app, from a screen the person is
 * using. A sign-in started this way marks its magic link `from=app`, so the web page the link opens
 * offers to open the app. (The timezone header does not say it: the widget's and the notices'
 * requests send it too.)
 */
export const CLIENT_HEADER = "x-lukas-client";
export const CLIENT_ANDROID = "android";
/**
 * `x-lukas-background: 1`: the request is made by a job the person did not start (the Android
 * widget's refresh, the local notices). The session is read as usual but never refreshed, so such
 * a request does not count as activity: `session.updatedAt` and `expiresAt` stay as they were, and
 * the guest cleanup (spec §4.4, 60 days idle) is not postponed by a phone that only runs jobs.
 */
export const BACKGROUND_HEADER = "x-lukas-background";

const asLocale = (value: string | null | undefined): Locale | null =>
  value === "es" || value === "en" ? value : null;

/**
 * The language and region of a BCP 47 tag as phones and browsers send it: `en-US`, `es-CO`, `EN-gb`,
 * or Java's `en_US`. Nothing for a value that is not a tag.
 */
export function parseLanguageTag(tag: string | null | undefined): {
  language: string | undefined;
  region: string | undefined;
} {
  try {
    const parsed = new Intl.Locale((tag ?? "").trim().replaceAll("_", "-"));
    return { language: parsed.language, region: parsed.region };
  } catch {
    return { language: undefined, region: undefined };
  }
}

/** The first of es/en in an Accept-Language header, by quality; null if it names neither. */
export function localeFromAcceptLanguage(header: string | null | undefined): Locale | null {
  const ranked = (header ?? "")
    .split(",")
    .map((part, index) => {
      const [tag = "", ...params] = part.trim().toLowerCase().split(";");
      const q = Number(params.find((p) => p.trim().startsWith("q="))?.split("=")[1] ?? 1);
      return { primary: tag.split("-")[0], q: Number.isFinite(q) ? q : 0, index };
    })
    .filter((entry) => entry.primary && entry.q > 0)
    .sort((a, b) => b.q - a.q || a.index - b.index);
  return asLocale(ranked[0]?.primary);
}

/**
 * The runtime's own spelling of a valid zone: `america/bogota` → `America/Bogota`, `US/Eastern` →
 * `America/New_York`. Stored as typed, a zone in another case would miss the currency rule.
 */
const canonicalTimeZone = (zone: string) =>
  new Intl.DateTimeFormat(undefined, { timeZone: zone }).resolvedOptions().timeZone;

/**
 * A new guest's profile defaults, from the device's headers: the time zone from `x-lukas-timezone`
 * (a named IANA zone in its canonical spelling, else UTC); the language from `x-lukas-locale` (es
 * or en, as a bare language or a tag like `es-CO`), else Accept-Language, else Spanish; and the
 * region that tag names, which the currency rule reads as the web reads the browser's languages.
 */
export function guestDefaults(headers: Headers | undefined): {
  timezone: string;
  locale: Locale;
  region: string | undefined;
} {
  const zone = headers?.get(TIMEZONE_HINT_HEADER)?.trim() ?? "";
  const { language, region } = parseLanguageTag(headers?.get(LOCALE_HINT_HEADER));
  return {
    timezone: isValidTimeZone(zone) ? canonicalTimeZone(zone) : "UTC",
    locale: asLocale(language) ?? localeFromAcceptLanguage(headers?.get("accept-language")) ?? "es",
    region,
  };
}

/** Whether a request comes from the app: only the app sends `x-lukas-timezone`. */
const fromDevice = (headers: Headers | undefined) => headers?.has(TIMEZONE_HINT_HEADER) ?? false;

/**
 * The language of a sign-in email: the profile's for an existing user; for a new address, the
 * language of `x-lukas-locale` (the web sends `es` or `en`, the app the phone's tag, such as
 * `en-US`), else the browser's Accept-Language, else Spanish.
 */
async function localeFor(deps: AppDeps, email: string, headers: Headers | undefined) {
  const [row] = await deps.db
    .select({ locale: userTable.locale })
    .from(userTable)
    .where(eq(userTable.email, email));
  if (row) return asLocale(row.locale) ?? "es";
  return (
    asLocale(parseLanguageTag(headers?.get(LOCALE_HINT_HEADER)).language) ??
    localeFromAcceptLanguage(headers?.get("accept-language")) ??
    "es"
  );
}

/**
 * `next` for the magic link: a same-origin path only (one leading slash, no backslash, no
 * whitespace, no encoded slash in the path). The web screens it again with `safeNext` on arrival.
 */
export function linkNext(value: string | null | undefined): string | null {
  if (!value || value.length > 512) return null;
  if (!/^\/(?![/\\])/.test(value) || /[\\\s]/.test(value)) return null;
  if (/%(?:2f|5c)/i.test(value.split(/[?#]/, 1)[0] ?? "")) return null;
  return value;
}

/**
 * The origin Android's Credential Manager puts in a passkey's client data for an app (rather than a
 * web page): `android:apk-key-hash:` and the SHA-256 of the app's signing certificate, in base64url
 * with no padding. `fingerprint` is that SHA-256 as hex pairs (AA:BB:…), in either case.
 */
export function androidApkKeyHashOrigin(fingerprint: string): string {
  const hash = Buffer.from(fingerprint.replaceAll(":", ""), "hex");
  return `android:apk-key-hash:${hash.toString("base64url")}`;
}

/**
 * The origins a passkey ceremony may come from: the web, and the Android app for each of its
 * signing certificates (ANDROID_CERT_SHA256). The relying party id stays the web host either way;
 * /.well-known/assetlinks.json on that host is what lets the app use it.
 */
export function passkeyOrigins(config: Pick<Config, "WEB_URL" | "ANDROID_CERT_SHA256">): string[] {
  return [config.WEB_URL, ...(config.ANDROID_CERT_SHA256 ?? []).map(androidApkKeyHashOrigin)];
}

export function createAuth(deps: AppDeps) {
  const { config } = deps;
  return betterAuth({
    appName: "Lukitas",
    // Better Auth ignores basePath when baseURL has a path, so it gets the origin and the full
    // path separately; its endpoints then resolve to `${API_URL}/auth/...`.
    basePath: `${apiPathPrefix(config)}/auth`,
    baseURL: new URL(config.API_URL).origin,
    secret: config.BETTER_AUTH_SECRET,
    trustedOrigins: [config.WEB_URL],
    database: drizzleAdapter(deps.db, { provider: "pg", schema }),
    emailAndPassword: { enabled: false },
    // Every session slides while it is used: valid for 60 days after its last use, extended at most
    // once a day. A guest has no email to sign in again with, so it must outlast the 60 days of
    // idleness after which the account is deleted (services/guest-cleanup.ts).
    session: { expiresIn: 60 * 24 * 60 * 60, updateAge: 24 * 60 * 60 },
    user: {
      additionalFields: {
        timezone: { type: "string", required: false, defaultValue: "UTC", input: false },
        locale: { type: "string", required: false, defaultValue: "es", input: false },
        onboardingCompletedAt: { type: "date", required: false, input: false },
        // A guest's latest activity, kept on the user so it outlives a signed-out session; the
        // guest cleanup reads it (services/guest-cleanup.ts, `stampGuestActivity`).
        lastActiveAt: { type: "date", required: false, input: false, returned: false },
      },
    },
    advanced: {
      ipAddress: {
        ipAddressHeaders: [config.CLIENT_IP_HEADER],
        trustedProxies: config.TRUSTED_PROXIES,
      },
    },
    rateLimit: {
      enabled: true,
      storage: "database",
      window: 60,
      max: 30,
      customRules: {
        "/email-otp/send-verification-otp": { window: 600, max: 5 },
      },
    },
    hooks: {
      before: createAuthMiddleware(async (ctx) => {
        // Guest sign-up is open whatever the allowlist says (spec §4.1); only GUEST_SIGNUP closes it.
        if (ctx.path === "/sign-in/anonymous") {
          if (config.GUEST_SIGNUP === false) throw guestSignupDisabled();
          return;
        }
        if (ctx.path !== "/email-otp/send-verification-otp") return;
        const email = String(ctx.body?.email ?? "")
          .trim()
          .toLowerCase();
        // Before anything is stored or sent: a refused address leaves no trace.
        if (!isSignInAllowed(config, email)) throw signInNotAllowed();
        if (email && (await overEmailLimit(deps, email))) {
          throw new APIError("TOO_MANY_REQUESTS", {
            message: "Too many codes requested for this email",
          });
        }
      }),
      after: createAuthMiddleware(async (ctx) => {
        if (ctx.path !== "/passkey/generate-register-options") return;
        const returned = ctx.context.returned;
        if (!returned || typeof returned !== "object" || !("pubKeyCredParams" in returned)) return;
        // The passkey plugin offers SimpleWebAuthn's default, Ed25519 first. Proton Pass then
        // creates Ed25519 keys it cannot sign with (CTAP2_ERR_UNSUPPORTED_ALGORITHM), so only
        // ES256 and RS256 are offered: every authenticator signs with one of those.
        return ctx.json({ ...returned, pubKeyCredParams: PASSKEY_ALGORITHMS });
      }),
    },
    databaseHooks: {
      // A guest's activity is stamped on the user, so it outlives the session (guest-cleanup.ts).
      // A background request refreshes nothing, so it never stamps.
      session: {
        create: {
          after: async (created) => stampGuestActivity(deps.db, created.userId, created.updatedAt),
        },
        update: {
          after: async (updated) => {
            if (updated.userId && updated.updatedAt)
              await stampGuestActivity(deps.db, updated.userId, updated.updatedAt);
          },
        },
        delete: {
          // Sign-out is activity; an expired session that a request finds and removes is not, so
          // it stamps only when that session was last used.
          after: async (ended) => {
            const now = new Date();
            const live = new Date(ended.expiresAt) > now;
            await stampGuestActivity(deps.db, ended.userId, live ? now : new Date(ended.updatedAt));
          },
        },
      },
      user: {
        create: {
          // A guest's time zone and language come from the device, and so do an app user's: the
          // app sends `x-lukas-timezone` on every request and has no onboarding. A user created
          // from the web (no such header) stays at the defaults until the web's onboarding.
          before: async (data, ctx) => {
            const headers = ctx?.headers ?? ctx?.request?.headers;
            if (!data.isAnonymous && !fromDevice(headers)) return;
            const { timezone, locale } = guestDefaults(headers);
            return { data: { ...data, timezone, locale } };
          },
          after: async (created, ctx) => {
            // A guest or an app user skips the web's currency step, so the device picks it (the
            // web's rule); a web user starts in EUR and chooses during onboarding.
            const headers = ctx?.headers ?? ctx?.request?.headers;
            const currency =
              created.isAnonymous || fromDevice(headers)
                ? defaultCurrencyFor(
                    String(created.timezone ?? "UTC"),
                    guestDefaults(headers).region,
                  )
                : "EUR";
            await withUser(deps.db, created.id, (tx) =>
              tx.insert(accounts).values({
                userId: created.id,
                name: "Main",
                currency,
                isDefault: true,
              }),
            );
          },
        },
      },
    },
    plugins: [
      emailOTP({
        otpLength: 6,
        expiresIn: CODE_TTL_SECONDS,
        allowedAttempts: CODE_ATTEMPTS,
        storeOTP: "hashed",
        disableSignUp: false,
        async sendVerificationOTP({ email, otp, type }, ctx) {
          if (type !== "sign-in") return;
          // The hook above refuses first; this keeps the rule even if another route reaches here.
          if (!isSignInAllowed(config, email)) throw signInNotAllowed();
          const headers = ctx?.headers ?? ctx?.request?.headers;
          const locale = await localeFor(deps, email, headers);
          // The link opens the web in the email's language and goes on to `next` after sign-in.
          const params = new URLSearchParams({ email, code: otp, lang: locale });
          const next = linkNext(headers?.get(NEXT_HINT_HEADER));
          if (next) params.set("next", next);
          if (headers?.get(CLIENT_HEADER)?.trim().toLowerCase() === CLIENT_ANDROID) {
            params.set("from", "app");
          }
          const link = `${config.WEB_URL}/auth/verify?${params}`;
          const mail = signInEmail({
            code: otp,
            link,
            locale,
            webUrl: config.WEB_URL,
            expiresInMinutes: Math.ceil(CODE_TTL_SECONDS / 60),
          });
          await deps.mailer.send({ to: email, ...mail });
        },
      }),
      passkey({
        rpID: new URL(config.WEB_URL).hostname,
        rpName: "Lukitas",
        origin: passkeyOrigins(config),
      }),
      anonymous({
        emailDomainName: GUEST_EMAIL_DOMAIN,
        // The plugin would delete the guest user when its session signs in with an email, data
        // and all. Guests keep their user instead: an email is claimed in place (spec §4.2), and
        // abandoned guests are cleaned up by a job (§4.4).
        disableDeleteAnonymousUser: true,
      }),
      bearer(),
      jwt(),
      oauthProvider({
        scopes: [...OAUTH_SCOPES],
        loginPage: `${config.WEB_URL}/auth/sign-in`,
        consentPage: `${config.WEB_URL}/oauth/consent`,
        allowDynamicClientRegistration: true,
        allowUnauthenticatedClientRegistration: true,
        clientRegistrationDefaultScopes: ["finance:read", "finance:write"],
        clientRegistrationRequirePKCE: true,
      }),
    ],
  });
}

export type Auth = ReturnType<typeof createAuth>;
