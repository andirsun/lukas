import { defineConfig, devices } from "@playwright/test";

const baseURL = "http://localhost:5173";

/** App flows against `pnpm dev`. The landing specs run against the built site instead: see
 * playwright.built.config.ts (`pnpm e2e:landing`). */
export default defineConfig({
  testDir: "./e2e",
  testIgnore: /landing(-3d)?\.spec\.ts$/,
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: { baseURL, trace: "on-first-retry" },
  projects: [
    {
      name: "phone",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 390, height: 844 },
        isMobile: true,
        hasTouch: true,
      },
    },
    {
      name: "desktop",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 800 } },
    },
  ],
  webServer: { command: "pnpm dev", url: baseURL, reuseExistingServer: !process.env.CI },
});
