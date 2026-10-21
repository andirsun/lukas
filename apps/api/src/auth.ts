import { oauthProvider } from "@better-auth/oauth-provider";
import { passkey } from "@better-auth/passkey";
import { accounts, emailThrottle, schema, user as userTable, withUser } from "@lukas/db";
import { eq, sql } from "@lukas/db/orm";
import { APIError, betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { createAuthMiddleware } from "better-auth/api";
import { bearer, emailOTP, jwt } from "better-auth/plugins";
import type { AppDeps } from "./deps.ts";
import { signInEmail } from "./emails/sign-in.ts";

export const OAUTH_SCOPES = ["finance:read", "finance:write", "offline_access"] as const;
export const CODE_TTL_SECONDS = 600;
const EMAIL_WINDOW_MS = 15 * 60 * 1000;
const EMAILS_PER_WINDOW = 5;

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

async function localeFor(deps: AppDeps, email: string): Promise<"es" | "en"> {
  const [row] = await deps.db
    .select({ locale: userTable.locale })
    .from(userTable)
    .where(eq(userTable.email, email));
  return row?.locale === "en" ? "en" : "es";
}

export function createAuth(deps: AppDeps) {
  const { config } = deps;
  return betterAuth({
    appName: "Lukas",
    basePath: "/auth",
    baseURL: config.API_URL,
    secret: config.BETTER_AUTH_SECRET,
    trustedOrigins: [config.WEB_URL],
    database: drizzleAdapter(deps.db, { provider: "pg", schema }),
    emailAndPassword: { enabled: false },
    user: {
      additionalFields: {
        timezone: { type: "string", required: false, defaultValue: "UTC", input: false },
        locale: { type: "string", required: false, defaultValue: "es", input: false },
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
        const email = String(ctx.body?.email ?? "").toLowerCase();
        if (email && (await bumpEmailThrottle(deps, email)) > EMAILS_PER_WINDOW) {
          throw new APIError("TOO_MANY_REQUESTS", {
            message: "Too many codes requested for this email",
          });
        }
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
        async sendVerificationOTP({ email, otp, type }) {
          if (type !== "sign-in") return;
          const link = `${config.WEB_URL}/auth/verify?${new URLSearchParams({ email, code: otp })}`;
          const locale = await localeFor(deps, email);
          await deps.mailer.send({ to: email, ...signInEmail({ code: otp, link, locale }) });
        },
      }),
      passkey({
        rpID: new URL(config.WEB_URL).hostname,
        rpName: "Lukas",
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
