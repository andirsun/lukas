import { addMonths, monthOf } from "@lukas/core";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, screen, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { HomeStage, STORY_TODAY } from "../home/story-harness.tsx";

/**
 * A category's detail (spec §2.7: the month's transactions in it, its budget from the selected
 * month on, rename / icon / color, archive) and the categories page (list, archived toggle,
 * create, edit), against the fake API.
 */

interface Spies {
  onRequest(line: string, headers: Record<string, string>): void;
}

const meta = {
  title: "Manage/Categories",
  args: { onRequest: fn() },
  parameters: {
    viewport: {
      options: {
        phone: { name: "Phone", styles: { width: "390px", height: "844px" }, type: "mobile" },
        shortPhone: {
          name: "Short phone",
          styles: { width: "360px", height: "640px" },
          type: "mobile",
        },
        desktop: { name: "Desktop", styles: { width: "1280px", height: "800px" }, type: "desktop" },
      },
    },
  },
  globals: { viewport: { value: "phone", isRotated: false } },
} satisfies Meta<Spies>;

export default meta;
type Story = StoryObj<Spies>;
type Canvas = ReturnType<typeof within>;

const MONTH = monthOf(STORY_TODAY);
/** Text content is compared with its whitespace collapsed (the NBSP before € included). */
const NBSP = " ";
const eur = (text: string) => `${text}${NBSP}€`;

const lines = (spy: Spies["onRequest"]) =>
  (spy as unknown as ReturnType<typeof fn>).mock.calls.map((call) => call[0] as string);

const dialogGone = () =>
  waitFor(() => expect(screen.queryByRole("dialog")).toBeNull(), { timeout: 8000 });

/**
 * Waits until the toast saying `text` has fully faded in, so the a11y checks after the play
 * function never measure its contrast mid-animation.
 */
const toastShown = (text: string | RegExp) =>
  waitFor(
    () => {
      const toast = screen.getByRole("status").querySelector<HTMLElement>(".lk-toast");
      expect(toast).toHaveTextContent(text);
      expect(toast && getComputedStyle(toast).opacity).toBe("1");
    },
    // On a loaded machine the toast's fade-in comes late.
    { timeout: 8000 },
  );

async function typeOnKeypad(dialog: Canvas, text: string) {
  const keypad = within(dialog.getByRole("group", { name: "Teclado numérico" }));
  for (const key of text) {
    await userEvent.click(keypad.getByRole("button", { name: key === "," ? "Coma decimal" : key }));
  }
}

function paste(text: string) {
  const clipboard = new DataTransfer();
  clipboard.setData("text/plain", text);
  document.dispatchEvent(
    new ClipboardEvent("paste", { clipboardData: clipboard, bubbles: true, cancelable: true }),
  );
}

const budgetRegion = (canvas: Canvas) => canvas.findByRole("region", { name: "Presupuesto" });

// -- Category detail -------------------------------------------------------------------------------

/** Ocio this month: its budget in words and as a bar, and only its transactions. */
export const Detail: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("heading", { level: 1, name: "Ocio" })).toBeVisible();
    const budget = await budgetRegion(canvas);
    await waitFor(() => expect(budget).toHaveTextContent(`Quedan ${eur("383,67")}`));
    await expect(budget).toHaveTextContent(`Gastado ${eur("266,33")} de ${eur("650,00")}`);
    const list = within(canvas.getByRole("region", { name: /^Movimientos de / }));
    await expect(list.getByRole("button", { name: /^cine −262,80\s€/ })).toBeVisible();
    await expect(list.getByRole("button", { name: /^Spotify −3,53\s€/ })).toBeVisible();
    // Another category's spending is not here.
    await expect(list.queryByRole("button", { name: /^desayuno/ })).toBeNull();
    await expectTarget(canvas.getByRole("button", { name: "Cambiar presupuesto" }));
    await expectTarget(canvas.getByRole("link", { name: "Volver al inicio" }));
  },
};

/**
 * The budget sheet: a negative amount is refused (typed or pasted) and never sent; a valid one is
 * saved from the month on screen, and the bar follows.
 */
export const BudgetRejectsNegatives: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const budget = await budgetRegion(canvas);
    await waitFor(() => expect(budget).toHaveTextContent(`Quedan ${eur("383,67")}`));
    await userEvent.click(canvas.getByRole("button", { name: "Cambiar presupuesto" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Presupuesto de Ocio" }));
    await expect(sheet.getByText(/^Desde .+ en adelante/)).toBeVisible();
    // It starts from the budget it has.
    await expect(sheet.getByTestId("budget-amount")).toHaveTextContent(eur("650"));

    await userEvent.keyboard("-");
    await expect(await sheet.findByRole("alert")).toHaveTextContent(
      "Un presupuesto no puede ser negativo.",
    );
    paste("-50");
    await expect(sheet.getByRole("alert")).toHaveTextContent(
      "Un presupuesto no puede ser negativo.",
    );
    await expect(sheet.getByTestId("budget-amount")).toHaveTextContent(eur("650"));
    await expect(lines(args.onRequest).filter((l) => l.startsWith("PUT "))).toHaveLength(0);

    // Clear it and type 700.
    for (let i = 0; i < 3; i++) await userEvent.keyboard("{Backspace}");
    await typeOnKeypad(sheet, "700");
    await expect(sheet.queryByRole("alert")).toBeNull();
    await userEvent.click(sheet.getByRole("button", { name: "Guardar presupuesto" }));
    await dialogGone();
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        `PUT /api/v1/categories/cat-fun/budget {"amount":70000,"effectiveFrom":"${MONTH}"}`,
      ),
    );
    await waitFor(() => expect(budget).toHaveTextContent(`Quedan ${eur("433,67")}`));
    await toastShown("Presupuesto de Ocio: 700,00");
  },
};

/**
 * The budget sheet as it opens (for the app's parity pictures): the budget in force on the keypad,
 * the month it applies from, and Guardar presupuesto.
 */
export const BudgetSheetOpen: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const budget = await budgetRegion(canvas);
    await waitFor(() => expect(budget).toHaveTextContent(`Quedan ${eur("383,67")}`));
    await userEvent.click(canvas.getByRole("button", { name: "Cambiar presupuesto" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Presupuesto de Ocio" }));
    await expect(sheet.getByTestId("budget-amount")).toHaveTextContent(eur("650"));
  },
};

/** The solid edge under a key (`.lk-key`'s `box-shadow: 0 3px 0`). */
const KEY_EDGE = 3;

/**
 * Opens the budget sheet and checks its keypad against the stuck footer: every key, the last row's
 * "," 0 ⌫ included, ends (with its 3px solid edge) above "Guardar presupuesto"'s footer, which
 * never covers or clips it. The sheet
 * scrolls as a whole, so on a phone too short for it the keypad must still be whole once it is
 * scrolled to its end, and on one that fits it must be whole without scrolling.
 */
const keypadFits = (args: Spies, { scrolls }: { scrolls: boolean }): NonNullable<Story["play"]> => {
  void args;
  return async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const budget = await budgetRegion(canvas);
    await waitFor(() => expect(budget).toHaveTextContent(`Quedan ${eur("383,67")}`));
    await userEvent.click(canvas.getByRole("button", { name: "Cambiar presupuesto" }));
    const dialog = await screen.findByRole("dialog", { name: "Presupuesto de Ocio" });
    await expect(within(dialog).getByTestId("budget-amount")).toHaveTextContent(eur("650"));
    // The sheet has slid in (it opens from below the screen).
    await waitFor(
      () => expect(dialog.getBoundingClientRect().bottom).toBeLessThanOrEqual(innerHeight + 1),
      { timeout: 8000 },
    );
    await new Promise((resolve) => setTimeout(resolve, 500));
    const footer = dialog.querySelector(".lk-sheet-footer");
    if (!footer) throw new Error("the budget sheet has no stuck footer");
    const save = within(dialog).getByRole("button", { name: "Guardar presupuesto" });
    const keys = [...dialog.querySelectorAll<HTMLElement>(".lk-key")];
    await expect(keys).toHaveLength(12);
    const fits = (where: string) => {
      const footerTop = footer.getBoundingClientRect().top;
      const sheetTop = dialog.getBoundingClientRect().top;
      for (const key of keys) {
        const box = key.getBoundingClientRect();
        const name = `${key.textContent || "⌫"} (${where})`;
        // Whole, with its solid edge, above the footer.
        expect(box.bottom + KEY_EDGE, `${name} ends above Guardar's footer`).toBeLessThanOrEqual(
          footerTop,
        );
        expect(box.top, `${name} is below the sheet's top`).toBeGreaterThanOrEqual(sheetTop);
      }
      const saveBox = save.getBoundingClientRect();
      expect(saveBox.bottom, "Guardar is in view").toBeLessThanOrEqual(innerHeight);
    };
    if (!scrolls) {
      await expect(dialog.scrollHeight).toBeLessThanOrEqual(dialog.clientHeight);
      fits("as it opens");
    }
    dialog.scrollTop = dialog.scrollHeight;
    await new Promise((resolve) => setTimeout(resolve, 100));
    fits("scrolled to its end");
  };
};

/** The budget sheet on a 390 × 844 phone: the keypad is whole above "Guardar presupuesto". */
export const BudgetSheetKeypadFits: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: keypadFits({ onRequest: fn() }, { scrolls: false }),
};

/** The same on a short phone, 360 × 640: whole once scrolled to the end, and in view. */
export const BudgetSheetKeypadFitsShortPhone: Story = {
  globals: { viewport: { value: "shortPhone", isRotated: false } },
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: keypadFits({ onRequest: fn() }, { scrolls: false }),
};

/** A minus typed on the keyboard is refused in words, and the amount stays (for the app's pictures). */
export const BudgetSheetNegative: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const budget = await budgetRegion(canvas);
    await waitFor(() => expect(budget).toHaveTextContent(`Quedan ${eur("383,67")}`));
    await userEvent.click(canvas.getByRole("button", { name: "Cambiar presupuesto" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Presupuesto de Ocio" }));
    await userEvent.keyboard("-");
    await expect(await sheet.findByRole("alert")).toHaveTextContent(
      "Un presupuesto no puede ser negativo.",
    );
    await expect(sheet.getByTestId("budget-amount")).toHaveTextContent(eur("650"));
  },
};

/** A budget changed while looking at last month applies from last month on. */
export const BudgetFromSelectedMonth: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await budgetRegion(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Mes anterior" }));
    await userEvent.click(await canvas.findByRole("button", { name: "Cambiar presupuesto" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Presupuesto de Ocio" }));
    for (let i = 0; i < 3; i++) await userEvent.keyboard("{Backspace}");
    await userEvent.keyboard("600");
    await userEvent.click(sheet.getByRole("button", { name: "Guardar presupuesto" }));
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        `PUT /api/v1/categories/cat-fun/budget {"amount":60000,"effectiveFrom":"${addMonths(MONTH, -1)}"}`,
      ),
    );
    await toastShown("Presupuesto de Ocio: 600,00");
  },
};

/** Archiving asks first: "Cancelar" changes nothing; "Sí, archivar" archives, and it can come back. */
export const ArchiveAsksForConfirmation: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await budgetRegion(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Editar categoría" }));
    let edit = within(await screen.findByRole("dialog", { name: "Editar categoría" }));
    await userEvent.click(edit.getByRole("button", { name: "Archivar categoría" }));
    let confirm = within(await screen.findByRole("dialog", { name: "¿Archivar Ocio?" }));
    await expect(confirm.getByText(/Sus movimientos se quedan/)).toBeVisible();
    // Ocio has two recurrences (Spotify, a film club): archiving stops them, and says so.
    await expect(
      confirm.getByText("También se detendrán 2 pagos recurrentes de esta categoría."),
    ).toBeVisible();
    await userEvent.click(confirm.getByRole("button", { name: "Cancelar" }));
    await dialogGone();
    await expect(lines(args.onRequest).filter((l) => l.startsWith("PATCH "))).toHaveLength(0);

    await userEvent.click(canvas.getByRole("button", { name: "Editar categoría" }));
    edit = within(await screen.findByRole("dialog", { name: "Editar categoría" }));
    await userEvent.click(edit.getByRole("button", { name: "Archivar categoría" }));
    confirm = within(await screen.findByRole("dialog", { name: "¿Archivar Ocio?" }));
    await userEvent.click(confirm.getByRole("button", { name: "Sí, archivar" }));
    await dialogGone();
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        'PATCH /api/v1/categories/cat-fun {"archived":true}',
      ),
    );
    await expect(await canvas.findByText(/Esta categoría está archivada/)).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Restaurar" }));
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        'PATCH /api/v1/categories/cat-fun {"archived":false}',
      ),
    );
    await waitFor(() => expect(canvas.queryByText(/Esta categoría está archivada/)).toBeNull());
    await toastShown("Ocio está de vuelta.");
  },
};

/** Rename, emoji and tint in one PATCH; the title follows. */
export const RenameAndRestyle: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories/cat-fun" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await budgetRegion(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Editar categoría" }));
    const edit = within(await screen.findByRole("dialog", { name: "Editar categoría" }));
    const name = edit.getByRole("textbox", { name: "Nombre" });
    await userEvent.clear(name);
    await userEvent.type(name, "Planes");
    await userEvent.click(edit.getByRole("radio", { name: "🎁" }));
    await userEvent.click(edit.getByRole("radio", { name: "Azul" }));
    await userEvent.click(edit.getByRole("button", { name: "Guardar categoría" }));
    await dialogGone();
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        'PATCH /api/v1/categories/cat-fun {"name":"Planes","icon":"🎁","color":"#3fa7ff"}',
      ),
    );
    await expect(await canvas.findByRole("heading", { level: 1, name: "Planes" })).toBeVisible();
    await toastShown("Guardaste los cambios de Planes.");
  },
};

/**
 * Pesos: the budget sheet starts from the stored budget (80.000.000 hundredths: $800.000, "800
 * lukas"), takes a pasted "15.000" as fifteen thousand pesos with its hint, refuses a minus, and
 * sends hundredths.
 */
export const BudgetInPesos: Story = {
  render: (args) => (
    <HomeStage onRequest={args.onRequest} path="/app/categories/cat-food" currency="COP" />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const budget = await budgetRegion(canvas);
    await waitFor(() => expect(budget).toHaveTextContent("Quedan $800.000"));
    await userEvent.click(canvas.getByRole("button", { name: "Cambiar presupuesto" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Presupuesto de Comida" }));
    const figure = sheet.getByTestId("budget-amount");
    await expect(figure).toHaveTextContent("$800.000 (800 lukas)");
    const keypad = within(sheet.getByRole("group", { name: "Teclado numérico" }));
    await expect(keypad.queryByRole("button", { name: "Coma decimal" })).toBeNull();

    paste("15.000");
    await waitFor(() => expect(figure).toHaveTextContent("$15.000 (15 lukas)"));
    await userEvent.keyboard("-");
    await expect(await sheet.findByRole("alert")).toHaveTextContent(
      "Un presupuesto no puede ser negativo.",
    );
    await expect(figure).toHaveTextContent("$15.000 (15 lukas)");
    await userEvent.click(sheet.getByRole("button", { name: "Guardar presupuesto" }));
    await dialogGone();
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        `PUT /api/v1/categories/cat-food/budget {"amount":1500000,"effectiveFrom":"${MONTH}"}`,
      ),
    );
    await toastShown("Presupuesto de Comida: $15.000 (15 lukas)");
  },
};

/** The archive sheet counts the recurrences it stops: one (singular), or none (no line). */
export const ArchiveCountsRecurrences: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const archiveFrom = async (name: string) => {
      await userEvent.click(await canvas.findByRole("button", { name: `Editar ${name}` }));
      const edit = within(await screen.findByRole("dialog", { name: "Editar categoría" }));
      await userEvent.click(edit.getByRole("button", { name: "Archivar categoría" }));
      return within(await screen.findByRole("dialog", { name: `¿Archivar ${name}?` }));
    };
    let confirm = await archiveFrom("Transporte");
    await expect(
      confirm.getByText("También se detendrá 1 pago recurrente de esta categoría."),
    ).toBeVisible();
    await userEvent.click(confirm.getByRole("button", { name: "Cancelar" }));
    await dialogGone();
    confirm = await archiveFrom("Supermercado");
    await expect(confirm.queryByText(/También se detendr/)).toBeNull();
    await userEvent.click(confirm.getByRole("button", { name: "Cancelar" }));
    await dialogGone();
    await expect(lines(args.onRequest).filter((l) => l.startsWith("PATCH "))).toHaveLength(0);
  },
};

// -- Categories page -------------------------------------------------------------------------------

/** Spending and income, each with its budget; the archived ones only on request. */
export const CategoriesList: Story = {
  render: (args) => (
    <HomeStage onRequest={args.onRequest} path="/app/categories" archivedCategory />
  ),
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Categorías" }),
    ).toBeVisible();
    const expenses = within(await canvas.findByRole("region", { name: "Gastos" }));
    await expect(
      await expenses.findByRole("link", { name: /^Supermercado Presupuesto: 180,00\s€$/ }),
    ).toHaveAttribute("href", "/app/categories/cat-groceries");
    const income = within(canvas.getByRole("region", { name: "Ingresos" }));
    await expect(income.getByRole("link", { name: /^Salario/ })).toBeVisible();
    // Transporte is archived: hidden until asked for.
    await expect(canvas.queryByRole("link", { name: /^Transporte/ })).toBeNull();
    const toggle = canvas.getByRole("button", { name: "Ver archivadas" });
    await expect(toggle).toHaveAttribute("aria-pressed", "false");
    await expectTarget(toggle);
    await userEvent.click(toggle);
    await expect(toggle).toHaveAttribute("aria-pressed", "true");
    const archived = within(canvas.getByRole("region", { name: "Archivadas" }));
    await expect(archived.getByRole("link", { name: /^Transporte/ })).toBeVisible();
    await userEvent.click(archived.getByRole("button", { name: "Restaurar Transporte" }));
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        'PATCH /api/v1/categories/cat-transport {"archived":false}',
      ),
    );
    await expect(await expenses.findByRole("link", { name: /^Transporte/ })).toBeVisible();
    await toastShown("Transporte está de vuelta.");
  },
};

/** "Nueva categoría": name, kind, emoji and tint; it joins the list. */
export const CreateCategory: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Nueva categoría" }));
    const sheet = within(await screen.findByRole("dialog", { name: "Nueva categoría" }));
    await userEvent.type(sheet.getByRole("textbox", { name: "Nombre" }), "Mascotas");
    await userEvent.click(sheet.getByRole("radio", { name: "🐶" }));
    await userEvent.click(sheet.getByRole("button", { name: "Guardar categoría" }));
    await dialogGone();
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual(
        expect.stringMatching(/^POST \/api\/v1\/categories .*"name":"Mascotas"/),
      ),
    );
    const expenses = within(canvas.getByRole("region", { name: "Gastos" }));
    await expect(await expenses.findByRole("link", { name: /^Mascotas/ })).toBeVisible();
    await toastShown("Listo: creaste Mascotas.");
  },
};

/** Editing from the list: the row's own "Editar" opens the same sheet. */
export const EditFromList: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/categories" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = await canvas.findByRole("button", { name: "Editar Supermercado" });
    await expectTarget(button);
    await userEvent.click(button);
    const sheet = within(await screen.findByRole("dialog", { name: "Editar categoría" }));
    await expect(sheet.getByRole("textbox", { name: "Nombre" })).toHaveValue("Supermercado");
    await expect(sheet.getByRole("button", { name: "Archivar categoría" })).toBeVisible();
  },
};

/** Wide screens: the sidebar marks Categorías. Day theme for the contrast checks. */
export const DesktopDay: Story = {
  globals: { viewport: { value: "desktop", isRotated: false }, theme: "day" },
  render: (args) => (
    <HomeStage onRequest={args.onRequest} path="/app/categories" archivedCategory />
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await canvas.findByRole("region", { name: "Gastos" });
    const nav = within(canvas.getByRole("navigation", { name: "Navegación principal" }));
    await expect(nav.getByRole("link", { name: "Categorías" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    await userEvent.click(canvas.getByRole("button", { name: "Ver archivadas" }));
  },
};
