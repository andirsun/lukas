import { oauthProviderAuthServerMetadata } from "@better-auth/oauth-provider";
import { OpenAPIHono } from "@hono/zod-openapi";
import { createAuth } from "./auth.ts";
import type { AppDeps } from "./deps.ts";
import type { AppEnv } from "./env.ts";
import { notFound, onError, validationHook } from "./http/problem.ts";
import { requireUser } from "./http/session.ts";

export type { AppDeps } from "./deps.ts";

/** A router for `/v1` feature routes; validation failures become 422 problems. */
export const router = () => new OpenAPIHono<AppEnv>({ defaultHook: validationHook });

export function createApp(deps: AppDeps) {
  const auth = createAuth(deps);
  const app = new OpenAPIHono<AppEnv>({ defaultHook: validationHook });

  app.onError(onError);
  app.notFound(notFound);

  app.get("/health", (c) => c.json({ status: "ok" }));
  app.on(["GET", "POST"], "/auth/*", (c) => auth.handler(c.req.raw));
  app.get("/.well-known/oauth-authorization-server", (c) =>
    oauthProviderAuthServerMetadata(auth)(c.req.raw),
  );

  app.use("/v1/*", requireUser(auth));
  app.get("/v1/me", (c) => c.json(c.get("user")));

  app.doc31("/openapi.json", {
    openapi: "3.1.0",
    info: { title: "Lukas API", version: "1.0.0" },
  });

  return app;
}
