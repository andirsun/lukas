import { fileURLToPath } from "node:url";
import { expect, type Page, test } from "@playwright/test";
import { clientIp, E2E_NOW, pinClock, signUpNewUser } from "./helpers.ts";

/**
 * The first run after signing up, against the dev stack (spec §2.4, revised: optional, short,
 * skippable): "Entrar directo" straight to /app, and the full path (currency, categories, the
 * sample Budge import, budgets last) ending on /app. The sample file is invented data in EUR
 * (packages/importers/test/fixtures).
 */

const BUDGE_SAMPLE = fileURLToPath(
  new URL("../../../packages/importers/test/fixtures/budge-sample.csv", import.meta.url),
);

const SUGGESTED = [
  "Supermercado",
  "Restaurante",
  "Casa",
  "Transporte",
  "Ocio",
  "Suscripciones",
  "Vida",
  "Salario",
];

test.use({
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
});

// The sample's months (September and October 2026) are read against the suite's clock.
test.beforeEach(async ({ page }) => {
  await pinClock(page);
});

const heading = (page: Page, name: string) => page.getByRole("heading", { level: 1, name });
const next = (page: Page) => page.getByRole("button", { name: "Siguiente" });

interface Category {
  name: string;
  currentBudget: number | null;
}
const categoriesOf = async (page: Page) =>
  (await (await page.request.get("/api/v1/categories")).json()) as Category[];
const profileOf = async (page: Page) =>
  (await (await page.request.get("/api/v1/me")).json()) as {
    currency: string;
    timezone: string;
    onboardingCompletedAt: string | null;
  };

/** The welcome, then CONFIGURAR EN 1 MINUTO: on /welcome/currency. */
async function setUp(page: Page) {
  await expect(heading(page, "Te damos la bienvenida a Lukitas")).toBeFocused();
  await page.getByRole("button", { name: "Configurar en 1 minuto" }).click();
  await expect(page).toHaveURL(/\/welcome\/currency$/);
  await expect(heading(page, "¿En qué moneda llevas tus cuentas?")).toBeFocused();
  await expect(page.getByText("Paso 1 de 4")).toBeVisible();
}

/** Budge from the source list, its how-to, then the sample file: the preview shows. */
async function uploadSample(page: Page) {
  await expect(heading(page, "¿Vienes de otra app?")).toBeFocused();
  await page.getByRole("button", { name: "Budge" }).click();
  await expect(
    page.getByRole("heading", { name: "Exporta tus movimientos de Budge" }),
  ).toBeFocused();
  await page.getByLabel("Subir archivo de Budge").setInputFiles(BUDGE_SAMPLE);
  await expect(
    page.getByRole("heading", { name: "Esto es lo que vamos a importar" }),
  ).toBeFocused();
}

test.describe("from Colombia, in Bogotá", () => {
  test.use({ locale: "es-CO", timezoneId: "America/Bogota" });

  test("Entrar directo leaves a usable account and lands on /app", async ({ page }) => {
    await signUpNewUser(page);
    await page.getByRole("button", { name: "Entrar directo" }).click();
    await expect(page).toHaveURL(/\/app$/);
    // No budgets yet: home shows what was spent, not what is left.
    await expect(page.getByRole("region", { name: "Gastado este mes" })).toContainText("$0");

    const me = await profileOf(page);
    expect(me).toMatchObject({ currency: "COP", timezone: "America/Bogota" });
    expect(me.onboardingCompletedAt).not.toBeNull();
    const categories = await categoriesOf(page);
    expect(categories.map((c) => c.name).sort()).toEqual([...SUGGESTED].sort());
    expect(categories.every((c) => c.currentBudget === null)).toBe(true);

    // Onboarding runs once.
    await page.goto("/welcome");
    await expect(page).toHaveURL(/\/app$/);

    // Home's "Trae tu historial" leads to the import, on its own after onboarding.
    await page.getByRole("link", { name: "Traer mi historial" }).click();
    await expect(page).toHaveURL(/\/app\/import$/);
    await expect(heading(page, "Trae tu historial")).toBeFocused();
    await page.getByRole("button", { name: "Budge" }).click();
    await page.getByLabel("Subir archivo de Budge").setInputFiles(BUDGE_SAMPLE);
    await expect(
      page.getByRole("heading", { name: "Esto es lo que vamos a importar" }),
    ).toBeFocused();
    // Still empty, so the file's currency (EUR) wins here too, but only once imported.
    await expect(
      page.getByText("Tu archivo está en EUR: al importarlo, tu cuenta pasará a usar EUR."),
    ).toBeVisible();
    expect((await profileOf(page)).currency).toBe("COP");
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByRole("heading", { name: "Importamos 22 movimientos." })).toBeVisible();
    // It ends with the budgets, as onboarding does, and saves them only when asked.
    await expect(page.getByRole("heading", { name: "Tus presupuestos" })).toBeFocused();
    await page.getByRole("button", { name: "Guardar presupuestos" }).click();
    await expect(page.getByText("Guardamos tus presupuestos.")).toBeVisible();
    const budgeted = (await categoriesOf(page)).filter((c) => c.currentBudget !== null);
    expect(budgeted.length).toBeGreaterThan(0);
    await page.getByRole("link", { name: "Ir al inicio" }).click();
    await expect(page).toHaveURL(/\/app$/);
    expect((await profileOf(page)).currency).toBe("EUR");
    const all = (await (await page.request.get("/api/v1/transactions?limit=200")).json()) as {
      items: unknown[];
    };
    expect(all.items.length).toBe(22);
  });

  test("a Budge file in another currency switches the still-empty account to it", async ({
    page,
  }) => {
    await signUpNewUser(page);
    await setUp(page);
    // es-CO → COP.
    await expect(page.getByRole("radio", { name: /COP/ })).toBeChecked();
    await next(page).click();

    // The sample is in EUR: the account switches before the preview the person confirms.
    const previews: {
      stats: { averageMonthlySpending: { category: string; amount: number }[] };
    }[] = [];
    page.on("response", async (response) => {
      if (response.request().method() === "POST" && response.url().endsWith("/api/v1/imports")) {
        previews.push(await response.json());
      }
    });
    await uploadSample(page);
    await expect(
      page.getByText("Tu archivo está en EUR: al importarlo, tu cuenta pasará a usar EUR."),
    ).toBeVisible();
    // Nothing changes before the confirm; the API switches the currency with the import.
    expect((await profileOf(page)).currency).toBe("COP");
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByRole("heading", { name: "Importamos 22 movimientos." })).toBeFocused();
    expect((await profileOf(page)).currency).toBe("EUR");

    const october = (await (
      await page.request.get("/api/v1/transactions?month=2026-10&limit=200")
    ).json()) as { items: { currency: string }[] };
    expect(october.items.length).toBeGreaterThan(0);
    expect(new Set(october.items.map((t) => t.currency))).toEqual(new Set(["EUR"]));

    // The account started with the suggested categories, and the file's lower-case
    // "suscripciones" went into the starter "Suscripciones": one chip, not two.
    await next(page).click();
    await expect(heading(page, "¿En qué se te va el dinero?")).toBeFocused();
    await expect(page.getByRole("button", { name: /^suscripciones$/i })).toHaveCount(1);

    // Budgets come last, prefilled in euros from the file's recent months (the API picks the
    // window from today's date), with no lukas hint.
    await next(page).click();
    await expect(heading(page, "¿Cuánto quieres gastar al mes?")).toBeFocused();
    const groceries = previews
      .at(-1)
      ?.stats.averageMonthlySpending.find((a) => a.category === "Supermercado")?.amount;
    const expected = groceries
      ? new Intl.NumberFormat("es", {
          minimumFractionDigits: groceries % 100 === 0 ? 0 : 2,
          maximumFractionDigits: 2,
        }).format(groceries / 100)
      : "";
    await expect(page.getByRole("textbox", { name: "Presupuesto de Supermercado" })).toHaveValue(
      expected,
    );
    if (groceries) await expect(page.getByText(/^Basado en /)).toBeVisible();
    await expect(page.getByText(/lukas\)/)).toHaveCount(0);

    // SALTAR on the last step finishes without budgets.
    await page.getByRole("button", { name: "Saltar" }).click();
    await expect(page).toHaveURL(/\/app$/);
    expect((await categoriesOf(page)).every((c) => c.currentBudget === null)).toBe(true);
  });
});

test.describe("from Spain", () => {
  test.use({ locale: "es-ES", timezoneId: "Europe/Madrid" });

  test("the full path: currency, the Budge import, categories, budgets, then /app", async ({
    page,
  }) => {
    await signUpNewUser(page);
    await setUp(page);
    await expect(page.getByRole("radio", { name: /EUR/ })).toBeChecked();
    await next(page).click();

    // "¿Vienes de otra app?" comes before the categories.
    await expect(page).toHaveURL(/\/welcome\/import$/);
    await uploadSample(page);
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByRole("heading", { name: "Importamos 22 movimientos." })).toBeFocused();
    await next(page).click();

    // Categories: the file's first, all chosen; the suggestions it covers don't repeat. One with
    // transactions can't be taken out: it stays chosen and the step says why. A reload keeps the
    // step.
    await expect(page).toHaveURL(/\/welcome\/categories$/);
    const things = page.getByRole("button", { name: "Things", exact: true });
    await expect(things).toHaveAttribute("aria-pressed", "true");
    await expect(page.getByRole("button", { name: "Supermercado", exact: true })).toHaveCount(1);
    await things.click();
    await expect(
      page.getByText(/^«Things» no se puede quitar porque tiene 1 movimiento\./),
    ).toBeVisible();
    await expect(things).toHaveAttribute("aria-pressed", "true");
    await page.reload();
    await expect(heading(page, "¿En qué se te va el dinero?")).toBeFocused();
    await expect(things).toHaveAttribute("aria-pressed", "true");
    await next(page).click();

    // Budgets last: a typed amount and the running total.
    await expect(page).toHaveURL(/\/welcome\/budgets$/);
    const home = page.getByRole("textbox", { name: "Presupuesto de Casa" });
    await home.fill("600");
    await expect(
      page.getByRole("status").filter({ hasText: "Lo que puedes gastar al mes" }),
    ).toContainText("€");
    await next(page).click();
    await expect(page).toHaveURL(/\/app$/);

    // The sample's spending this month shows on /app.
    const me = await profileOf(page);
    expect(me).toMatchObject({ currency: "EUR", timezone: "Europe/Madrid" });
    expect(me.onboardingCompletedAt).not.toBeNull();
    const month = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Europe/Madrid",
      year: "numeric",
      month: "2-digit",
    }).format(new Date(E2E_NOW));
    const summary = (await (await page.request.get(`/api/v1/summary?month=${month}`)).json()) as {
      spent: number;
    };
    expect(summary.spent).toBeGreaterThan(0);
    // With a budget, home leads with what is left and says what was spent under it.
    await expect(page.getByRole("region", { name: "Te quedan este mes" })).toContainText(
      `Gastado ${(summary.spent / 100).toFixed(2).replace(".", ",")} €`,
    );
    const categories = await categoriesOf(page);
    expect(categories.find((c) => c.name === "Casa")?.currentBudget).toBe(60000);
    // Things has transactions: it was never archived.
    expect(categories.some((c) => c.name === "Things")).toBe(true);
    expect(categories.some((c) => c.name === "Ocio")).toBe(true);
  });

  test("a re-import from /app/import keeps a budget already saved and fills the rest", async ({
    page,
  }) => {
    await signUpNewUser(page);
    await page.getByRole("button", { name: "Entrar directo" }).click();
    await expect(page).toHaveURL(/\/app$/);
    // A budget saved before the import: 300 € for Supermercado, from this month.
    const month = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Europe/Madrid",
      year: "numeric",
      month: "2-digit",
    }).format(new Date(E2E_NOW));
    const before = (await (await page.request.get("/api/v1/categories")).json()) as {
      id: string;
      name: string;
    }[];
    const groceries = before.find((c) => c.name === "Supermercado")?.id as string;
    const put = await page.request.put(`/api/v1/categories/${groceries}/budget`, {
      data: { amount: 30000, effectiveFrom: month },
    });
    expect(put.status()).toBe(200);

    await page.goto("/app/import");
    await page.getByRole("button", { name: "Budge" }).click();
    await page.getByLabel("Subir archivo de Budge").setInputFiles(BUDGE_SAMPLE);
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByRole("heading", { name: "Tus presupuestos" })).toBeFocused();
    // The saved one shows as it is, not the file's average.
    await expect(page.getByRole("textbox", { name: "Presupuesto de Supermercado" })).toHaveValue(
      "300",
    );
    await page.getByRole("button", { name: "Guardar presupuestos" }).click();
    await expect(page.getByText("Guardamos tus presupuestos.")).toBeVisible();
    const after = await categoriesOf(page);
    expect(after.find((c) => c.name === "Supermercado")?.currentBudget).toBe(30000);
  });
});
