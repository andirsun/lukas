import { expect, type Locator, type Page, test } from "@playwright/test";
import { clientIp, onboardWithSample, signUpNewUser } from "./helpers.ts";
import { centerOf, swipe, tap, touchDown } from "./touch.ts";

/**
 * The feel pass (Task 12c) on a phone with real touch (CDP touch events): the home pager follows
 * the finger, rows swipe to delete, edit and pay, the undo toast, the keypad on short phones, the
 * celebration's place, and the first ＋ after onboarding. Most of it runs in the demo (no API, a
 * pinned clock, a long list); paying and the first ＋ run against the dev stack.
 */

test.use({
  extraHTTPHeaders: async ({ extraHTTPHeaders }, use) =>
    use({ ...extraHTTPHeaders, "x-forwarded-for": clientIp() }),
});

test.beforeEach(({}, testInfo) => {
  test.skip(testInfo.project.name !== "phone", "Touch gestures: the phone project only");
});

const plus = (page: Page) => page.getByRole("button", { name: "Agregar", exact: true });
const tab = (page: Page, name: string) => page.getByRole("tab", { name });
const movimientos = (page: Page) => page.getByRole("tabpanel", { name: "Movimientos" });

/** The hero's figure (what assistive technology reads, not the count-up), as its digits. */
async function heroDigits(page: Page): Promise<number> {
  const text =
    (await page.locator(".lk-hero .lk-hero-amount .sr-only").first().textContent()) ?? "";
  return Number(text.replace(/\D/g, ""));
}

/** Valentina's demo month, on a pinned clock (21 October 2026, afternoon in Bogotá). */
async function openDemo(page: Page, lang: "es" | "en" = "es") {
  await page.clock.setFixedTime(new Date("2026-10-21T18:00:00Z"));
  await page.goto(`/demo?lang=${lang}`);
  await expect(
    page.getByRole("region", { name: lang === "es" ? "Te quedan este mes" : "Left this month" }),
  ).toBeVisible();
}

/** Paid rows (no pending badge): they swipe left to delete and right to edit. */
const paidRows = (page: Page, panel = "Movimientos") =>
  page.getByRole("tabpanel", { name: panel }).locator("[data-swipe-row]:not(:has(.lk-badge))");

/** A row's title, as it shows. */
const titleOf = (row: Locator) => row.locator(".lk-rowtop > span").first().innerText();

/** Where a row (or anything) starts, as a point a little inside its left or right edge. */
async function edgeOf(
  locator: Locator,
  side: "left" | "right" | "center",
): Promise<{ x: number; y: number }> {
  const box = await locator.boundingBox();
  if (!box) throw new Error("Not on screen");
  const x =
    side === "left"
      ? box.x + 40
      : side === "right"
        ? box.x + box.width - 40
        : box.x + box.width / 2;
  return { x, y: box.y + box.height / 2 };
}

test.describe("the tab pager", () => {
  test("follows the finger while dragging, moves the tab's indicator, and snaps", async ({
    page,
  }) => {
    await openDemo(page);
    await expect(tab(page, "Movimientos")).toHaveAttribute("aria-selected", "true");
    const panel = movimientos(page);
    const before = (await panel.boundingBox())?.x ?? 0;
    const thumb = page.locator(".lk-seg-thumb");
    const thumbBefore = (await thumb.boundingBox())?.x ?? 0;

    // From the right of the summary card (the pager owns it), 230 px to the left, slowly.
    const card = await centerOf(page.locator(".lk-hero"));
    const finger = await touchDown(page, { x: 330, y: card.y });
    await finger.moveTo({ x: 100, y: card.y }, { steps: 20 });
    await page.waitForTimeout(50);
    const during = (await panel.boundingBox())?.x ?? 0;
    // 1:1 with the finger (less the few px before the drag picks its axis).
    expect(before - during).toBeGreaterThan(215);
    expect(before - during).toBeLessThanOrEqual(231);
    const thumbDuring = (await thumb.boundingBox())?.x ?? 0;
    expect(thumbDuring).toBeGreaterThan(thumbBefore + 20);
    await finger.up();

    // Past half the width at rest: it settles on Presupuestos, remembered on the device.
    await expect(tab(page, "Presupuestos")).toHaveAttribute("aria-selected", "true");
    const budgets = page.getByRole("tabpanel", { name: "Presupuestos" });
    await expect.poll(async () => Math.round((await budgets.boundingBox())?.x ?? -1)).toBe(16);
    expect(await page.evaluate(() => localStorage.getItem("lukas.home.view"))).toBe("budgets");
  });

  test("a short flick switches, a short slow drag snaps back", async ({ page }) => {
    await openDemo(page);
    const hero = await centerOf(page.locator(".lk-hero"));
    // Slow and short: back to Movimientos.
    await swipe(page, hero, { dx: -60, steps: 20, stepMs: 20 });
    await page.waitForTimeout(400);
    await expect(tab(page, "Movimientos")).toHaveAttribute("aria-selected", "true");
    // Fast and short (80 px, under a quarter of the width): a flick.
    await swipe(page, hero, { dx: -80, steps: 2, stepMs: 0 });
    await expect(tab(page, "Presupuestos")).toHaveAttribute("aria-selected", "true");
    // The whole Presupuestos page swipes back (its rows do not swipe).
    const row = page.getByRole("tabpanel", { name: "Presupuestos" }).locator(".lk-rowcard").first();
    await swipe(page, await edgeOf(row, "left"), { dx: 200, steps: 12 });
    await expect(tab(page, "Movimientos")).toHaveAttribute("aria-selected", "true");
  });

  test("a vertical scroll on the list never changes tabs or opens a row", async ({ page }) => {
    await openDemo(page);
    const row = movimientos(page).locator("[data-swipe-row]").nth(2);
    const start = await edgeOf(row, "center");
    // Mostly down, a little sideways: scrolling wins.
    await swipe(page, start, { dx: -30, dy: -320, steps: 16 });
    await page.waitForTimeout(400);
    await expect(tab(page, "Movimientos")).toHaveAttribute("aria-selected", "true");
    expect(await page.evaluate(() => window.scrollY)).toBeGreaterThan(100);
    await expect(
      movimientos(page).getByRole("button", { name: "Borrar", exact: true }),
    ).toHaveCount(0);
  });

  test("a tap on the other tab still slides", async ({ page }) => {
    await openDemo(page);
    await tap(page, tab(page, "Presupuestos"));
    await expect(tab(page, "Presupuestos")).toHaveAttribute("aria-selected", "true");
    const budgets = page.getByRole("tabpanel", { name: "Presupuestos" });
    await expect.poll(async () => Math.round((await budgets.boundingBox())?.x ?? -1)).toBe(16);
  });
});

/** The pager track's offset, in px (0 on Movimientos). */
const trackX = (page: Page) =>
  page
    .locator("[data-pager-track]")
    .evaluate((element) => new DOMMatrix(getComputedStyle(element).transform).m41);
/** One page further along: a page's width and the 32 px gap. */
const pageStep = (page: Page) =>
  page
    .locator("[data-pager-track]")
    .evaluate((element) => (element as HTMLElement).offsetWidth + 32);
/** A row's face offset, in px (0 closed). */
const faceX = (row: Locator) =>
  row
    .locator(".lk-swipe-face")
    .evaluate((element) => new DOMMatrix(getComputedStyle(element).transform).m41);
/** A finger tap at a point, with nothing in between (for taps a few ms apart). */
const tapAt = async (page: Page, at: { x: number; y: number }) => (await touchDown(page, at)).up();

test.describe("a touch that interrupts a spring", () => {
  test("a double tap on Presupuestos settles on Presupuestos", async ({ page }) => {
    await openDemo(page);
    const at = await centerOf(tab(page, "Presupuestos"));
    await tapAt(page, at);
    await page.waitForTimeout(60);
    await tapAt(page, at);
    await expect(tab(page, "Presupuestos")).toHaveAttribute("aria-selected", "true");
    const step = await pageStep(page);
    await expect.poll(() => trackX(page)).toBeCloseTo(-step, 0);
    await page.waitForTimeout(300);
    expect(Math.abs((await trackX(page)) + step)).toBeLessThanOrEqual(1);
  });

  test("a tap on the tab, then on the summary card, settles on the tab's page", async ({
    page,
  }) => {
    await openDemo(page);
    const tabAt = await centerOf(tab(page, "Presupuestos"));
    const cardAt = await centerOf(page.locator(".lk-hero"));
    await tapAt(page, tabAt);
    await page.waitForTimeout(60);
    await tapAt(page, cardAt);
    await expect(tab(page, "Presupuestos")).toHaveAttribute("aria-selected", "true");
    const step = await pageStep(page);
    await expect.poll(() => trackX(page)).toBeCloseTo(-step, 0);
    await page.waitForTimeout(300);
    expect(Math.abs((await trackX(page)) + step)).toBeLessThanOrEqual(1);
  });

  test("a small row swipe, then a vertical scroll on it, settles the row closed", async ({
    page,
  }) => {
    await openDemo(page);
    const row = paidRows(page).nth(1);
    await row.evaluate((element) => element.scrollIntoView({ block: "center" }));
    const from = await edgeOf(row, "right");
    const title = await titleOf(row);
    // 32 px, slowly: under half the action and no flick, so it springs closed...
    await swipe(page, from, { dx: -32, steps: 8, stepMs: 24 });
    await page.waitForTimeout(30);
    // ...and a scroll starts on it mid-spring.
    await swipe(page, from, { dx: 0, dy: -200, steps: 10, stepMs: 16 });
    await expect.poll(() => faceX(row)).toBeCloseTo(0, 0);
    await page.waitForTimeout(300);
    expect(Math.abs(await faceX(row))).toBeLessThanOrEqual(1);
    // The same row, still there: nothing was deleted on the way.
    expect(await titleOf(row)).toBe(title);
    await expect(page.getByRole("status")).not.toContainText("Eliminado");
  });
});

test.describe("deep in a long list", () => {
  test("the tabs stay under the header, and a sideways drag on them turns the page", async ({
    page,
  }) => {
    await openDemo(page);
    await page.evaluate(() => window.scrollTo(0, document.documentElement.scrollHeight));
    await page.waitForTimeout(200);
    expect(await page.evaluate(() => window.scrollY)).toBeGreaterThan(800);
    const tabs = page.getByRole("tablist", { name: "Vista" });
    const box = await tabs.boundingBox();
    if (!box) throw new Error("tabs not on screen");
    // Stuck just under the demo banner, in view.
    const banner = await page.getByRole("complementary", { name: "Demo" }).boundingBox();
    expect(box.y).toBeGreaterThanOrEqual((banner?.y ?? 0) + (banner?.height ?? 0) - 1);
    expect(box.y).toBeLessThan(200);
    await swipe(page, { x: box.x + box.width - 30, y: box.y + box.height / 2 }, { dx: -230 });
    await expect(tab(page, "Presupuestos")).toHaveAttribute("aria-selected", "true");
  });
});

test.describe("row swipes", () => {
  test("left deletes, Deshacer brings it back, and the total is unchanged", async ({ page }) => {
    await openDemo(page);
    const before = await heroDigits(page);
    const row = paidRows(page).first();
    const title = await titleOf(row);
    const box = await row.boundingBox();
    if (!box) throw new Error("no row");

    await swipe(page, await edgeOf(row, "right"), { dx: -box.width * 0.6, steps: 16 });
    const toast = page.getByRole("status");
    await expect(toast).toContainText(`Eliminado: ${title}`);
    await expect(toast.locator(".lk-toast-progress")).toBeVisible();
    await expect.poll(() => heroDigits(page)).not.toBe(before);

    await tap(page, toast.getByRole("button", { name: "Deshacer" }));
    await expect(toast).toContainText(`De vuelta: ${title}`);
    await expect.poll(() => heroDigits(page)).toBe(before);
    await expect(movimientos(page).getByText(title, { exact: true }).first()).toBeVisible();
  });

  test("a short swipe leaves Borrar open; tapping elsewhere closes it, tapping it deletes", async ({
    page,
  }) => {
    await openDemo(page);
    const row = paidRows(page).nth(1);
    // Mid-screen, so no tap below has to scroll first (a scroll closes an open row too).
    await row.evaluate((element) => element.scrollIntoView({ block: "center" }));
    const title = await titleOf(row);
    await swipe(page, await edgeOf(row, "right"), { dx: -70, steps: 12, stepMs: 24 });
    const remove = movimientos(page).getByRole("button", { name: "Borrar", exact: true });
    await expect(remove).toBeVisible();
    // Elsewhere: the row's day heading.
    await tap(page, row.locator("xpath=ancestor::section[1]/h3"));
    await expect(remove).toHaveCount(0);
    await page.waitForTimeout(300);

    await swipe(page, await edgeOf(row, "right"), { dx: -70, steps: 12, stepMs: 24 });
    await tap(page, remove);
    await expect(page.getByRole("status")).toContainText(`Eliminado: ${title}`);
  });

  test("right opens the edit sheet", async ({ page }) => {
    await openDemo(page);
    const row = paidRows(page).first();
    const box = await row.boundingBox();
    if (!box) throw new Error("no row");
    await swipe(page, await edgeOf(row, "left"), { dx: box.width * 0.6, steps: 16 });
    await expect(page.getByRole("dialog", { name: "Editar movimiento" })).toBeVisible();
  });
});

test.describe("a category's detail", () => {
  test("its rows swipe too: left deletes, Deshacer brings it back", async ({ page }) => {
    await openDemo(page);
    await tap(page, tab(page, "Presupuestos"));
    await tap(
      page,
      page.getByRole("tabpanel", { name: "Presupuestos" }).getByText("Mercado").first(),
    );
    await expect(page).toHaveURL(/\/demo\/categories\/[0-9a-f-]+/);
    const row = page.locator("[data-swipe-row]:not(:has(.lk-badge))").first();
    await row.evaluate((element) => element.scrollIntoView({ block: "center" }));
    const title = await titleOf(row);
    const box = await row.boundingBox();
    if (!box) throw new Error("no row");
    await swipe(page, await edgeOf(row, "right"), { dx: -box.width * 0.6, steps: 16 });
    const toast = page.getByRole("status");
    await expect(toast).toContainText(`Eliminado: ${title}`);
    await tap(page, toast.getByRole("button", { name: "Deshacer" }));
    await expect(toast).toContainText(`De vuelta: ${title}`);
    // No sideways scroll was left behind by the swipe.
    expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBe(390);
  });
});

test.describe("in Madrid, on 21 October 2026", () => {
  test.use({ locale: "es-ES", timezoneId: "Europe/Madrid" });

  // Te quedan counts pending transactions already (packages/core summary.ts), so paying one
  // moves nothing on the hero: the row, the toast, the celebration and the API say it is paid.
  test("a pending row swiped right is paid, with its celebration; Te quedan holds because the summary already counts pending as spent", async ({
    page,
  }) => {
    await page.clock.install({ time: new Date("2026-10-21T15:00:00Z") });
    await signUpNewUser(page);
    await onboardWithSample(page, "Europe/Madrid");
    await page.goto("/app");
    const before = await heroDigits(page);
    const upcoming = movimientos(page)
      .getByRole("region", { name: /próximo/ })
      .first();
    const row = upcoming.locator("[data-swipe-row]").first();
    await expect(row).toContainText("video streaming");
    const box = await row.boundingBox();
    if (!box) throw new Error("no row");
    await swipe(page, await edgeOf(row, "left"), { dx: box.width * 0.6, steps: 16 });
    await expect(page.getByRole("status")).toContainText("Pagado: video streaming");
    await expect(page.getByTestId("celebration")).toBeAttached();
    await expect(row.getByText("Pagado")).toBeVisible();
    const october = (await (
      await page.request.get("/api/v1/transactions?month=2026-10&limit=200")
    ).json()) as { items: { name: string; status: string }[] };
    expect(october.items.find((t) => t.name === "video streaming")?.status).toBe("paid");
    expect(await heroDigits(page)).toBe(before);
  });
});

test.describe("dragging the sheet down from anywhere", () => {
  /** How far the sheet is dragged down, in px (0 at rest). */
  const sheetY = (page: Page) =>
    page
      .locator("[data-sheet-drag]")
      .evaluate((element) => new DOMMatrix(getComputedStyle(element).transform).m42);

  async function openSheet(page: Page) {
    await openDemo(page);
    await tap(page, plus(page));
    const sheet = page.getByRole("dialog", { name: "Nuevo gasto" });
    await expect(sheet).toBeVisible();
    // Done sliding in: its bottom edge is the screen's.
    const height = page.viewportSize()?.height ?? 0;
    await expect
      .poll(async () => {
        const box = await sheet.boundingBox();
        return box ? Math.round(box.y + box.height) : -1;
      })
      .toBe(height);
    return sheet;
  }

  test("down from a key follows the finger, closes the sheet, and types nothing", async ({
    page,
  }) => {
    const sheet = await openSheet(page);
    const amount = sheet.getByTestId("amount");
    const shown = await amount.innerText();
    const key = await centerOf(sheet.getByRole("button", { name: "5", exact: true }));
    const finger = await touchDown(page, key);
    await finger.moveTo({ x: key.x, y: key.y + 120 }, { steps: 12, stepMs: 20 });
    await page.waitForTimeout(50);
    // 1:1 with the finger, less the few px before the drag picks its axis.
    expect(await sheetY(page)).toBeGreaterThan(105);
    expect(await amount.innerText()).toBe(shown);
    await finger.moveTo({ x: key.x, y: key.y + 260 }, { steps: 10, stepMs: 20 });
    await finger.up();
    await expect(sheet).toBeHidden();
    // No digit went in: a new sheet starts empty, and nothing was saved.
    await expect(page.getByRole("status")).not.toContainText("Gasto");
  });

  test("a short drag springs back", async ({ page }) => {
    const sheet = await openSheet(page);
    await swipe(page, await centerOf(sheet.getByTestId("amount")), {
      dy: 60,
      steps: 12,
      stepMs: 24,
    });
    await page.waitForTimeout(500);
    await expect(sheet).toBeVisible();
    expect(Math.abs(await sheetY(page))).toBeLessThanOrEqual(1);
  });

  test("a downward flick closes it", async ({ page }) => {
    const sheet = await openSheet(page);
    await swipe(page, await centerOf(sheet.getByTestId("amount")), {
      dy: 70,
      steps: 2,
      stepMs: 0,
    });
    await expect(sheet).toBeHidden();
  });

  test("a tap on a key still types", async ({ page }) => {
    const sheet = await openSheet(page);
    await tap(page, sheet.getByRole("button", { name: "5", exact: true }));
    await expect(sheet.getByTestId("amount")).toContainText("5");
    expect(Math.abs(await sheetY(page))).toBeLessThanOrEqual(1);
  });

  test("a sideways swipe on the chips never moves the sheet", async ({ page }) => {
    const sheet = await openSheet(page);
    const chips = sheet.getByRole("group", { name: "Categoría" });
    const at = await centerOf(chips);
    const finger = await touchDown(page, { x: at.x + 100, y: at.y });
    await finger.moveTo({ x: at.x - 100, y: at.y + 10 }, { steps: 12 });
    expect(Math.abs(await sheetY(page))).toBeLessThanOrEqual(1);
    await finger.up();
    await page.waitForTimeout(300);
    await expect(sheet).toBeVisible();
    expect(Math.abs(await sheetY(page))).toBeLessThanOrEqual(1);
  });

  test("upward, a middle with more below scrolls; the sheet stays", async ({ page }) => {
    await page.setViewportSize({ width: 360, height: 640 });
    const sheet = await openSheet(page);
    const body = sheet.locator(".lk-sheet-body");
    const box = await body.boundingBox();
    if (!box) throw new Error("no body");
    await swipe(
      page,
      { x: box.x + box.width / 2, y: box.y + box.height - 20 },
      { dy: -120, steps: 12, stepMs: 20 },
    );
    await page.waitForTimeout(300);
    expect(await body.evaluate((element) => element.scrollTop)).toBeGreaterThan(40);
    expect(Math.abs(await sheetY(page))).toBeLessThanOrEqual(1);
  });

  test("a scrolled middle scrolls back to its top before the sheet moves", async ({ page }) => {
    await page.setViewportSize({ width: 360, height: 640 });
    const sheet = await openSheet(page);
    const body = sheet.locator(".lk-sheet-body");
    await body.evaluate((element) => {
      element.scrollTop = 120;
    });
    expect(await body.evaluate((element) => element.scrollTop)).toBeGreaterThan(60);
    // A finger on the scrolled middle (no scrolling things into view first: that would move it).
    const box = await body.boundingBox();
    if (!box) throw new Error("no body");
    await swipe(
      page,
      { x: box.x + box.width / 2, y: box.y + 40 },
      { dy: 100, steps: 12, stepMs: 20 },
    );
    await page.waitForTimeout(400);
    await expect(sheet).toBeVisible();
    expect(Math.abs(await sheetY(page))).toBeLessThanOrEqual(1);
    expect(await body.evaluate((element) => element.scrollTop)).toBeLessThan(60);
  });
});

test.describe("the keypad on short phones", () => {
  const sizes = [
    { width: 375, height: 667 },
    { width: 375, height: 812 },
    { width: 390, height: 844 },
    // An Android phone (412×893) less Chrome's bottom toolbar, and a small Android phone.
    { width: 412, height: 760 },
    { width: 360, height: 640 },
  ];

  for (const lang of ["es", "en"] as const) {
    for (const theme of ["night", "day"] as const) {
      test(`every key and the save button show, ${lang}, ${theme}`, async ({ page }) => {
        test.setTimeout(120_000);
        await page.addInitScript((value) => localStorage.setItem("lukas.theme", value), theme);
        const l =
          lang === "es"
            ? {
                add: "Agregar",
                sheet: "Nuevo gasto",
                edit: "Editar movimiento",
                backspace: "Borrar dígito",
                save: "Guardar",
                saveEdit: "Guardar cambios",
                panel: "Movimientos",
              }
            : {
                add: "Add",
                sheet: "New expense",
                edit: "Edit transaction",
                backspace: "Delete digit",
                save: "Save",
                saveEdit: "Save changes",
                panel: "Transactions",
              };
        await openDemo(page, lang);
        for (const size of sizes) {
          await page.setViewportSize(size);
          for (const which of ["add", "edit"] as const) {
            if (which === "add") {
              await tap(page, page.getByRole("button", { name: l.add, exact: true }));
            } else {
              await tap(page, paidRows(page, l.panel).first().locator(".lk-rowtop"));
            }
            const sheet = page.getByRole("dialog", { name: which === "add" ? l.sheet : l.edit });
            await expect(sheet).toBeVisible();
            // Done sliding up: its bottom edge is the screen's.
            await expect
              .poll(async () => {
                const box = await sheet.boundingBox();
                return box ? Math.round(box.y + box.height) : -1;
              })
              .toBe(size.height);
            const footer = sheet.locator(".lk-sheet-footer");
            const save = sheet.getByRole("button", {
              name: which === "add" ? l.save : l.saveEdit,
              exact: true,
            });
            const zero = sheet.getByRole("button", { name: "0", exact: true });
            const back = sheet.getByRole("button", { name: l.backspace, exact: true });
            for (const key of [zero, back, save]) {
              const box = await key.boundingBox();
              expect(box, `${which} at ${size.width}×${size.height}`).not.toBeNull();
              if (!box) continue;
              const where = `${which} at ${size.width}×${size.height}`;
              expect(box.y, where).toBeGreaterThanOrEqual(0);
              expect(box.y + box.height, where).toBeLessThanOrEqual(size.height);
              expect(box.height, where).toBeGreaterThanOrEqual(44);
            }
            // The keys sit above the save row, never under it.
            const saveRow = await save.boundingBox();
            for (const key of [zero, back]) {
              const box = await key.boundingBox();
              if (box && saveRow) expect(box.y + box.height).toBeLessThanOrEqual(saveRow.y);
            }
            // And they work: clear what is there, then 5, 0 and back to 5.
            const amount = sheet.getByTestId("amount");
            if (which === "edit") for (let i = 0; i < 12; i++) await tap(page, back);
            const cleared = await amount.innerText();
            await tap(page, sheet.getByRole("button", { name: "5", exact: true }));
            await expect(amount).not.toHaveText(cleared);
            const five = await amount.innerText();
            await tap(page, zero);
            await expect(amount).not.toHaveText(five);
            await tap(page, back);
            await expect(amount).toHaveText(five);
            expect(await footer.count()).toBe(1);
            await page.keyboard.press("Escape");
            await expect(sheet).toBeHidden();
          }
        }
      });
    }
  }
});

test.describe("the celebration", () => {
  test("Lukitas lands above the ＋, which stays visible and tappable", async ({ page }) => {
    await openDemo(page);
    await tap(page, plus(page));
    const sheet = page.getByRole("dialog", { name: "Nuevo gasto" });
    // Done sliding in (keys tapped mid-slide can move from under the finger).
    await expect
      .poll(async () => {
        const box = await sheet.boundingBox();
        return box ? Math.round(box.y + box.height) : -1;
      })
      .toBe(844);
    for (const key of ["5", "0", "0", "0"])
      await tap(page, sheet.getByRole("button", { name: key, exact: true }));
    await tap(
      page,
      sheet.getByRole("group", { name: "Categoría" }).getByRole("button", { name: "Mercado" }),
    );
    await tap(page, sheet.getByRole("button", { name: "Guardar", exact: true }));
    const lukas = page.locator(".lk-celebration-lukas");
    await expect(lukas).toBeVisible();
    // Past the pop (it lasts one --celebrate, 1.2 s): standing where he lands.
    await page.waitForTimeout(300);
    const box = await lukas.boundingBox();
    const button = await plus(page).boundingBox();
    if (!box || !button) throw new Error("not on screen");
    // Above the ＋ (never on it), centered on its column.
    expect(box.y + box.height).toBeLessThanOrEqual(button.y + 1);
    expect(Math.abs(box.x + box.width / 2 - (button.x + button.width / 2))).toBeLessThan(2);
    expect(
      await page.locator(".lk-celebration").evaluate((el) => getComputedStyle(el).pointerEvents),
    ).toBe("none");
    // The ＋ is what a finger finds at its center, and a tap there opens the sheet mid-party.
    const center = { x: button.x + button.width / 2, y: button.y + button.height / 2 };
    // (Once the closing sheet's backdrop is gone, while Lukitas is still up.)
    await expect
      .poll(() =>
        page.evaluate(
          ({ x, y }) => document.elementFromPoint(x, y)?.closest(".lk-plus")?.tagName ?? "none",
          center,
        ),
      )
      .toBe("BUTTON");
    await expect(page.getByTestId("celebration")).toBeAttached();
    await (await touchDown(page, center)).up();
    await expect(page.getByRole("dialog", { name: "Nuevo gasto" })).toBeVisible();
  });
});

test.describe("the first ＋ after onboarding", () => {
  test.use({ locale: "es-CO", timezoneId: "America/Bogota" });

  test("opens the sheet after Entrar directo", async ({ page }) => {
    await signUpNewUser(page);
    await tap(page, page.getByRole("button", { name: "Entrar directo" }));
    await expect(page).toHaveURL(/\/app$/);
    await tap(page, plus(page));
    await expect(page.getByRole("dialog", { name: "Nuevo gasto" })).toBeVisible();
  });

  test("opens the sheet after the full path", async ({ page }) => {
    await signUpNewUser(page);
    await tap(page, page.getByRole("button", { name: "Configurar en 1 minuto" }));
    for (const step of ["currency", "import", "categories", "budgets"]) {
      await expect(page).toHaveURL(new RegExp(`/welcome/${step}$`));
      if (step === "budgets") {
        await tap(page, page.getByRole("textbox").first());
        await page.keyboard.type("300000");
      }
      await tap(
        page,
        page.getByRole("button", { name: step === "import" ? "Saltar" : "Siguiente" }),
      );
    }
    await expect(page).toHaveURL(/\/app$/);
    await tap(page, plus(page));
    await expect(page.getByRole("dialog", { name: "Nuevo gasto" })).toBeVisible();
  });
});

test.describe("onboarding's budget field", () => {
  test.use({ locale: "es-CO", timezoneId: "America/Bogota" });

  test("groups thousands while typing and shows the lukas hint beside it", async ({ page }) => {
    await signUpNewUser(page);
    await page.getByRole("button", { name: "Configurar en 1 minuto" }).click();
    for (const step of ["currency", "import", "categories"]) {
      await expect(page).toHaveURL(new RegExp(`/welcome/${step}$`));
      await page.getByRole("button", { name: step === "import" ? "Saltar" : "Siguiente" }).click();
    }
    const field = page.getByRole("textbox", { name: "Presupuesto de Supermercado" });
    await field.click();
    await page.keyboard.type("300000");
    await expect(field).toHaveValue("300.000");
    await expect(field.locator("xpath=..")).toContainText("(300 lukas)");
  });
});
