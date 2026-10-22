import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    name: "api",
    // Integration tests run many sequential HTTP requests against a real Postgres. Leave headroom
    // for loaded machines and CI runners.
    testTimeout: 30_000,
    // Starting the Postgres testcontainer per test file is the slow part of setup.
    hookTimeout: 120_000,
  },
});
