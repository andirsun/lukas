import { expect, type Page, test } from "@playwright/test";
import { clientIp, onboardWithSample, pinClock, signUpNewUser } from "./helpers.ts";

/**
 * A month with more movements than one page of the API (200): home's Movimientos shows the first
 * page and "Ver más movimientos" brings the rest, whose rows open, edit and delete like any other.
 */

test.use({
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
  locale: "es-ES",
  timezoneId: "Europe/Madrid",
});

/** Extra movements on 9 October: with the sample's 10, October has 215. */
const EXTRA = 205;

/**
 * A Budge export of `count` coffees on 9 October 2026 (Restaurante, 1,20 € each), in the sample's
 * format; distinct names, so none is taken for a duplicate.
 */
function coffees(count: number): string {
  const rows = Array.from(
    { length: count },
    (_, i) =>
      `09-10-2026,coffee ${String(i + 1).padStart(3, "0")},true,-1.20,EUR,main,Restaurante,,,`,
  );
  return [
    "Format version,Period,User ID",
    "1,01-10-2026..31-10-2026,FAKEuserID000000000000000000",
    "",
    "###",
    "",
    "Date,Payment,Is paid,Amount,Currency,Account,Category,Subcategory,Goal,Description",
    ...rows,
    "",
    "###",
    "",
  ].join("\n");
}

/** One import through the API: every row in one request. */
async function importBudge(page: Page, csv: string) {
  const preview = await page.request.post("/api/v1/imports", {
    multipart: {
      source: "budge",
      file: { name: "coffees.csv", mimeType: "text/csv", buffer: Buffer.from(csv) },
    },
  });
  expect(preview.ok(), await preview.text()).toBe(true);
  const { id } = (await preview.json()) as { id: string };
  const confirm = await page.request.post(`/api/v1/imports/${id}/confirm`);
  expect(confirm.ok(), await confirm.text()).toBe(true);
}

interface Row {
  id: string;
  name: string;
  amount: number;
}

/** Every October movement the API has, through every page. */
async function october(page: Page): Promise<Row[]> {
  const rows: Row[] = [];
  let cursor: string | null = null;
  do {
    const response = await page.request.get(
      `/api/v1/transactions?month=2026-10&limit=200${cursor ? `&cursor=${cursor}` : ""}`,
    );
    const body = (await response.json()) as { items: Row[]; nextCursor: string | null };
    rows.push(...body.items);
    cursor = body.nextCursor;
  } while (cursor);
  return rows;
}

test.beforeEach(async ({ page }) => {
  await pinClock(page);
});

test("a month with more than 200 movements shows them all, and page 2's rows edit and delete", async ({
  page,
}) => {
  test.slow();
  await signUpNewUser(page);
  await onboardWithSample(page, "Europe/Madrid");
  await importBudge(page, coffees(EXTRA));
  expect(await october(page)).toHaveLength(EXTRA + 10);

  await page.goto("/app");
  const list = page.getByRole("tabpanel", { name: "Movimientos" });
  // Newest first: the sample's rows from the 8th back (bus, groceries, flights, salary) and the
  // last coffees are on page 2.
  await expect(list.getByRole("button", { name: /^dinner\b/ })).toBeVisible();
  const bus = list.getByRole("button", { name: /^bus\b/ });
  const groceries = list.getByRole("button", { name: /^groceries\b/ });
  await expect(bus).toHaveCount(0);

  const more = list.getByRole("button", { name: "Ver más movimientos" });
  await more.click();
  await expect(bus).toBeVisible();
  await expect(groceries).toBeVisible();
  await expect(list.getByRole("button", { name: /^Salary\b/ })).toBeVisible();
  await expect(list.getByRole("button", { name: /^coffee 001\b/ })).toBeVisible();
  // That was the last page.
  await expect(more).toHaveCount(0);

  // Edit a row from page 2.
  await bus.click();
  const edit = page.getByRole("dialog", { name: "Editar movimiento" });
  await edit.getByRole("textbox", { name: "Nombre (opcional)" }).fill("metro");
  await edit.getByRole("button", { name: "Guardar cambios" }).click();
  await expect(edit).toBeHidden();
  await expect(page.getByRole("status")).toContainText("Cambios guardados: metro");
  await expect(list.getByRole("button", { name: /^metro\b/ })).toBeVisible();
  await expect(bus).toHaveCount(0);

  // Delete another one.
  await groceries.click();
  const sheet = page.getByRole("dialog", { name: "Editar movimiento" });
  await sheet.getByRole("button", { name: "Eliminar" }).click();
  await expect(page.getByRole("status")).toContainText("Eliminado: groceries");
  await expect(groceries).toHaveCount(0);
  // Still on screen after the refetch that follows each write: page 2 is fetched again.
  await expect(list.getByRole("button", { name: /^metro\b/ })).toBeVisible();
  await expect(list.getByRole("button", { name: /^coffee 001\b/ })).toBeVisible();

  const after = await october(page);
  expect(after).toHaveLength(EXTRA + 9);
  expect(after.find((t) => t.name === "metro")).toBeDefined();
  expect(after.find((t) => t.name === "bus")).toBeUndefined();
  expect(after.find((t) => t.name === "groceries")).toBeUndefined();

  // A category's detail pages the same way: Restaurante has the 205 coffees and the dinner.
  const categories = (await (await page.request.get("/api/v1/categories")).json()) as {
    id: string;
    name: string;
  }[];
  const restaurante = categories.find((c) => c.name === "Restaurante");
  if (!restaurante) throw new Error("The sample has Restaurante");
  await page.goto(`/app/categories/${restaurante.id}?month=2026-10`);
  const detail = page.getByRole("region", { name: "Movimientos de octubre" });
  await expect(detail.getByRole("button", { name: /^dinner\b/ })).toBeVisible();
  await expect(detail.getByRole("button", { name: /^coffee 001\b/ })).toHaveCount(0);
  await detail.getByRole("button", { name: "Ver más movimientos" }).click();
  await expect(detail.getByRole("button", { name: /^coffee 001\b/ })).toBeVisible();
  await expect(detail.getByRole("button", { name: "Ver más movimientos" })).toHaveCount(0);
});
