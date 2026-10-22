import { expect, type Page, test } from "@playwright/test";
import {
  clientIp,
  expectNoAxeViolations,
  onboardWithSample,
  pinClock,
  signUpNewUser,
} from "./helpers.ts";

/**
 * Insights (spec §2.7) against the dev stack: a new user who imported the sample Budge file
 * (invented data, in EUR, September and October 2026) opens Análisis from the navigation and sees
 * October's spending as a donut, and what living costs them from their complete months.
 */

test.use({
  locale: "es-ES",
  timezoneId: "Europe/Madrid",
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
});

interface ByCategory {
  total: number;
  items: { name: string; total: number; share: number }[];
}

/** Euros as the Spanish UI writes them (Playwright's text matching treats NBSP as a space). */
const eur = (cents: number) =>
  new Intl.NumberFormat("es", { style: "currency", currency: "EUR" })
    .format(cents / 100)
    .replace("-", "−");

const isPhone = (page: Page) => (page.viewportSize()?.width ?? 0) < 1024;

test.beforeEach(async ({ page }) => {
  await pinClock(page);
  await signUpNewUser(page);
  await onboardWithSample(page, "Europe/Madrid");
});

test("after the sample import, Análisis shows October's donut and what living costs", async ({
  page,
}) => {
  const october = (await (
    await page.request.get("/api/v1/reports/by-category?from=2026-10&to=2026-10")
  ).json()) as ByCategory;
  expect(october.items.length).toBeGreaterThan(1);
  const top = october.items[0] as ByCategory["items"][number];

  await page.goto("/app");
  // A real link now, in the bottom bar on phones and the sidebar on wide screens.
  const nav = isPhone(page)
    ? page.locator(".lk-tabbar")
    : page.getByRole("navigation", { name: "Navegación principal" });
  await nav.getByRole("link", { name: "Análisis" }).click();
  await expect(page).toHaveURL(/\/app\/insights$/);
  await expect(page.getByRole("heading", { level: 1, name: "Análisis" })).toBeVisible();

  const donut = page.getByRole("region", { name: "Por categoría" });
  await expect(donut.locator(".recharts-pie-sector")).toHaveCount(october.items.length);
  await expect(donut.getByTestId("donut-total")).toContainText(eur(october.total));
  const table = donut.getByRole("table", { name: "Gastos por categoría en octubre" });
  await expect(table.locator("tbody tr").first()).toContainText(top.name);
  await expect(table.locator("tbody tr").first()).toContainText(eur(top.total));

  // The sample's only complete month is September: what living costs is its spending.
  const living = page.getByRole("region", { name: "¿Cuánto me cuesta vivir?" });
  const cost = (await (
    await page.request.get("/api/v1/reports/cost-of-living?months=1")
  ).json()) as { total: number };
  expect(cost.total).toBeGreaterThan(0);
  await expect(living).toContainText(`${eur(cost.total)} al mes`);
  await expect(living).toContainText("tu último mes completo");

  // The trend covers the span on screen: over six months, October's figures are under the chart,
  // and tapping September's bars shows September's.
  const trend = page.getByRole("region", { name: "Mes a mes" });
  await page.getByRole("tab", { name: "6 meses" }).click();
  await expect(trend.getByRole("table")).toBeAttached();
  const readout = trend.getByTestId("trend-readout");
  await expect(readout).toContainText("Octubre");
  await expect(trend.locator(".lk-trend-income .recharts-rectangle")).not.toHaveCount(0);
  // A real tap on September's place in the plot (the fifth of six months).
  await trend.locator(".lk-trend-hit").nth(4).click();
  await expect(readout).toContainText("Septiembre");
  await expect(readout).toContainText("Ingresos");

  await expectNoAxeViolations(page);
});
