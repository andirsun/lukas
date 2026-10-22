import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import {
  expectEdge,
  expectFocusRing,
  expectSunk,
  expectTarget,
} from "../../.storybook/story-utils.ts";
import { TransactionRow } from "./TransactionRow.tsx";

const meta = {
  title: "UI/TransactionRow",
  component: TransactionRow,
  decorators: [
    (Story) => (
      <div className="max-w-[360px]">
        <Story />
      </div>
    ),
  ],
  args: {
    name: "continente",
    categoryName: "Supermercado",
    glyph: "🛒",
    amount: -608,
    currency: "EUR",
    status: "paid",
    onOpen: fn(),
  },
} satisfies Meta<typeof TransactionRow>;

export default meta;
type Story = StoryObj<typeof meta>;

/** An expense: name, category and the amount with a real minus sign; the row opens the editor. */
export const Expense: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const amount = canvas.getByText("−6,08 €");
    await expect(amount).toHaveClass("lk-amount");
    await expect(amount).not.toHaveClass("text-good");

    const row = canvas.getByRole("button", { name: /continente/ });
    await expect(row).toHaveAccessibleName(/^continente −6,08\s€ Supermercado$/);
    await expectTarget(row);
    await userEvent.click(row);
    await expect(args.onOpen).toHaveBeenCalledOnce();
    await expect(canvas.queryByText("Pendiente")).toBeNull();
  },
};

/** Without a name the row is titled with its category. */
export const Unnamed: Story = {
  args: { name: "  " },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByText("Supermercado")).toHaveLength(2);
    await expect(canvas.getByRole("button")).toHaveAccessibleName(
      /^Supermercado −6,08\s€ Supermercado$/,
    );
  },
};

/** Income shows a plus sign in `good`. */
export const Income: Story = {
  args: { name: "nómina", categoryName: "Salario", glyph: "💼", amount: 120000 },
  play: async ({ canvasElement }) => {
    const amount = within(canvasElement).getByText("+1200,00 €");
    await expect(amount).toHaveClass("text-good");
  },
};

/**
 * A pending transaction carries the PendingBadge after its category. Paying it is its own button:
 * it calls `onPay`, never `onOpen`; the rest of the row still opens the editor.
 */
export const Pending: Story = {
  args: {
    name: "Spotify",
    categoryName: "suscripciones",
    glyph: "☂️",
    amount: -353,
    status: "pending",
    onPay: fn(async () => {}),
  },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const badge = canvas.getByRole("button", { name: "Pendiente, marcar como pagado" });
    await expectTarget(badge);
    await userEvent.click(badge);
    await expect(args.onPay).toHaveBeenCalledOnce();
    await expect(args.onOpen).not.toHaveBeenCalled();
    await expect(await canvas.findByText("Pagado")).toBeVisible();

    await userEvent.click(canvas.getByRole("button", { name: /^Spotify/ }));
    await expect(args.onOpen).toHaveBeenCalledOnce();
  },
};

/** Pending without `onPay` (e.g. a future occurrence): a plain label, not a button, with no edge. */
export const PendingReadOnly: Story = {
  args: { ...Pending.args, onPay: undefined },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const label = canvas.getByText("Pendiente");
    await expect(label.closest("button")).toBeNull();
    await expect(canvas.getAllByRole("button")).toHaveLength(1);
    await expect(getComputedStyle(label).boxShadow).toBe("none");
  },
};

/** Solid edge, sink on press, focus ring from the keyboard; Tab reaches the badge next. */
export const PressAndFocus: Story = {
  args: Pending.args,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const row = canvas.getByRole("button", { name: /Spotify/ });
    const card = row.closest(".lk-rowcard") as HTMLElement;
    await expectEdge(card, 3);
    card.classList.add("is-pressed");
    await expectSunk(card, 3);
    card.classList.remove("is-pressed");

    await userEvent.tab();
    await expect(row).toHaveFocus();
    await expectFocusRing(row);
    await userEvent.tab();
    await expect(canvas.getByRole("button", { name: /Pendiente/ })).toHaveFocus();
  },
};

export const PendingDayEnglish: Story = {
  args: Pending.args,
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("−€3.53")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Pending, mark as paid" })).toBeVisible();
  },
};
