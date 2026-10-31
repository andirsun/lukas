import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    name: "@lukas/mcp",
    // The API-backed tests start the API's test app (apps/api/test/harness.ts): a Postgres
    // testcontainer per file and real HTTP requests, so the API's headroom applies here too.
    testTimeout: 30_000,
    hookTimeout: 120_000,
  },
});
