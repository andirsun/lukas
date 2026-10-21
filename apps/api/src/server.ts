import { serve } from "@hono/node-server";
import { createDb, runMigrations } from "@lukas/db";
import { createApp } from "./app.ts";
import { loadConfig } from "./config.ts";
import { type Mailer, ResendMailer, SmtpMailer } from "./mailer.ts";

const config = loadConfig(process.env);
// Development applies migrations itself; elsewhere they are a separate step with the owner role
// (deploy/personal runs a `migrate` service), so this process never holds that credential.
if (config.NODE_ENV === "development" && config.DATABASE_ADMIN_URL) {
  await runMigrations(config.DATABASE_ADMIN_URL);
}

const mailer: Mailer = config.RESEND_API_KEY
  ? new ResendMailer(config.RESEND_API_KEY, config.MAIL_FROM)
  : new SmtpMailer(config.SMTP_URL ?? "", config.MAIL_FROM, {
      tlsInsecure: config.SMTP_TLS_INSECURE,
    });
const { db } = createDb(config.DATABASE_URL);
const app = createApp({ config, db, mailer });

serve({ fetch: app.fetch, port: config.PORT }, ({ port }) => {
  console.log(`Lukitas API listening on http://localhost:${port}`);
});
