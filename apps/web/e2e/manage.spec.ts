import { expect, type Page, test } from "@playwright/test";
import { clientIp, onboardWithSample, signUpNewUser } from "./helpers.ts";

/**
 * Category detail, categories and recurring (spec §2.7) against the dev stack: a new user who
 * imported the sample Budge file (invented data, in EUR, September and October 2026) sets Ocio's
 * budget from its detail and sees home follow, and adds a monthly payment on the 23rd that shows
 * up as pending this month.
 */

test.use({
  locale: "es-ES",
  timezoneId: "Europe/Madrid",
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
});

interface Summary {
  remaining: number;
  budgetTotal: number;
  categories: { categoryId: string; budget: number | null; remaining: number | null }[];
}
interface Category {
  id: string;
  name: string;
}

/** Euros as the Spanish UI writes them (Playwright's text matching treats NBSP as a space). */
const eur = (cents: number) =>
  new Intl.NumberFormat("es", { style: "currency", currency: "EUR" })
    .format(cents / 100)
    .replace("-", "−");

const isPhone = (page: Page) => (page.viewportSize()?.width ?? 0) < 1024;

/** Presupuestos is the second tab on phones; on wide screens both lists show side by side. */
async function showBudgets(page: Page) {
  if (isPhone(page)) await page.getByRole("tab", { name: "Presupuestos" }).click();
  return page.getByRole("tabpanel", { name: "Presupuestos" });
}

/** Recurrentes lives in the avatar menu on phones and in the sidebar on wide screens. */
async function openRecurring(page: Page) {
  if (isPhone(page)) {
    await page.getByRole("button", { name: "Tu cuenta" }).click();
    await page.locator(".lk-menu").getByRole("link", { name: "Recurrentes" }).click();
  } else {
    await page
      .getByRole("navigation", { name: "Navegación principal" })
      .getByRole("link", { name: "Recurrentes" })
      .click();
  }
  await expect(page).toHaveURL(/\/app\/recurring$/);
}

test.beforeEach(async ({ page }) => {
  await page.clock.install({ time: new Date("2026-10-21T15:00:00Z") });
  await signUpNewUser(page);
  await onboardWithSample(page, "Europe/Madrid");
});

test("Ocio's budget, set from its detail this month, moves home's bars", async ({ page }) => {
  const categories = (await (await page.request.get("/api/v1/categories")).json()) as Category[];
  const ocio = categories.find((c) => c.name === "Ocio");
  if (!ocio) throw new Error("The sample has Ocio");
  const before = (await (
    await page.request.get("/api/v1/summary?month=2026-10")
  ).json()) as Summary;

  await page.goto("/app");
  const budgets = await showBudgets(page);
  await budgets.getByRole("button", { name: /^Ocio Sin presupuesto/ }).click();
  await expect(page).toHaveURL(new RegExp(`/app/categories/${ocio.id}\\?month=2026-10$`));
  await expect(page.getByRole("heading", { level: 1, name: "Ocio" })).toBeVisible();

  await page.getByRole("button", { name: "Poner presupuesto" }).click();
  const sheet = page.getByRole("dialog", { name: "Presupuesto de Ocio" });
  await expect(sheet).toContainText("Desde octubre en adelante");
  const keypad = sheet.getByRole("group", { name: "Teclado numérico" });
  for (const key of ["2", "0", "0"]) {
    await keypad.getByRole("button", { name: key, exact: true }).click();
  }
  await sheet.getByRole("button", { name: "Guardar presupuesto" }).click();
  await expect(sheet).toBeHidden();
  // The sample spent 120 € on Ocio in October: 80 € left of 200 €.
  const region = page.getByRole("region", { name: "Presupuesto" });
  await expect(region).toContainText(`Quedan ${eur(8000)}`);

  const after = (await (await page.request.get("/api/v1/summary?month=2026-10")).json()) as Summary;
  expect(after.categories.find((c) => c.categoryId === ocio.id)?.budget).toBe(20000);
  expect(after.budgetTotal).toBe(before.budgetTotal + 20000);
  // From this month on: September keeps no budget for Ocio.
  const september = (await (
    await page.request.get("/api/v1/summary?month=2026-09")
  ).json()) as Summary;
  expect(september.categories.find((c) => c.categoryId === ocio.id)?.budget ?? null).toBeNull();

  await page.getByRole("link", { name: "Volver al inicio" }).click();
  await expect(page).toHaveURL(/\/app$/);
  const hero = page.getByRole("region", { name: "Te quedan este mes" });
  await expect(hero).toContainText(eur(after.remaining));
  await expect(hero.getByRole("meter")).toHaveAccessibleName(
    `Gastado ${eur(after.budgetTotal - after.remaining)} de ${eur(after.budgetTotal)}`,
  );
  const row = (await showBudgets(page)).getByRole("button", { name: /^Ocio/ });
  await expect(row).toHaveAccessibleName(`Ocio Quedan ${eur(8000)}`);
});

test("a monthly payment on the 23rd shows as pending in this month's Movimientos", async ({
  page,
}) => {
  await page.goto("/app");
  await openRecurring(page);
  await page.getByRole("button", { name: "Nuevo recurrente" }).click();
  const sheet = page.getByRole("dialog", { name: "Nuevo recurrente" });
  const keypad = sheet.getByRole("group", { name: "Teclado numérico" });
  for (const key of ["2", "5"]) {
    await keypad.getByRole("button", { name: key, exact: true }).click();
  }
  await sheet.getByRole("textbox", { name: "Nombre" }).fill("Gimnasio");
  await sheet
    .getByRole("group", { name: "Categoría" })
    .getByRole("button", { name: "Ocio", exact: true })
    .click();
  await sheet.getByRole("combobox", { name: "Día del mes" }).selectOption("23");
  await sheet.getByRole("button", { name: "Guardar" }).click();
  await expect(sheet).toBeHidden();

  const item = page.getByRole("button", { name: /^Gimnasio −25,00\s€/ });
  await expect(item).toHaveAccessibleName(/Cada mes, el día 23/);
  await expect(item).toHaveAccessibleName(/Próximo: 23 oct 2026/);

  await page.getByRole("link", { name: "Volver al inicio" }).click();
  const transactions = page.getByRole("tabpanel", { name: "Movimientos" });
  const friday = transactions.getByRole("region", { name: /^vie 23 · próximo/ });
  const gym = friday.getByRole("button", { name: /^Gimnasio −25,00\s€ Ocio$/ });
  await expect(gym).toBeVisible();
  await expect(
    friday.getByRole("button", { name: "Pendiente, marcar como pagado" }).first(),
  ).toBeVisible();

  const october = (await (
    await page.request.get("/api/v1/transactions?month=2026-10&limit=200")
  ).json()) as { items: { name: string; status: string; date: string; source: string }[] };
  expect(october.items.find((t) => t.name === "Gimnasio")).toMatchObject({
    status: "pending",
    date: "2026-10-23",
    source: "recurrence",
  });
});
