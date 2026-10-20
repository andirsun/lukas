import { z } from "zod";

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
  })
  .refine((c) => c.NODE_ENV === "test" || Boolean(c.RESEND_API_KEY) !== Boolean(c.SMTP_URL), {
    message: "Set exactly one of RESEND_API_KEY or SMTP_URL",
    path: ["RESEND_API_KEY"],
  });

export type Config = z.infer<typeof configSchema>;

export function loadConfig(env: NodeJS.ProcessEnv): Config {
  return configSchema.parse(env);
}
