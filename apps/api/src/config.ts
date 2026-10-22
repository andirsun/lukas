import { isIP } from "node:net";
import { z } from "zod";

const isCidr = (entry: string) => {
  const [ip, prefix] = entry.split("/");
  return Boolean(ip && isIP(ip)) && (prefix === undefined || /^\d{1,3}$/.test(prefix));
};

/** Hosts that mean "this machine" from the API's point of view (Docker Desktop's name for the host included). */
const LOCAL_SMTP_HOSTS = new Set(["localhost", "127.0.0.1", "[::1]", "host.docker.internal"]);

function smtpHostIsLocal(smtpUrl: string | undefined): boolean {
  if (!smtpUrl) return false;
  try {
    return LOCAL_SMTP_HOSTS.has(new URL(smtpUrl).hostname.toLowerCase());
  } catch {
    return false;
  }
}

const configSchema = z
  .object({
    DATABASE_URL: z.string().url(),
    /** The owner role. Only development needs it (the API migrates on start); production runs migrations as a separate step. */
    DATABASE_ADMIN_URL: z.string().url().optional(),
    BETTER_AUTH_SECRET: z.string().min(32),
    API_URL: z.string().url(),
    WEB_URL: z.string().url(),
    MAIL_FROM: z.string().min(3),
    RESEND_API_KEY: z.string().optional(),
    SMTP_URL: z.string().optional(),
    /**
     * Accept the SMTP server's self-signed certificate (still over STARTTLS). Only for a mail
     * server on this machine, such as Proton Bridge; refused for any other host.
     */
    SMTP_TLS_INSECURE: z
      .preprocess(
        (v) => (v === "" ? undefined : v),
        z
          .enum(["true", "false"])
          .transform((v) => v === "true")
          .optional(),
      )
      .optional(),
    /**
     * Comma-separated emails that may sign in (case-insensitive). When set, a sign-in code is only
     * sent to these addresses; unset or blank means anyone can ask for one (development, tests).
     */
    SIGN_IN_ALLOWLIST: z
      .string()
      // Set, but naming nobody (" ", ","): refuse to start rather than let everyone in.
      .refine(
        (v) => v === "" || v.split(",").some((email) => email.trim()),
        "SIGN_IN_ALLOWLIST is set but has no emails; remove it to allow everyone",
      )
      .transform((v) =>
        v
          .split(",")
          .map((email) => email.trim().toLowerCase())
          .filter(Boolean),
      )
      .refine(
        (list) => list.every((email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)),
        "SIGN_IN_ALLOWLIST must be a comma-separated list of emails",
      )
      .transform((list) => (list.length > 0 ? list : undefined))
      .optional(),
    PORT: z.coerce.number().int().default(3000),
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    /** Header carrying the client IP, e.g. a platform header like `fly-client-ip`. */
    CLIENT_IP_HEADER: z.string().min(1).default("x-forwarded-for"),
    /** Comma-separated IPs/CIDRs of our own proxies, stripped from the right of X-Forwarded-For. */
    TRUSTED_PROXIES: z
      .string()
      .default("")
      .transform((v) =>
        v
          .split(",")
          .map((p) => p.trim())
          .filter(Boolean),
      )
      .refine((list) => list.every(isCidr), "TRUSTED_PROXIES must be IPs or CIDR ranges"),
    /**
     * End-to-end tests only: pins the API's clock (the "current month" every route works out) to
     * this ISO instant, so tests that read seeded months do not depend on the real date. Refused
     * in production. Blank or unset: the real clock.
     */
    E2E_NOW: z
      .preprocess(
        (v) => (v === "" ? undefined : v),
        z.string().datetime({ offset: true }).pipe(z.coerce.date()).optional(),
      )
      .optional(),
  })
  .refine((c) => c.NODE_ENV === "test" || Boolean(c.RESEND_API_KEY) !== Boolean(c.SMTP_URL), {
    message: "Set exactly one of RESEND_API_KEY or SMTP_URL",
    path: ["RESEND_API_KEY"],
  })
  .refine((c) => c.NODE_ENV !== "development" || Boolean(c.DATABASE_ADMIN_URL), {
    message: "DATABASE_ADMIN_URL is required in development (the API applies migrations on start)",
    path: ["DATABASE_ADMIN_URL"],
  })
  .refine((c) => !c.SMTP_TLS_INSECURE || smtpHostIsLocal(c.SMTP_URL), {
    message:
      "SMTP_TLS_INSECURE only works with an SMTP_URL on this machine (localhost, 127.0.0.1, [::1] or host.docker.internal)",
    path: ["SMTP_TLS_INSECURE"],
  })
  .refine((c) => c.NODE_ENV !== "production" || c.E2E_NOW === undefined, {
    message: "E2E_NOW pins the clock for end-to-end tests; production refuses it",
    path: ["E2E_NOW"],
  })
  .refine(
    (c) =>
      c.NODE_ENV !== "production" ||
      c.CLIENT_IP_HEADER !== "x-forwarded-for" ||
      c.TRUSTED_PROXIES.length > 0,
    {
      message:
        "In production set TRUSTED_PROXIES (your proxy ranges) or CLIENT_IP_HEADER (a platform header); a bare X-Forwarded-For is spoofable",
      path: ["TRUSTED_PROXIES"],
    },
  );

export type Config = z.infer<typeof configSchema>;

/**
 * The path every route lives under: API_URL's pathname without a trailing slash. "/api" when the
 * web origin proxies /api to the API (so Better Auth cookies are first-party), "" when the API is
 * served from its own origin.
 */
export function apiPathPrefix(config: Pick<Config, "API_URL">): string {
  return new URL(config.API_URL).pathname.replace(/\/+$/, "");
}

export function loadConfig(env: NodeJS.ProcessEnv): Config {
  return configSchema.parse(env);
}
