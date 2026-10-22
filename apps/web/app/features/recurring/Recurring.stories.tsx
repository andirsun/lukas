import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, screen, userEvent, waitFor, within } from "storybook/test";
import { expectTarget } from "../../../.storybook/story-utils.ts";
import { HomeStage, STORY_TODAY } from "../home/story-harness.tsx";

/**
 * Recurring transactions (spec §2.7): the list with each one's next date, and the form to create,
 * edit and delete them (monthly or yearly, the day, the month for yearly ones, start, optional end).
 */

interface Spies {
  onRequest(line: string, headers: Record<string, string>): void;
}

const meta = {
  title: "Manage/Recurring",
  args: { onRequest: fn() },
  parameters: {
    viewport: {
      options: {
        phone: { name: "Phone", styles: { width: "390px", height: "844px" }, type: "mobile" },
        desktop: { name: "Desktop", styles: { width: "1280px", height: "800px" }, type: "desktop" },
      },
    },
  },
  globals: { viewport: { value: "phone", isRotated: false } },
} satisfies Meta<Spies>;

export default meta;
type Story = StoryObj<Spies>;
type Canvas = ReturnType<typeof within>;

const lines = (spy: Spies["onRequest"]) =>
  (spy as unknown as ReturnType<typeof fn>).mock.calls.map((call) => call[0] as string);
const recurrencePosts = (spy: Spies["onRequest"]) =>
  lines(spy).filter((l) => l.startsWith("POST /api/v1/recurrences"));

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

async function openNew(canvas: Canvas) {
  await userEvent.click(
    await canvas.findByRole("button", { name: "Nuevo recurrente" }, { timeout: 4000 }),
  );
  return within(await screen.findByRole("dialog", { name: "Nuevo recurrente" }));
}

/** Fills what every recurrence needs: amount, name and category. */
async function fillBasics(sheet: Canvas, { amount, name, category }: Record<string, string>) {
  await typeOnKeypad(sheet, amount as string);
  await userEvent.type(sheet.getByRole("textbox", { name: "Nombre" }), name as string);
  await userEvent.click(
    within(sheet.getByRole("group", { name: "Categoría" })).getByRole("button", {
      name: category as string,
    }),
  );
}

/** Each one with its rule in words and its next date. */
export const List: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/recurring" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByRole("heading", { level: 1, name: "Recurrentes" }, { timeout: 4000 }),
    ).toBeVisible();
    const day = Number(STORY_TODAY.slice(8, 10));
    const spotify = await canvas.findByRole("button", { name: /^Spotify −3,53\s€/ });
    await expect(spotify).toHaveAccessibleName(/Cada mes, el día \d+/);
    await expect(spotify).toHaveAccessibleName(/Próximo: /);
    await expectTarget(spotify);
    const insurance = canvas.getByRole("button", { name: /^Seguro del carro/ });
    await expect(insurance).toHaveAccessibleName(/Cada año, el 15 de marzo/);
    await expect(insurance).toHaveAccessibleName(/Próximo: 15 mar \d{4}/);
    const salary = canvas.getByRole("button", { name: /^Salario \+2500,00\s€/ });
    // The salary falls on the 1st: past this month (unless today is the 1st), so next month.
    await expect(salary).toHaveAccessibleName(day === 1 ? /Próximo: / : /Próximo: 1 /);
  },
};

/** A yearly one needs its month: without it nothing is sent and the form says so. */
export const YearlyRequiresMonth: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/recurring" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const sheet = await openNew(canvas);
    await fillBasics(sheet, { amount: "420", name: "Seguro de la moto", category: "Transporte" });
    await userEvent.click(sheet.getByRole("tab", { name: "Cada año" }));
    const month = sheet.getByRole("combobox", { name: "Mes" });
    await expect(month).toHaveValue("");
    await userEvent.click(sheet.getByRole("button", { name: "Guardar" }));
    await expect(await sheet.findByRole("alert")).toHaveTextContent(
      "Elige el mes en que se repite.",
    );
    await expect(month).toHaveAttribute("aria-invalid", "true");
    await expect(recurrencePosts(args.onRequest)).toHaveLength(0);

    await userEvent.selectOptions(month, "3");
    await userEvent.selectOptions(sheet.getByRole("combobox", { name: "Día del mes" }), "15");
    await userEvent.click(sheet.getByRole("button", { name: "Guardar" }));
    await dialogGone();
    await waitFor(() => expect(recurrencePosts(args.onRequest)).toHaveLength(1));
    const sent = JSON.parse(
      (recurrencePosts(args.onRequest)[0] as string).replace(/^POST \S+ /, ""),
    ) as Record<string, unknown>;
    await expect(sent).toMatchObject({
      name: "Seguro de la moto",
      amount: -42000,
      categoryId: "cat-transport",
      frequency: "yearly",
      dayOfMonth: 15,
      monthOfYear: 3,
      startDate: STORY_TODAY,
    });
    await expect(sent.endDate ?? null).toBeNull();
    await expect(
      await canvas.findByRole("button", { name: /^Seguro de la moto/ }, { timeout: 4000 }),
    ).toBeVisible();
    await toastShown("Guardaste Seguro de la moto.");
  },
};

/** A monthly income on the 23rd, with an end date. */
export const CreateMonthlyIncome: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/recurring" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const sheet = await openNew(canvas);
    await userEvent.click(sheet.getByRole("tab", { name: "Ingreso" }));
    await fillBasics(sheet, { amount: "150", name: "Clases", category: "Salario" });
    await userEvent.selectOptions(sheet.getByRole("combobox", { name: "Día del mes" }), "23");
    const year = Number(STORY_TODAY.slice(0, 4)) + 1;
    await userEvent.type(sheet.getByLabelText("Hasta (opcional)"), `${year}-06-30`);
    await userEvent.click(sheet.getByRole("button", { name: "Guardar" }));
    await dialogGone();
    await waitFor(() => expect(recurrencePosts(args.onRequest)).toHaveLength(1));
    await expect(recurrencePosts(args.onRequest)[0]).toContain('"amount":15000');
    await expect(recurrencePosts(args.onRequest)[0]).toContain('"frequency":"monthly"');
    await expect(recurrencePosts(args.onRequest)[0]).toContain('"dayOfMonth":23');
    await expect(recurrencePosts(args.onRequest)[0]).toContain(`"endDate":"${year}-06-30"`);
    await toastShown("Guardaste Clases.");
  },
};

/** Editing keeps what it had; deleting asks first and keeps the transactions it made. */
export const EditAndDelete: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/recurring" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(
      await canvas.findByRole("button", { name: /^Spotify/ }, { timeout: 4000 }),
    );
    const sheet = within(await screen.findByRole("dialog", { name: "Editar recurrente" }));
    await expect(sheet.getByRole("textbox", { name: "Nombre" })).toHaveValue("Spotify");
    await expect(sheet.getByTestId("recurring-amount")).toHaveTextContent("−3,53");
    await userEvent.click(sheet.getByRole("button", { name: "Eliminar recurrente" }));
    const confirm = within(await screen.findByRole("dialog", { name: "¿Eliminar Spotify?" }));
    await expect(
      confirm.getByText(/sus pendientes de este mes en adelante se borran/),
    ).toBeVisible();
    await userEvent.click(confirm.getByRole("button", { name: "Sí, eliminar" }));
    await dialogGone();
    await waitFor(() =>
      expect(lines(args.onRequest)).toContainEqual("DELETE /api/v1/recurrences/rec-spotify"),
    );
    await waitFor(() => expect(canvas.queryByRole("button", { name: /^Spotify/ })).toBeNull());
    await toastShown(/Eliminaste Spotify/);
  },
};

/**
 * Pesos: no decimal key, the muted lukas hint follows the typed figure (worked out from the ×100
 * amount that is sent), and the expense is stored negative in hundredths.
 */
export const PesosRecurring: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/recurring" currency="COP" />,
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const sheet = await openNew(canvas);
    const keypad = within(sheet.getByRole("group", { name: "Teclado numérico" }));
    await expect(keypad.queryByRole("button", { name: "Coma decimal" })).toBeNull();
    await fillBasics(sheet, { amount: "50000", name: "Arriendo", category: "Casa" });
    await expect(sheet.getByTestId("recurring-amount")).toHaveTextContent("−$50.000 (50 lukas)");
    await userEvent.click(sheet.getByRole("button", { name: "Guardar" }));
    await dialogGone();
    await waitFor(() => expect(recurrencePosts(args.onRequest)).toHaveLength(1));
    await expect(recurrencePosts(args.onRequest)[0]).toContain('"amount":-5000000');
    await expect(
      await canvas.findByRole("button", { name: /^Arriendo −\$50\.000/ }, { timeout: 4000 }),
    ).toBeVisible();
    await toastShown("Guardaste Arriendo.");
  },
};

/** Nothing yet: Lukitas explains what goes here, and the way to add one. */
export const Empty: Story = {
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/recurring" noRecurrences />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByText(/Aquí van tus pagos fijos/, {}, { timeout: 4000 }),
    ).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Nuevo recurrente" })).toBeVisible();
  },
};

/** Wide screens, day theme: the sidebar marks Recurrentes; the form open for the a11y checks. */
export const DesktopDay: Story = {
  globals: { viewport: { value: "desktop", isRotated: false }, theme: "day" },
  render: (args) => <HomeStage onRequest={args.onRequest} path="/app/recurring" />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await canvas.findByRole("button", { name: /^Spotify/ }, { timeout: 4000 });
    const nav = within(canvas.getByRole("navigation", { name: "Navegación principal" }));
    await expect(nav.getByRole("link", { name: "Recurrentes" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    const sheet = await openNew(canvas);
    await userEvent.click(sheet.getByRole("tab", { name: "Cada año" }));
    await expect(sheet.getByRole("combobox", { name: "Mes" })).toBeVisible();
  },
};
