import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { BudgetBar } from "./BudgetBar.tsx";

const meta = {
  title: "UI/BudgetBar",
  component: BudgetBar,
  decorators: [
    (Story) => (
      <div className="max-w-[360px]">
        <Story />
      </div>
    ),
  ],
} satisfies Meta<typeof BudgetBar>;

export default meta;
type Story = StoryObj<typeof meta>;

function fill(canvasElement: HTMLElement): HTMLElement {
  const meter = within(canvasElement).getByRole("meter");
  return meter.firstElementChild as HTMLElement;
}

/** Below 80 %: fills with what was spent, in `good`. */
export const Ok: Story = {
  args: { spent: 25_813, budget: 64_533, state: "ok", label: "Ocio · Quedan 387,20 €" },
  play: async ({ canvasElement }) => {
    const meter = within(canvasElement).getByRole("meter", { name: "Ocio · Quedan 387,20 €" });
    await expect(meter).toHaveAttribute("aria-valuenow", "25813");
    await expect(meter).toHaveAttribute("aria-valuemin", "0");
    await expect(meter).toHaveAttribute("aria-valuemax", "64533");
    await expect(meter).toHaveClass("lk-bar");
    await expect(meter).not.toHaveClass("is-near");
    await expect(fill(canvasElement).style.width).toBe("40%");
  },
};

/** From 80 %: `near`. The state comes from the API; the bar never recomputes it. */
export const Near: Story = {
  args: { spent: 26_254, budget: 30_887, state: "near", label: "Restaurante · Quedan 46,33 €" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByRole("meter")).toHaveClass("is-near");
    await expect(fill(canvasElement).style.width).toBe("85%");
  },
};

/** Over budget: `over`, the fill caps at full and the value stays within the meter's range. */
export const Over: Story = {
  args: {
    spent: 41_412,
    budget: 27_300,
    state: "over",
    label: "Supermercado · Te pasaste 141,12 €",
  },
  play: async ({ canvasElement }) => {
    const meter = within(canvasElement).getByRole("meter");
    await expect(meter).toHaveClass("is-over");
    await expect(meter).toHaveAttribute("aria-valuenow", "27300");
    await expect(fill(canvasElement).style.width).toBe("100%");
  },
};

/** No budget: an empty track with nothing to measure, left to the status line in words. */
export const NoBudget: Story = {
  args: { spent: 4_550, budget: null, state: "ok", label: "Regalos · Sin presupuesto" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).queryByRole("meter")).toBeNull();
    const track = canvasElement.querySelector(".lk-bar") as HTMLElement;
    await expect(track).toHaveAttribute("aria-hidden", "true");
    await expect((track.firstElementChild as HTMLElement).style.width).toBe("0%");
  },
};

/** The 7px bar used inside rows. */
export const Small: Story = {
  args: { spent: 2_000, budget: 10_000, state: "ok", size: "sm", label: "Transporte" },
  play: async ({ canvasElement }) => {
    const meter = within(canvasElement).getByRole("meter");
    await expect(meter).toHaveClass("lk-bar-sm");
    await expect(meter.getBoundingClientRect().height).toBe(7);
  },
};

export const OverDay: Story = {
  ...Over,
  globals: { theme: "day", locale: "en" },
};
