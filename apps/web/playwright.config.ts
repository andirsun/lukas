import { defineConfig, devices } from "@playwright/test";

const baseURL = "http://localhost:5173";
/** The built site (`build/client`) served statically, for the prerendered landing pages. */
const builtURL = "http://localhost:4180";

const phone = {
  ...devices["Desktop Chrome"],
  viewport: { width: 390, height: 844 },
  isMobile: true,
  hasTouch: true,
};
const desktop = { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 800 } };

/** Specs that run against the built, prerendered site instead of the dev server. */
const BUILT_SPECS = /landing\.spec\.ts$/;

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: { baseURL, trace: "on-first-retry" },
  projects: [
    // App flows against `pnpm dev` (and the API behind its proxy).
    { name: "phone", testIgnore: BUILT_SPECS, use: phone },
    { name: "desktop", testIgnore: BUILT_SPECS, use: desktop },
    // The landing page as shipped: prerendered HTML, read with JavaScript off unless a test opts in.
    {
      name: "built-phone",
      testMatch: BUILT_SPECS,
      use: { ...phone, baseURL: builtURL, javaScriptEnabled: false },
    },
    {
      name: "built-desktop",
      testMatch: BUILT_SPECS,
      use: { ...desktop, baseURL: builtURL, javaScriptEnabled: false },
    },
  ],
  webServer: [
    { command: "pnpm dev", url: baseURL, reuseExistingServer: !process.env.CI },
    {
      // Always rebuilds, so the landing specs never read a stale build.
      command: "pnpm build && tsx scripts/serve-build.ts 4180",
      url: builtURL,
      reuseExistingServer: false,
      timeout: 180_000,
    },
  ],
});
