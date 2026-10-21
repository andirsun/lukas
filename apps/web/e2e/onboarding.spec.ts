import { fileURLToPath } from "node:url";
import { expect, type Page, test } from "@playwright/test";
import { clientIp, signUpNewUser } from "./helpers.ts";

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
  await expect(heading(page, "¿Traes tu historial?")).toBeFocused();
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
  });

  test("a Budge file in another currency switches the still-empty account to it", async ({
    page,
  }) => {
    await signUpNewUser(page);
    await setUp(page);
    // es-CO → COP.
    await expect(page.getByRole("radio", { name: /COP/ })).toBeChecked();
    await next(page).click();
    await expect(heading(page, "¿En qué se te va el dinero?")).toBeFocused();
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
      page.getByText("Tu archivo está en EUR, así que tu cuenta ahora usa EUR."),
    ).toBeVisible();
    expect((await profileOf(page)).currency).toBe("EUR");
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByRole("heading", { name: "Importamos 22 movimientos." })).toBeFocused();

    const october = (await (
      await page.request.get("/api/v1/transactions?month=2026-10&limit=200")
    ).json()) as { items: { currency: string }[] };
    expect(october.items.length).toBeGreaterThan(0);
    expect(new Set(october.items.map((t) => t.currency))).toEqual(new Set(["EUR"]));

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

  test("the full path: currency, categories, the Budge import, budgets, then /app", async ({
    page,
  }) => {
    await signUpNewUser(page);
    await setUp(page);
    await expect(page.getByRole("radio", { name: /EUR/ })).toBeChecked();
    await next(page).click();

    // Categories: the suggestions come pre-selected; one is taken out. A reload keeps the step.
    await expect(page).toHaveURL(/\/welcome\/categories$/);
    await page.reload();
    await expect(heading(page, "¿En qué se te va el dinero?")).toBeFocused();
    const fun = page.getByRole("button", { name: "Ocio", exact: true });
    await expect(fun).toHaveAttribute("aria-pressed", "true");
    await fun.click();
    await next(page).click();
    await expect(heading(page, "¿Traes tu historial?")).toBeFocused();
    // The seven chosen suggestions were created; Ocio wasn't.
    expect((await categoriesOf(page)).map((c) => c.name).sort()).toEqual(
      SUGGESTED.filter((name) => name !== "Ocio").sort(),
    );

    await uploadSample(page);
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByRole("heading", { name: "Importamos 22 movimientos." })).toBeFocused();
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
    }).format(new Date());
    const summary = (await (await page.request.get(`/api/v1/summary?month=${month}`)).json()) as {
      spent: number;
    };
    expect(summary.spent).toBeGreaterThan(0);
    await expect(page.getByRole("region", { name: "Gastado este mes" })).toContainText(
      `${(summary.spent / 100).toFixed(2).replace(".", ",")} €`,
    );
    const categories = await categoriesOf(page);
    expect(categories.find((c) => c.name === "Casa")?.currentBudget).toBe(60000);
    // The file has Ocio rows, so the import brought that category in after all.
    expect(categories.some((c) => c.name === "Ocio")).toBe(true);
  });
});
