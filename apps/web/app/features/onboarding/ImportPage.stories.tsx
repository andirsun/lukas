import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { ImportShellStage } from "./story-harness.tsx";

/**
 * `/app/import` in the signed-in frame, one picture per stage of the import: the sources, the
 * Budge how-to, the preview (and the warning before a currency switch), and the result with the
 * budgets. The mobile app is held to these pictures (docs/mobile/parity.md); the behaviour is
 * `Onboarding.stories.tsx`'s (`ImportPage*`, `Flow*`).
 */

interface Spies {
  onRequest(line: string): void;
}

const meta = {
  title: "Onboarding/Import page",
  args: { onRequest: fn() },
} satisfies Meta<Spies>;

export default meta;
type Story = StoryObj<Spies>;
type Canvas = ReturnType<typeof within>;

const upload = async (canvas: Canvas) =>
  userEvent.upload(
    await canvas.findByLabelText("Subir archivo de Budge"),
    new File(["Date,Payment\n"], "budge.csv", { type: "text/csv" }),
  );

/** From the sources to the preview of the sample file. */
const toPreview = async (canvas: Canvas) => {
  await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
  await upload(canvas);
  await canvas.findByRole("heading", { name: "Esto es lo que vamos a importar" });
};

/** Confirms the sample file and waits for the budgets, then leaves the page at its top. */
const toBudgets = async (canvas: Canvas) => {
  await toPreview(canvas);
  await userEvent.click(await canvas.findByRole("button", { name: "Importar 22 movimientos" }));
  const budgets = await canvas.findByRole("heading", { name: "Tus presupuestos" });
  await waitFor(() => expect(budgets).toHaveFocus());
  // The heading took the focus and the view with it: the picture is of the page from its top.
  window.scrollTo(0, 0);
};

/** The first thing: the title, the lead and the list of sources. */
export const Sources: Story = {
  render: (args) => <ImportShellStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Trae tu historial" }),
    ).toBeVisible();
    await expect(canvas.getByRole("heading", { name: "Desde dónde" })).toBeVisible();
  },
};

/** Budge's how-to and the picker. */
export const HowTo: Story = {
  render: (args) => <ImportShellStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    const howTo = canvas.getByRole("heading", { name: "Exporta tus movimientos de Budge" });
    await waitFor(() => expect(howTo).toHaveFocus());
  },
};

/** What the sample file holds, before anything is imported. */
export const Preview: Story = {
  render: (args) => <ImportShellStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await toPreview(canvas);
    await expect(canvas.getByRole("button", { name: "Importar 22 movimientos" })).toBeEnabled();
  },
};

/** The same preview in English, in the day theme. */
export const PreviewEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  render: (args) => <ImportShellStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Budge" }));
    await userEvent.upload(
      await canvas.findByLabelText("Upload a Budge file"),
      new File(["Date,Payment\n"], "budge.csv", { type: "text/csv" }),
    );
    await canvas.findByRole("heading", { name: "Here's what we'll import" });
  },
};

/** The rows with problems, opened. */
export const PreviewRejectedOpen: Story = {
  render: (args) => <ImportShellStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await toPreview(canvas);
    await userEvent.click(canvas.getByText("Ver las filas con problemas"));
    await expect(canvas.getByText("Línea 19: fecha no válida")).toBeVisible();
  },
};

/** A COP account with budgets, a EUR file: the preview says what the switch will do. */
export const PreviewSwitching: Story = {
  render: (args) => <ImportShellStage currency="COP" budgeted onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await toPreview(canvas);
    await expect(
      canvas.getByText("Tus presupuestos en COP se borrarán al cambiar a EUR."),
    ).toBeVisible();
  },
};

/** Imported: how many came in, and the budgets, prefilled from the file's recent months. */
export const Imported: Story = {
  render: (args) => <ImportShellStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    await toBudgets(within(canvasElement));
  },
};

/** The account took the file's currency: the line that says so, and the budgets in euros. */
export const ImportedSwitched: Story = {
  globals: { theme: "day" },
  render: (args) => <ImportShellStage currency="COP" budgeted onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await toBudgets(canvas);
    await expect(
      canvas.getByText("Tu archivo está en EUR, así que tu cuenta ahora usa EUR."),
    ).toBeVisible();
  },
};

/** The budgets saved. */
export const BudgetsSaved: Story = {
  render: (args) => <ImportShellStage currency="EUR" onRequest={args.onRequest} />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await toBudgets(canvas);
    await userEvent.click(canvas.getByRole("button", { name: "Guardar presupuestos" }));
    await expect(await canvas.findByText("Guardamos tus presupuestos.")).toBeVisible();
    window.scrollTo(0, 0);
  },
};
