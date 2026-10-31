import { verifyJwsAccessToken } from "better-auth/oauth2";
import { createMiddleware } from "hono/factory";
import { type Auth, BACKGROUND_HEADER } from "../auth.ts";
import type { Config } from "../config.ts";
import type { AppEnv, Grant, SessionUser } from "../env.ts";
import { ApiError } from "./problem.ts";

type AuthUser = {
  id: string;
  email: string;
  timezone: string;
  locale: string;
  isAnonymous?: boolean | null;
};

const toSessionUser = (u: AuthUser): SessionUser => ({
  id: u.id,
  email: u.email,
  timezone: u.timezone,
  locale: u.locale,
});

/** The issuer Better Auth stamps on its tokens: the auth routes' base URL. */
export const authIssuer = (config: Pick<Config, "API_URL">) =>
  `${config.API_URL.replace(/\/+$/, "")}/auth`;

/**
 * Resolves the caller from the cookie or `Authorization: Bearer`; 401 otherwise. The bearer is a
 * session token (the app), or an assistant's OAuth access token: a JWT signed by our `jwt` keys,
 * issued by us, for the MCP (`aud` = MCP_URL, RFC 8707). A token for any other audience is
 * refused, so a token minted for something else cannot open the API.
 *
 * A request with `x-lukas-background: 1` reads the session without refreshing it (Better Auth's
 * `disableRefresh`), so background jobs never count as activity for the guest cleanup.
 */
export function requireUser(auth: Auth, config: Pick<Config, "API_URL" | "MCP_URL">) {
  return createMiddleware<AppEnv>(async (c, next) => {
    const background = c.req.header(BACKGROUND_HEADER) === "1";
    const result = await auth.api.getSession({
      headers: c.req.raw.headers,
      ...(background ? { query: { disableRefresh: true } } : {}),
    });
    let user: SessionUser;
    let grant: Grant;
    if (result) {
      user = toSessionUser(result.user as AuthUser);
      grant = { kind: "session" };
    } else {
      const oauth = await oauthUser(auth, config, c.req.header("authorization"));
      if (!oauth) throw new ApiError(401, "unauthenticated", "Sign in to continue");
      ({ user, grant } = oauth);
    }
    c.set("userId", user.id);
    c.set("user", user);
    c.set("grant", grant);
    await next();
  });
}

async function oauthUser(
  auth: Auth,
  config: Pick<Config, "API_URL" | "MCP_URL">,
  header: string | undefined,
): Promise<{ user: SessionUser; grant: Grant } | null> {
  const token = /^Bearer\s+(\S+)$/i.exec(header ?? "")?.[1];
  if (!config.MCP_URL || !token || token.split(".").length !== 3) return null;
  let payload: Awaited<ReturnType<typeof verifyJwsAccessToken>>;
  try {
    payload = await verifyJwsAccessToken(token, {
      jwksFetch: () => auth.api.getJwks(),
      jwksCacheKey: auth,
      verifyOptions: { audience: config.MCP_URL, issuer: authIssuer(config) },
    });
  } catch {
    return null;
  }
  const clientId = typeof payload.azp === "string" ? payload.azp : payload.client_id;
  if (typeof payload.sub !== "string" || typeof clientId !== "string") return null;
  const ctx = await auth.$context;
  const found = (await ctx.internalAdapter.findUserById(payload.sub)) as AuthUser | null;
  if (!found) return null;
  // Guests cannot connect an assistant (main spec, Guest mode); the consent screen offers to save
  // their progress instead. This refuses a token minted for one anyway.
  if (found.isAnonymous)
    throw new ApiError(403, "guest_cannot_authorize", "Save your progress first");
  const scopes = typeof payload.scope === "string" ? payload.scope.split(" ").filter(Boolean) : [];
  return { user: toSessionUser(found), grant: { kind: "oauth", clientId, scopes } };
}
