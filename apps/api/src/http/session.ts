import { createMiddleware } from "hono/factory";
import { type Auth, BACKGROUND_HEADER } from "../auth.ts";
import type { AppEnv } from "../env.ts";
import { ApiError } from "./problem.ts";

/**
 * Resolves the session from the cookie or `Authorization: Bearer`; 401 otherwise. A request with
 * `x-lukas-background: 1` reads it without refreshing it (Better Auth's `disableRefresh`), so
 * background jobs never count as activity for the guest cleanup.
 */
export function requireUser(auth: Auth) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const background = c.req.header(BACKGROUND_HEADER) === "1";
    const result = await auth.api.getSession({
      headers: c.req.raw.headers,
      ...(background ? { query: { disableRefresh: true } } : {}),
    });
    if (!result) throw new ApiError(401, "unauthenticated", "Sign in to continue");
    const u = result.user as typeof result.user & { timezone: string; locale: string };
    c.set("userId", u.id);
    c.set("user", { id: u.id, email: u.email, timezone: u.timezone, locale: u.locale });
    await next();
  });
}
