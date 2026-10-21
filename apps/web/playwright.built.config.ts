import { defineConfig, devices } from "@playwright/test";

/**
 * The built site: `build/client` served statically, the way it ships, for the prerendered landing
 * pages (read with JavaScript off unless a test turns it on). Run with `pnpm e2e:landing`, which
 * builds first; the server reads files on every request, so a server left running from an earlier
 * run still serves the fresh build. App flows against the dev server use playwright.config.ts.
 */
/** `E2E_BUILT_PORT` picks another port, e.g. to run beside a server another checkout reuses. */
const port = Number(process.env.E2E_BUILT_PORT ?? 4180);
const baseURL = `http://localhost:${port}`;

export default defineConfig({
  testDir: "./e2e",
  testMatch: /landing\.spec\.ts$/,
  outputDir: "test-results/built",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: { baseURL, trace: "on-first-retry", javaScriptEnabled: false },
  projects: [
    {
      name: "built-phone",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 390, height: 844 },
        isMobile: true,
        hasTouch: true,
        javaScriptEnabled: false,
      },
    },
    {
      name: "built-desktop",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 1280, height: 800 },
        javaScriptEnabled: false,
      },
    },
  ],
  webServer: {
    command: `tsx scripts/serve-build.ts ${port}`,
    url: baseURL,
    reuseExistingServer: !process.env.CI,
  },
});
