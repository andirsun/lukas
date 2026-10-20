import { createMiddleware } from "hono/factory";
import type { Auth } from "../auth.ts";
import type { AppEnv } from "../env.ts";
import { ApiError } from "./problem.ts";

/** Resolves the session from the cookie or `Authorization: Bearer`; 401 otherwise. */
export function requireUser(auth: Auth) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const result = await auth.api.getSession({ headers: c.req.raw.headers });
    if (!result) throw new ApiError(401, "unauthenticated", "Sign in to continue");
    const u = result.user as typeof result.user & { timezone: string; locale: string };
    c.set("userId", u.id);
    c.set("user", { id: u.id, email: u.email, timezone: u.timezone, locale: u.locale });
    await next();
  });
}
