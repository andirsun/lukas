import { createDb, type Db } from "@lukas/db";
import { startTestDatabase } from "@lukas/db/testing";
import { createApp } from "../src/app.ts";
import type { Config } from "../src/config.ts";
import { MemoryMailer } from "../src/mailer.ts";

export type TestApp = Awaited<ReturnType<typeof createTestApp>>;

export const TEST_CONFIG = {
  BETTER_AUTH_SECRET: "test-secret-test-secret-test-secret-0000",
  API_URL: "http://localhost:3000",
  WEB_URL: "http://localhost:5173",
  MAIL_FROM: "Lukitas <test@lukas.test>",
  PORT: 3000,
  NODE_ENV: "test" as const,
  CLIENT_IP_HEADER: "x-forwarded-for",
  TRUSTED_PROXIES: ["10.0.0.0/8"],
};

export function codeFrom(subject: string): string {
  const match = /(\d{6})$/.exec(subject);
  if (!match?.[1]) throw new Error(`No code in subject: ${subject}`);
  return match[1];
}

/** A fresh database + app per test file. Requests go through `app.request` (no network). */
export async function createTestApp(overrides: Partial<Config> = {}) {
  const database = await startTestDatabase();
  const app$ = createDb(database.appUrl);
  const admin = createDb(database.adminUrl);
  const mailer = new MemoryMailer();
  const config: Config = {
    ...TEST_CONFIG,
    DATABASE_URL: database.appUrl,
    DATABASE_ADMIN_URL: database.adminUrl,
    ...overrides,
  };
  const app = createApp({ config, db: app$.db, mailer });

  // Distinct fake client IPs (behind a trusted 10.x proxy) keep the per-IP auth rate limit out of
  // unrelated tests.
  let ipCounter = 0;
  const nextIp = () => `198.51.${Math.floor(++ipCounter / 250)}.${ipCounter % 250}, 10.0.0.1`;

  async function request(
    method: string,
    path: string,
    { body, headers = {} }: { body?: unknown; headers?: Record<string, string> } = {},
  ): Promise<Response> {
    const init: RequestInit = {
      method,
      headers: {
        "x-forwarded-for": nextIp(),
        ...(body !== undefined && !(body instanceof FormData)
          ? { "content-type": "application/json" }
          : {}),
        ...headers,
      },
    };
    if (body !== undefined) init.body = body instanceof FormData ? body : JSON.stringify(body);
    return app.request(path, init);
  }

  async function signIn(
    email: string,
  ): Promise<{ userId: string; headers: { authorization: string } }> {
    const sent = await request("POST", "/auth/email-otp/send-verification-otp", {
      body: { email, type: "sign-in" },
    });
    if (sent.status !== 200)
      throw new Error(`send otp failed: ${sent.status} ${await sent.text()}`);
    const mail = mailer.lastTo(email);
    if (!mail) throw new Error("no sign-in mail");
    const res = await request("POST", "/auth/sign-in/email-otp", {
      body: { email, otp: codeFrom(mail.subject) },
    });
    if (res.status !== 200) throw new Error(`sign-in failed: ${res.status} ${await res.text()}`);
    const token = res.headers.get("set-auth-token");
    const json = (await res.json()) as { user: { id: string } };
    return { userId: json.user.id, headers: { authorization: `Bearer ${token}` } };
  }

  return {
    app,
    db: app$.db as Db,
    admin: admin.db as Db,
    mailer,
    request,
    signIn,
    async stop() {
      await app$.close();
      await admin.close();
      await database.stop();
    },
  };
}
