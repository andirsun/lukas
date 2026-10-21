import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { Money } from "./Money.tsx";
import { PressButton } from "./PressButton.tsx";

const meta = {
  title: "UI/Money",
  component: Money,
  args: { cents: 56_292, currency: "EUR", className: "lk-hero-amount" },
} satisfies Meta<typeof Money>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Spanish format: `562,92 €`. */
export const Spanish: Story = {
  play: async ({ canvasElement }) => {
    await expect(canvasElement).toHaveTextContent("562,92 €");
    await expect(canvasElement.querySelector(".lk-num")).toHaveClass("lk-hero-amount");
  },
};

/** English format: `€562.92`. */
export const English: Story = {
  globals: { locale: "en" },
  play: async ({ canvasElement }) => {
    await expect(canvasElement).toHaveTextContent("€562.92");
  },
};

/** Expenses carry the real minus sign (U+2212), never a hyphen. */
export const Negative: Story = {
  args: { cents: -608, className: "lk-amount" },
  play: async ({ canvasElement }) => {
    await expect(canvasElement).toHaveTextContent("−6,08 €");
    await expect(canvasElement.textContent).not.toContain("-");
  },
};

export const NegativeDayEnglish: Story = {
  ...Negative,
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    await expect(canvasElement).toHaveTextContent("−€6.08");
  },
};

function CountUpHarness() {
  const [cents, setCents] = useState(56_292);
  return (
    <div className="lk-hero flex flex-col items-start gap-(--space-2)">
      <Money cents={cents} currency="EUR" animate className="lk-hero-amount" />
      <PressButton size="sm" variant="secondary" onClick={() => setCents((c) => c - 608)}>
        −6,08 €
      </PressButton>
    </div>
  );
}

/**
 * With `animate`, a new value counts up over `--count-up` (700ms); the final amount is what
 * assistive technology reads, never the intermediate frames.
 */
export const CountUp: Story = {
  render: () => <CountUpHarness />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvasElement).toHaveTextContent("562,92 €");
    await userEvent.click(canvas.getByRole("button"));
    const shown = canvasElement.querySelector("[aria-hidden='true']") as HTMLElement;
    const spoken = canvasElement.querySelector(".sr-only") as HTMLElement;
    // Mid-count: the visible figure is still on its way, the spoken one is already final.
    await new Promise((resolve) => setTimeout(resolve, 150));
    await expect(spoken).toHaveTextContent("556,84 €");
    await expect(shown.textContent).not.toBe("556,84 €");
    await waitFor(() => expect(shown).toHaveTextContent("556,84 €"), { timeout: 2000 });
  },
};

/** Reduced motion: no count-up, the new amount shows at once. */
export const CountUpReducedMotion: Story = {
  parameters: { reducedMotion: true },
  render: () => <CountUpHarness />,
  play: async ({ canvasElement }) => {
    await userEvent.click(within(canvasElement).getByRole("button"));
    const shown = canvasElement.querySelector("[aria-hidden='true']") as HTMLElement;
    await expect(shown).toHaveTextContent("556,84 €");
    await new Promise((resolve) => setTimeout(resolve, 150));
    await expect(shown).toHaveTextContent("556,84 €");
  },
};
