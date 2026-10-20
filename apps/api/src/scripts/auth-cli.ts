// Auth instance for the Better Auth CLI, which regenerates packages/db/src/schema/auth.ts:
//   pnpm --filter @lukas/api auth:generate
import { createAuth } from "../auth.ts";

export const auth = createAuth({
  config: {
    DATABASE_URL: "postgres://x@localhost/x",
    DATABASE_ADMIN_URL: "postgres://x@localhost/x",
    BETTER_AUTH_SECRET: "x".repeat(32),
    API_URL: "http://localhost:3000",
    WEB_URL: "http://localhost:5173",
    MAIL_FROM: "x@x",
    PORT: 3000,
    NODE_ENV: "test",
    CLIENT_IP_HEADER: "x-forwarded-for",
    TRUSTED_PROXIES: [],
  },
  db: {} as never,
  mailer: { send: async () => {} },
});
