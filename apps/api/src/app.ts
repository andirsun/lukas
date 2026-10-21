import { oauthProviderAuthServerMetadata } from "@better-auth/oauth-provider";
import { OpenAPIHono } from "@hono/zod-openapi";
import { getPath } from "hono/utils/url";
import { createAuth } from "./auth.ts";
import { apiPathPrefix } from "./config.ts";
import type { AppDeps } from "./deps.ts";
import type { AppEnv } from "./env.ts";
import { notFound, onError, validationHook } from "./http/problem.ts";
import { requireUser } from "./http/session.ts";
import { categoryRoutes } from "./routes/categories.ts";
import { importRoutes } from "./routes/imports.ts";
import { meRoutes } from "./routes/me.ts";
import { recurrenceRoutes } from "./routes/recurrences.ts";
import { reportRoutes } from "./routes/reports.ts";
import { summaryRoutes } from "./routes/summary.ts";
import { transactionRoutes } from "./routes/transactions.ts";

export type { AppDeps } from "./deps.ts";

/** A path no route matches: requests outside the API_URL prefix fall through to the 404. */
const OUTSIDE_PREFIX = "/\u0000outside-api-path";

/**
 * Routes are declared without the API_URL path prefix and matched after stripping it, so they all
 * live under the prefix while the OpenAPI document keeps prefix-free paths (its `servers` entry
 * carries API_URL instead).
 */
function stripPrefix(path: string, prefix: string): string {
  if (!prefix) return path;
  if (path === prefix) return "/";
  return path.startsWith(`${prefix}/`) ? path.slice(prefix.length) : OUTSIDE_PREFIX;
}

export function createApp(deps: AppDeps) {
  const auth = createAuth(deps);
  const prefix = apiPathPrefix(deps.config);
  const app = new OpenAPIHono<AppEnv>({
    defaultHook: validationHook,
    getPath: (request) => stripPrefix(getPath(request), prefix),
  });

  app.onError(onError);
  app.notFound(notFound);

  app.get("/health", (c) => c.json({ status: "ok" }));
  app.on(["GET", "POST"], "/auth/*", (c) => auth.handler(c.req.raw));
  app.get("/.well-known/oauth-authorization-server", (c) =>
    oauthProviderAuthServerMetadata(auth)(c.req.raw),
  );

  app.use("/v1/*", requireUser(auth));
  app.route("/", meRoutes(deps));
  app.route("/", categoryRoutes(deps));
  app.route("/", transactionRoutes(deps));
  app.route("/", recurrenceRoutes(deps));
  app.route("/", summaryRoutes(deps));
  app.route("/", reportRoutes(deps));
  app.route("/", importRoutes(deps));

  app.doc31("/openapi.json", {
    openapi: "3.1.0",
    info: { title: "Lukas API", version: "1.0.0" },
    servers: [{ url: deps.config.API_URL }],
  });

  return app;
}
