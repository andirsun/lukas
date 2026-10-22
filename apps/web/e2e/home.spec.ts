import { expect, type Page, test } from "@playwright/test";
import { clientIp, onboardWithSample, signUpNewUser } from "./helpers.ts";

/**
 * Home and the add sheet against the dev stack (spec §2.5, §2.6): a new user who imported the
 * sample Budge file (invented data, in EUR, September and October 2026) adds an expense, pays a
 * pending one, and sees the month of their own time zone.
 */

test.use({
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
});

/** Euros as the Spanish UI writes them (Playwright's text matching treats NBSP as a space). */
const eur = (cents: number) =>
  new Intl.NumberFormat("es", { style: "currency", currency: "EUR" })
    .format(cents / 100)
    .replace("-", "−");

interface Summary {
  remaining: number;
}

/**
 * Movimientos is the first tab on phones, and the one shown by default; on wide screens (64rem
 * and up) both lists show side by side, Movimientos first.
 */
async function showTransactions(page: Page) {
  if ((page.viewportSize()?.width ?? 0) < 1024) {
    await expect(page.getByRole("tab", { name: "Movimientos" })).toHaveAttribute(
      "aria-selected",
      "true",
    );
  }
  return page.getByRole("tabpanel", { name: "Movimientos" });
}

test.describe("in Madrid, on 21 October 2026", () => {
  test.use({ locale: "es-ES", timezoneId: "Europe/Madrid" });

  test.beforeEach(async ({ page }) => {
    await page.clock.install({ time: new Date("2026-10-21T15:00:00Z") });
  });

  test("adding an expense lowers what is left and lists it under today", async ({ page }) => {
    await signUpNewUser(page);
    await onboardWithSample(page, "Europe/Madrid");
    const before = (await (
      await page.request.get("/api/v1/summary?month=2026-10")
    ).json()) as Summary;

    await page.goto("/app");
    const hero = page.getByRole("region", { name: "Te quedan este mes" });
    await expect(hero).toContainText(eur(before.remaining));

    await page.getByRole("button", { name: "Agregar", exact: true }).click();
    const sheet = page.getByRole("dialog", { name: "Nuevo gasto" });
    const keypad = sheet.getByRole("group", { name: "Teclado numérico" });
    for (const key of ["6", "Coma decimal", "0", "8"]) {
      await keypad.getByRole("button", { name: key, exact: true }).click();
    }
    await sheet
      .getByRole("group", { name: "Categoría" })
      .getByRole("button", { name: "Supermercado" })
      .click();
    await sheet.getByRole("button", { name: "Guardar" }).click();
    await expect(sheet).toBeHidden();

    await expect(page.getByRole("status")).toContainText("Gasto en Supermercado: 6,08 €");
    await expect(hero).toContainText(eur(before.remaining - 608));

    const transactions = await showTransactions(page);
    const today = transactions.getByRole("region", { name: /^Hoy · / });
    await expect(today.getByRole("button", { name: /^Supermercado −6,08\s€/ })).toBeVisible();

    const after = (await (
      await page.request.get("/api/v1/summary?month=2026-10")
    ).json()) as Summary;
    expect(after.remaining).toBe(before.remaining - 608);
  });

  test("paying a pending transaction turns its badge into Pagado", async ({ page }) => {
    await signUpNewUser(page);
    await onboardWithSample(page, "Europe/Madrid");
    await page.goto("/app");

    const transactions = await showTransactions(page);
    // The sample has two pending ones this month: video streaming (23rd) and internet (28th).
    const upcoming = transactions.getByRole("region", { name: /próximo/ }).first();
    await upcoming.getByRole("button", { name: "Pendiente, marcar como pagado" }).click();
    await expect(upcoming.getByText("Pagado")).toBeVisible();
    await expect(page.getByRole("status")).toContainText("Pagado:");

    const october = (await (
      await page.request.get("/api/v1/transactions?month=2026-10&limit=200")
    ).json()) as { items: { name: string; status: string }[] };
    expect(october.items.find((t) => t.name === "video streaming")?.status).toBe("paid");
    expect(october.items.find((t) => t.name === "internet")?.status).toBe("pending");
  });
});

test.describe("the person in Bogotá, the browser in Lisbon", () => {
  test.use({ locale: "es-ES", timezoneId: "Europe/Lisbon" });

  test("the default month follows the profile's time zone", async ({ page }) => {
    // 03:00 on 1 November in Lisbon is still 31 October, 22:00, in Bogotá.
    await page.clock.install({ time: new Date("2026-11-01T03:00:00Z") });
    await signUpNewUser(page);
    await onboardWithSample(page, "America/Bogota");
    await page.goto("/app");
    const month = page.getByRole("group", { name: "Mes" });
    await expect(month).toContainText("Octubre");
    await expect(month).not.toContainText("Noviembre");
    // October is the latest month there: "next" is off.
    await expect(month.getByRole("button", { name: "Mes siguiente" })).toBeDisabled();
  });
});
