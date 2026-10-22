import { oauthProvider } from "@better-auth/oauth-provider";
import { passkey } from "@better-auth/passkey";
import { accounts, emailThrottle, schema, user as userTable, withUser } from "@lukas/db";
import { eq, sql } from "@lukas/db/orm";
import { APIError, betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { createAuthMiddleware } from "better-auth/api";
import { bearer, emailOTP, jwt } from "better-auth/plugins";
import { apiPathPrefix, type Config } from "./config.ts";
import type { AppDeps } from "./deps.ts";
import { signInEmail } from "./emails/sign-in.ts";

export const OAUTH_SCOPES = ["finance:read", "finance:write", "offline_access"] as const;
export const CODE_TTL_SECONDS = 600;
const EMAIL_WINDOW_MS = 15 * 60 * 1000;
const EMAILS_PER_WINDOW = 5;
/** ES256 then RS256 (COSE ids), offered when a passkey is created. */
const PASSKEY_ALGORITHMS = [
  { alg: -7, type: "public-key" },
  { alg: -257, type: "public-key" },
] as const;

/** Whether `email` may ask for a sign-in code: always, unless an allowlist is configured. */
export function isSignInAllowed(config: Pick<Config, "SIGN_IN_ALLOWLIST">, email: string): boolean {
  const list = config.SIGN_IN_ALLOWLIST;
  return !list || list.includes(email.trim().toLowerCase());
}

/** The refusal: the web shows `errors.sign_in_not_allowed` for this code. */
const signInNotAllowed = () =>
  new APIError("FORBIDDEN", {
    code: "sign_in_not_allowed",
    message: "Sign-in is not open to this address",
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

type Locale = "es" | "en";

/** Headers the web app sends with a code request: the page's language and where to go after. */
export const LOCALE_HINT_HEADER = "x-lukas-locale";
export const NEXT_HINT_HEADER = "x-lukas-next";

const asLocale = (value: string | null | undefined): Locale | null =>
  value === "es" || value === "en" ? value : null;

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
 * The language of a sign-in email: the profile's for an existing user; for a new address, the
 * page's (the web sends it in `x-lukas-locale`), else the browser's Accept-Language, else Spanish.
 */
async function localeFor(deps: AppDeps, email: string, headers: Headers | undefined) {
  const [row] = await deps.db
    .select({ locale: userTable.locale })
    .from(userTable)
    .where(eq(userTable.email, email));
  if (row) return asLocale(row.locale) ?? "es";
  return (
    asLocale(headers?.get(LOCALE_HINT_HEADER)) ??
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
    user: {
      additionalFields: {
        timezone: { type: "string", required: false, defaultValue: "UTC", input: false },
        locale: { type: "string", required: false, defaultValue: "es", input: false },
        onboardingCompletedAt: { type: "date", required: false, input: false },
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
        if (ctx.path !== "/email-otp/send-verification-otp") return;
        const email = String(ctx.body?.email ?? "")
          .trim()
          .toLowerCase();
        // Before anything is stored or sent: a refused address leaves no trace.
        if (!isSignInAllowed(config, email)) throw signInNotAllowed();
        if (email && (await bumpEmailThrottle(deps, email)) > EMAILS_PER_WINDOW) {
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
      user: {
        create: {
          after: async (created) => {
            await withUser(deps.db, created.id, (tx) =>
              tx.insert(accounts).values({
                userId: created.id,
                name: "Main",
                currency: "EUR",
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
        allowedAttempts: 3,
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
        origin: config.WEB_URL,
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
