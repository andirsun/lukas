import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { MemoryRouter, Outlet, Route, Routes } from "react-router";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { ApiProvider } from "../api/ApiProvider.tsx";
import { CategoryDetail } from "../features/categories/CategoryDetail.tsx";
import { AppShell } from "../features/home/AppShell.tsx";
import { Home } from "../features/home/Home.tsx";
import { Settings } from "../features/settings/Settings.tsx";
import { type Locale } from "../i18n/format.ts";
import { IntlProvider, useLocale } from "../i18n/IntlProvider.tsx";
import { ToastProvider } from "../ui/Toast.tsx";
import { DemoBanner } from "./DemoBanner.tsx";
import { createDemoBackend } from "./demo-backend.ts";
import { DEMO_SEED } from "./demo-data.ts";

/** The demo's clock in these stories: mid-afternoon on 21 October 2026. */
const NOW = new Date("2026-10-21T18:00:00Z");

/**
 * The demo as routes/demo.tsx builds it, in a memory router: the app's shell and screens under
 * `/demo`, against the real in-memory backend (Valentina, in the toolbar's language), with the
 * banner on top.
 */
function DemoStage({ path }: { path: string }) {
  const storyLocale = useLocale().locale;
  const [locale, setLocale] = useState<Locale>(storyLocale);
  const [backend] = useState(() => createDemoBackend(DEMO_SEED[storyLocale], () => NOW));
  return (
    <IntlProvider locale={locale} onLocaleChange={setLocale}>
      <MemoryRouter initialEntries={[path]}>
        <ApiProvider mode="demo" fetch={backend.fetch}>
          <ToastProvider>
            <Routes>
              <Route
                path="/demo"
                element={
                  <AppShell banner={<DemoBanner />}>
                    <Outlet />
                  </AppShell>
                }
              >
                <Route index element={<Home />} />
                <Route path="categories/:id" element={<CategoryDetail />} />
                <Route path="settings" element={<Settings />} />
              </Route>
            </Routes>
          </ToastProvider>
        </ApiProvider>
      </MemoryRouter>
    </IntlProvider>
  );
}

const meta = {
  title: "Demo/Screens",
  component: DemoStage,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof DemoStage>;

export default meta;
type Story = StoryObj<typeof meta>;

/**
 * Valentina's home in pesos: the banner on top, $638.100 left of $3.980.000 this month, and every
 * link into the app stays under /demo.
 */
export const HomeInPesos: Story = {
  args: { path: "/demo" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("complementary", { name: "Demo" })).toBeVisible();
    const hero = await canvas.findByRole("region", { name: "Te quedan este mes" });
    await waitFor(() => expect(hero).toHaveTextContent(/\$[\d.]+/));
    await expect(
      await canvas.findByRole("meter", { name: "Gastado $3.341.900 de $3.980.000" }),
    ).toBeVisible();
    const hrefs = [...canvasElement.querySelectorAll("a[href]")].map((a) => a.getAttribute("href"));
    await expect(hrefs.filter((href) => href?.startsWith("/app"))).toEqual([]);
    await expect(hrefs).toContain("/demo/insights");
  },
};

/**
 * Settings in the demo, by day and in English: passkeys, import, export and deleting the account
 * are off, each with the note; language, theme, sound and time zone still work.
 */
export const SettingsOffByDay: Story = {
  args: { path: "/demo/settings" },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await canvas.findByRole("heading", { name: "Settings", level: 1 });
    const note = "Not available in the demo. Create your account to use it.";
    await expect(canvas.getAllByText(note)).toHaveLength(3);
    for (const name of [
      "Download JSON",
      "Download CSV",
      "Import from Budge",
      "Delete my account",
    ]) {
      const button = canvas.getByRole("button", { name });
      await expect(button).toBeDisabled();
      await expect(button).toHaveAccessibleDescription(note);
    }
    await expect(canvas.getByRole("button", { name: /Add a fingerprint/ })).toBeDisabled();
    await expect(canvas.getByRole("link", { name: "Back to home" })).toHaveAttribute(
      "href",
      "/demo",
    );
    // The language still switches: the demo's profile changes in memory.
    await userEvent.click(canvas.getByRole("radio", { name: "Español" }));
    await canvas.findByRole("heading", { name: "Ajustes", level: 1 });
  },
};
