import { serve } from "@hono/node-server";
import { apiLukitas } from "./api-lukitas.ts";
import { createMcpApp } from "./app.ts";
import { loadConfig } from "./config.ts";
import { jwtVerifier } from "./verifier.ts";

const config = loadConfig(process.env);
const app = createMcpApp({
  config,
  verifier: jwtVerifier(config),
  lukitasFor: (token) => apiLukitas(config.MCP_API_URL, token),
});

serve({ fetch: app.fetch, port: config.MCP_PORT }, (info) => {
  console.log(`Lukitas MCP on :${info.port}, serving ${config.MCP_URL}`);
});
