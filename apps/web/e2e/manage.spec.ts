import { expect, type Locator, type Page, test } from "@playwright/test";
import { clientIp, onboardWithSample, pinClock, signUpNewUser } from "./helpers.ts";

/**
 * Category detail, home's Categorías tab and recurring (spec §2.7) against the dev stack: a new user who
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
  icon: string;
  color: string;
  archived: boolean;
}

/** A radio of the category sheet (emoji or tint): its input is hidden, so the label is pressed. */
const pick = (sheet: Locator, name: string) =>
  sheet
    .locator("label")
    .filter({ has: sheet.page().getByRole("radio", { name }) })
    .click();

const categoriesOf = async (page: Page) =>
  (await (await page.request.get("/api/v1/categories?includeArchived=true")).json()) as Category[];

/** Euros as the Spanish UI writes them (Playwright's text matching treats NBSP as a space). */
const eur = (cents: number) =>
  new Intl.NumberFormat("es", { style: "currency", currency: "EUR" })
    .format(cents / 100)
    .replace("-", "−");

const isPhone = (page: Page) => (page.viewportSize()?.width ?? 0) < 1024;

/** Categorías is the second tab on phones; on wide screens both lists show side by side. */
async function showBudgets(page: Page) {
  if (isPhone(page)) await page.getByRole("tab", { name: "Categorías" }).click();
  return page.getByRole("tabpanel", { name: "Categorías" });
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
  await pinClock(page);
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

  // Back to the tab it was opened from.
  await page.getByRole("link", { name: "Volver a Categorías" }).click();
  await expect(page).toHaveURL(/\/app$/);
  const hero = page.getByRole("region", { name: "Te quedan este mes" });
  await expect(hero).toContainText(eur(after.remaining));
  await expect(hero.getByRole("meter")).toHaveAccessibleName(
    `Gastado ${eur(after.budgetTotal - after.remaining)} de ${eur(after.budgetTotal)}`,
  );
  const row = (await showBudgets(page)).getByRole("button", { name: /^Ocio/ });
  await expect(row).toHaveAccessibleName(`Ocio Quedan ${eur(8000)}`);
});

test("categories are managed from the Categorías tab and the detail: create, restyle, archive, restore", async ({
  page,
}) => {
  await page.goto("/app");
  const panel = await showBudgets(page);
  await panel.getByRole("button", { name: "Nueva categoría" }).click();
  const create = page.getByRole("dialog", { name: "Nueva categoría" });
  await create.getByRole("textbox", { name: "Nombre" }).fill("Mascotas");
  await pick(create, "🐶");
  await create.getByRole("button", { name: "Guardar categoría" }).click();
  await expect(create).toBeHidden();
  const row = panel.getByRole("button", { name: /^Mascotas Sin presupuesto/ });
  await expect(row).toBeVisible();
  const made = (await categoriesOf(page)).find((c) => c.name === "Mascotas");
  expect(made).toMatchObject({ icon: "🐶", archived: false });

  // Its detail: rename, icon and colour.
  await row.click();
  await expect(page).toHaveURL(new RegExp(`/app/categories/${made?.id}\\?month=2026-10$`));
  await page.getByRole("button", { name: "Editar categoría" }).click();
  const edit = page.getByRole("dialog", { name: "Editar categoría" });
  await edit.getByRole("textbox", { name: "Nombre" }).fill("Mascotas y más");
  await pick(edit, "🎁");
  await pick(edit, "Azul");
  await edit.getByRole("button", { name: "Guardar categoría" }).click();
  await expect(edit).toBeHidden();
  await expect(page.getByRole("heading", { level: 1, name: "Mascotas y más" })).toBeVisible();
  expect((await categoriesOf(page)).find((c) => c.id === made?.id)).toMatchObject({
    name: "Mascotas y más",
    icon: "🎁",
    color: "#3fa7ff",
  });

  // Archive it, after asking.
  await page.getByRole("button", { name: "Editar categoría" }).click();
  await page
    .getByRole("dialog", { name: "Editar categoría" })
    .getByRole("button", { name: "Archivar categoría" })
    .click();
  const ask = page.getByRole("dialog", { name: "¿Archivar Mascotas y más?" });
  await expect(ask).not.toContainText("También se detendr");
  await ask.getByRole("button", { name: "Sí, archivar" }).click();
  await expect(page.getByText(/Esta categoría está archivada/)).toBeVisible();
  expect((await categoriesOf(page)).find((c) => c.id === made?.id)?.archived).toBe(true);

  // In the tab it moved to "Archivadas", folded; "Restaurar" brings it back.
  await page.getByRole("link", { name: "Volver a Categorías" }).click();
  const tab = await showBudgets(page);
  await expect(tab.getByRole("button", { name: /^Mascotas y más/ })).toHaveCount(0);
  await tab.getByRole("button", { name: "Archivadas (1)" }).click();
  await tab.getByRole("button", { name: "Restaurar Mascotas y más" }).click();
  await expect(tab.getByRole("button", { name: /^Mascotas y más Sin presupuesto/ })).toBeVisible();
  await expect(tab.getByRole("button", { name: /^Archivadas/ })).toHaveCount(0);
  expect((await categoriesOf(page)).find((c) => c.id === made?.id)?.archived).toBe(false);
});

test("archiving a category stops its recurring payment, and home follows", async ({ page }) => {
  const ocio = (await categoriesOf(page)).find((c) => c.name === "Ocio");
  if (!ocio) throw new Error("The sample has Ocio");
  const rule = await page.request.post("/api/v1/recurrences", {
    data: {
      name: "Gimnasio",
      amount: -2500,
      categoryId: ocio.id,
      frequency: "monthly",
      dayOfMonth: 23,
      startDate: "2026-10-01",
    },
  });
  expect(rule.ok()).toBe(true);

  await page.goto("/app");
  const panel = await showBudgets(page);
  await panel.getByRole("button", { name: /^Ocio/ }).click();
  await page.getByRole("button", { name: "Editar categoría" }).click();
  await page
    .getByRole("dialog", { name: "Editar categoría" })
    .getByRole("button", { name: "Archivar categoría" })
    .click();
  const ask = page.getByRole("dialog", { name: "¿Archivar Ocio?" });
  await expect(ask).toContainText("También se detendrá 1 pago recurrente de esta categoría.");
  await ask.getByRole("button", { name: "Sí, archivar" }).click();
  await expect(page.getByText(/Esta categoría está archivada/)).toBeVisible();

  // The rule ended today and its pending payment from the 23rd is gone.
  const rules = (await (await page.request.get("/api/v1/recurrences")).json()) as {
    name: string;
    endDate: string | null;
  }[];
  expect(rules.find((r) => r.name === "Gimnasio")?.endDate).toBe("2026-10-21");
  const october = (await (
    await page.request.get("/api/v1/transactions?month=2026-10&limit=200")
  ).json()) as { items: { name: string; status: string }[] };
  expect(october.items.some((t) => t.name === "Gimnasio" && t.status === "pending")).toBe(false);

  // Home's figures are the API's. Ocio has spending in the month, so it stays among the tab's
  // rows, noted "archivada", and does not wait in the "Archivadas" fold.
  const summary = (await (
    await page.request.get("/api/v1/summary?month=2026-10")
  ).json()) as Summary;
  await page.getByRole("link", { name: "Volver a Categorías" }).click();
  await expect(page.getByRole("region", { name: "Te quedan este mes" })).toContainText(
    eur(summary.remaining),
  );
  const tab = await showBudgets(page);
  await expect(tab.getByRole("button", { name: /^Ocio · archivada/ })).toBeVisible();
  await expect(tab.getByRole("button", { name: /^Archivadas/ })).toHaveCount(0);
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
