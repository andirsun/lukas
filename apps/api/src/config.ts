import { isIP } from "node:net";
import { z } from "zod";

const isCidr = (entry: string) => {
  const [ip, prefix] = entry.split("/");
  return Boolean(ip && isIP(ip)) && (prefix === undefined || /^\d{1,3}$/.test(prefix));
};

const configSchema = z
  .object({
    DATABASE_URL: z.string().url(),
    DATABASE_ADMIN_URL: z.string().url(),
    BETTER_AUTH_SECRET: z.string().min(32),
    API_URL: z.string().url(),
    WEB_URL: z.string().url(),
    MAIL_FROM: z.string().min(3),
    RESEND_API_KEY: z.string().optional(),
    SMTP_URL: z.string().optional(),
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
  })
  .refine((c) => c.NODE_ENV === "test" || Boolean(c.RESEND_API_KEY) !== Boolean(c.SMTP_URL), {
    message: "Set exactly one of RESEND_API_KEY or SMTP_URL",
    path: ["RESEND_API_KEY"],
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

export function loadConfig(env: NodeJS.ProcessEnv): Config {
  return configSchema.parse(env);
}
