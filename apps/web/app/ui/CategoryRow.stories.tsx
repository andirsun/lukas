import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import {
  expectEdge,
  expectFocusRing,
  expectSunk,
  expectTarget,
} from "../../.storybook/story-utils.ts";
import { CategoryRow } from "./CategoryRow.tsx";

const meta = {
  title: "UI/CategoryRow",
  component: CategoryRow,
  decorators: [
    (Story) => (
      <div className="max-w-[360px]">
        <Story />
      </div>
    ),
  ],
  args: {
    name: "Supermercado",
    glyph: "🛒",
    tint: "#4a2140",
    budget: 18000,
    spent: 19412,
    remaining: -1412,
    state: "over",
    currency: "EUR",
    onOpen: fn(),
  },
} satisfies Meta<typeof CategoryRow>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Over budget: the status says so in words, next to a full bar in `over`. */
export const Over: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const status = canvas.getByText("Te pasaste 14,12 €");
    await expect(status).toBeVisible();
    await expect(status).toHaveClass("lk-status", "is-over");
    await expect(canvas.getByText("180,00 €")).toBeVisible();

    const bar = canvas.getByRole("meter", { name: /^Supermercado: Te pasaste 14,12\s€$/ });
    await expect(bar).toHaveClass("is-over");

    const row = canvas.getByRole("button", { name: /Supermercado/ });
    await expect(row).toHaveAccessibleName(/^Supermercado Te pasaste 14,12\s€$/);
    await expectTarget(row);
    await userEvent.click(row);
    await expect(args.onOpen).toHaveBeenCalledOnce();
  },
};

/** Near the limit: "Quedan" in `near`. */
export const Near: Story = {
  args: {
    name: "Restaurante",
    glyph: "🍽️",
    tint: "#4a2a30",
    budget: 30000,
    spent: 25367,
    remaining: 4633,
    state: "near",
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Quedan 46,33 €")).toHaveClass("is-near");
    await expect(canvas.getByRole("meter")).toHaveClass("is-near");
  },
};

/** Within budget: "Quedan" in the muted status color. */
export const Ok: Story = {
  args: {
    name: "Ocio",
    glyph: "⭐",
    tint: "#3b2560",
    budget: 65000,
    spent: 26280,
    remaining: 38720,
    state: "ok",
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const status = canvas.getByText("Quedan 387,20 €");
    await expect(status).not.toHaveClass("is-near");
    await expect(status).not.toHaveClass("is-over");
  },
};

/** Without a budget: "Sin presupuesto", what was spent, and no bar. */
export const NoBudget: Story = {
  args: {
    name: "Regalos",
    glyph: "🎁",
    tint: "#2b2a5a",
    budget: null,
    spent: 2500,
    remaining: null,
    state: "ok",
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Sin presupuesto")).toBeVisible();
    await expect(canvas.getByText("Gastado 25,00 €")).toBeVisible();
    await expect(canvas.queryByRole("meter")).toBeNull();
    await expect(canvasElement.querySelector(".lk-bar")).toBeNull();
  },
};

/** The row sits on a solid edge, sinks while pressed, and shows the focus ring from the keyboard. */
export const PressAndFocus: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const row = canvas.getByRole("button", { name: /Supermercado/ });
    const card = row.closest(".lk-rowcard") as HTMLElement;
    await expectEdge(card, 3);

    card.classList.add("is-pressed");
    await expectSunk(card, 3);
    card.classList.remove("is-pressed");

    await userEvent.tab();
    await expect(row).toHaveFocus();
    await expectFocusRing(row);
    await userEvent.keyboard("{Enter}");
    await expect(args.onOpen).toHaveBeenCalledOnce();
  },
};

export const OverDayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("€14.12 over")).toBeVisible();
    await expect(canvas.getByRole("meter", { name: "Supermercado: €14.12 over" })).toBeVisible();
  },
};

export const NoBudgetEnglish: Story = {
  args: NoBudget.args,
  globals: { locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("No budget")).toBeVisible();
    await expect(canvas.getByText("€25.00 spent")).toBeVisible();
  },
};
