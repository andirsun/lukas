import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // apps/web/vitest.config.ts declares its own projects: "unit" and "storybook" (browser mode).
    projects: ["packages/*", "apps/*"],
  },
});
