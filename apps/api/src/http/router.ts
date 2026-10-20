import { OpenAPIHono } from "@hono/zod-openapi";
import type { AppEnv } from "../env.ts";
import { validationHook } from "./problem.ts";

/** A router for `/v1` feature routes; validation failures become 422 problems. */
export const router = () => new OpenAPIHono<AppEnv>({ defaultHook: validationHook });
