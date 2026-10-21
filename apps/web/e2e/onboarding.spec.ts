import { fileURLToPath } from "node:url";
import { expect, type Page, test } from "@playwright/test";
import { clientIp, signUpNewUser } from "./helpers.ts";

/**
 * The first run after signing up, against the dev stack: currency, passkey offer (skipped),
 * categories, budgets, the sample Budge import and the celebration, ending on /app. The sample
 * file is invented data in EUR (packages/importers/test/fixtures).
 */

const BUDGE_SAMPLE = fileURLToPath(
  new URL("../../../packages/importers/test/fixtures/budge-sample.csv", import.meta.url),
);

test.use({
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
});

const heading = (page: Page, name: string) => page.getByRole("heading", { level: 1, name });

async function skipPasskey(page: Page) {
  // Chromium has WebAuthn, so the offer shows; it is skippable.
  await expect(heading(page, "¿Entrar con tu huella la próxima vez?")).toBeFocused();
  await expect(page.getByText("Paso 2 de 6")).toBeVisible();
  await page.getByRole("button", { name: "Ahora no" }).click();
}

async function pickCategories(page: Page, names: string[]) {
  await expect(heading(page, "¿En qué se te va el dinero?")).toBeFocused();
  const next = page.getByRole("button", { name: "Continuar" });
  await expect(next).toBeDisabled();
  for (const name of names) await page.getByRole("button", { name, exact: true }).click();
  await next.click();
}

async function uploadSample(page: Page) {
  await expect(heading(page, "¿Vienes de Budge?")).toBeFocused();
  await page.getByLabel("Subir archivo de Budge").setInputFiles(BUDGE_SAMPLE);
  await expect(
    page.getByRole("heading", { name: "Esto es lo que vamos a importar" }),
  ).toBeVisible();
}

test.describe("from Spain", () => {
  test.use({ locale: "es-ES" });

  test("a new user sets up categories, budgets and the Budge import, and lands on /app", async ({
    page,
  }) => {
    await signUpNewUser(page);

    // Step 0: the currency, preselected from the browser (es-ES → EUR).
    await expect(heading(page, "¿En qué moneda llevas tus cuentas?")).toBeFocused();
    await expect(page.getByText("Paso 1 de 6")).toBeVisible();
    await expect(page.getByRole("radio", { name: /EUR/ })).toBeChecked();
    await page.getByRole("button", { name: "Continuar" }).click();

    await skipPasskey(page);
    await pickCategories(page, ["Supermercado", "Restaurante", "Casa"]);

    // Budgets: one per chosen spending category, with the running total.
    await expect(heading(page, "¿Cuánto quieres gastar al mes?")).toBeFocused();
    await page.getByRole("textbox", { name: "Presupuesto de Supermercado" }).fill("300");
    await page.getByRole("textbox", { name: "Presupuesto de Restaurante" }).fill("120,50");
    await page.getByRole("textbox", { name: "Presupuesto de Casa" }).fill("600");
    await expect(
      page.getByRole("status").filter({ hasText: "Lo que puedes gastar al mes" }),
    ).toContainText("1020,50 €");
    await page.getByRole("button", { name: "Continuar" }).click();

    // The import: preview, then confirm.
    await uploadSample(page);
    const preview = page.getByRole("region", { name: "Esto es lo que vamos a importar" });
    await expect(preview.getByRole("definition").first()).toHaveText("22");
    await expect(preview).toContainText("Filas con problemas");
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByText("Importamos 22 movimientos.")).toBeVisible();
    await page.getByRole("button", { name: "Continuar" }).click();

    // Done: the celebration, then the app.
    await expect(heading(page, "¡Todo listo!")).toBeFocused();
    await expect(page.getByText("Paso 6 de 6")).toBeVisible();
    await page.getByRole("button", { name: "Empezar" }).click();
    await expect(page).toHaveURL(/\/app$/);

    // The sample's spending this month (the user's time zone is UTC) shows on /app.
    const month = new Date().toISOString().slice(0, 7);
    const summary = (await (await page.request.get(`/api/v1/summary?month=${month}`)).json()) as {
      spent: number;
    };
    expect(summary.spent).toBeGreaterThan(0);
    const spent = page.getByRole("region", { name: "Gastado este mes" });
    await expect(spent).toContainText(`${(summary.spent / 100).toFixed(2).replace(".", ",")} €`);

    const me = await (await page.request.get("/api/v1/me")).json();
    expect(me).toMatchObject({ currency: "EUR" });
    expect(me.onboardingCompletedAt).not.toBeNull();
    const categories = (await (await page.request.get("/api/v1/categories")).json()) as {
      name: string;
      currentBudget: number | null;
    }[];
    expect(categories.find((c) => c.name === "Supermercado")?.currentBudget).toBe(30000);
    expect(categories.find((c) => c.name === "Restaurante")?.currentBudget).toBe(12050);

    // Onboarding runs once.
    await page.goto("/welcome");
    await expect(page).toHaveURL(/\/app$/);
  });
});

test.describe("from Colombia", () => {
  test.use({ locale: "es-CO" });

  test("a Budge file in another currency switches the still-empty account to it", async ({
    page,
  }) => {
    await signUpNewUser(page);

    // es-CO → COP.
    await expect(page.getByRole("radio", { name: /COP/ })).toBeChecked();
    await page.getByRole("button", { name: "Continuar" }).click();
    await skipPasskey(page);
    await pickCategories(page, ["Supermercado"]);

    // COP budgets show the lukas hint next to the amount.
    const field = page.getByRole("textbox", { name: "Presupuesto de Supermercado" });
    await field.fill("300.000");
    await expect(page.getByText("$300.000 (300 lukas)").first()).toBeVisible();
    await page.getByRole("button", { name: "Continuar" }).click();

    // The sample is in EUR: the account switches before the preview the person confirms.
    await uploadSample(page);
    await expect(
      page.getByText("Tu archivo está en EUR, así que tu cuenta ahora usa EUR."),
    ).toBeVisible();
    expect((await (await page.request.get("/api/v1/me")).json()).currency).toBe("EUR");
    await page.getByRole("button", { name: "Importar 22 movimientos" }).click();
    await expect(page.getByText("Importamos 22 movimientos.")).toBeVisible();
    await expect(
      page.getByText("Llenamos tus presupuestos con lo que gastas en promedio cada mes."),
    ).toBeVisible();

    const october = (await (
      await page.request.get("/api/v1/transactions?month=2026-10&limit=200")
    ).json()) as { items: { currency: string }[] };
    expect(october.items.length).toBeGreaterThan(0);
    expect(new Set(october.items.map((t) => t.currency))).toEqual(new Set(["EUR"]));

    // The budget typed in pesos is replaced by the file's monthly average, in euros:
    // Supermercado (30,70 + 41,08) / 2 months = 35,89 €.
    await page.getByRole("button", { name: "Revisar presupuestos" }).click();
    await expect(field).toHaveValue("35,89");
    await expect(page.getByText(/lukas\)/)).toHaveCount(0);
  });
});
