import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { LukasBubble } from "./LukasBubble.tsx";

const meta = {
  title: "Lukas/LukasBubble",
  component: LukasBubble,
  decorators: [
    (Story) => (
      <div className="lk-screen max-w-[390px] p-(--space-4)">
        <Story />
      </div>
    ),
  ],
  args: { message: "¡Vas bien! Te quedan 11 días y aún tienes margen.", mood: "happy" },
} satisfies Meta<typeof LukasBubble>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Lukas beside his line. The line is the content; Lukas is decorative next to it. */
export const Happy: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const bubble = canvas.getByText("¡Vas bien! Te quedan 11 días y aún tienes margen.");
    await expect(bubble).toHaveClass("lk-bubble");
    await expect(bubble).toHaveAttribute("aria-live", "polite");
    const lukas = canvasElement.querySelector(".lk-lukas") as HTMLElement;
    await expect(lukas).toHaveAttribute("aria-hidden", "true");
    await expect(lukas).toHaveClass("is-happy");
    await expect(canvas.queryByRole("img")).toBeNull();
  },
};

export const Worried: Story = {
  args: { message: "Ojo: ya te pasaste 20,20 € en Supermercado.", mood: "worried" },
  play: async ({ canvasElement }) => {
    await expect(canvasElement.querySelector(".lk-lukas")).toHaveClass("is-worried");
    await expect(
      within(canvasElement).getByText("Ojo: ya te pasaste 20,20 € en Supermercado."),
    ).toBeVisible();
  },
};

export const CelebratingDay: Story = {
  args: { message: "¡Anotado!", mood: "celebrating" },
  globals: { theme: "day" },
  play: async ({ canvasElement }) => {
    await expect(canvasElement.querySelector(".lk-lukas")).toHaveClass("is-celebrating");
  },
};

const MONTH_LINE = "Vas muy bien: te quedan 501,13 € para 11 días.";
const PAID_LINE = "Pagaste «gym»: 32,00 €. Vas cumpliendo.";

/**
 * Home's sequence after a payment: the month's line, the payment's (same live region, so it is
 * announced), then the month's again with a new quiet key (a new live region: not announced). The
 * two buttons are story scaffolding, not app copy.
 */
function AfterPayment() {
  const [state, setState] = useState({ message: MONTH_LINE, quietKey: 0 });
  return (
    <div className="flex flex-col gap-(--space-3)">
      <LukasBubble message={state.message} mood="happy" quietKey={state.quietKey} />
      <button type="button" onClick={() => setState((s) => ({ ...s, message: PAID_LINE }))}>
        pay
      </button>
      <button
        type="button"
        onClick={() => setState((s) => ({ message: MONTH_LINE, quietKey: s.quietKey + 1 }))}
      >
        time passes
      </button>
    </div>
  );
}

/** The payment's line replaces the month's in place (read out once); its end swaps in quietly. */
export const PaymentLineThenQuiet: Story = {
  render: () => <AfterPayment />,
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const before = canvas.getByText(MONTH_LINE);
    await userEvent.click(canvas.getByRole("button", { name: "pay" }));
    const paid = canvas.getByText(PAID_LINE);
    await expect(paid).toBe(before);
    await expect(paid).toHaveAttribute("aria-live", "polite");
    // It fades in.
    await expect(paid.getAnimations().length).toBeGreaterThan(0);
    await userEvent.click(canvas.getByRole("button", { name: "time passes" }));
    const back = canvas.getByText(MONTH_LINE);
    await expect(back).not.toBe(paid);
    await expect(paid.isConnected).toBe(false);
    await expect(back).toHaveAttribute("aria-live", "polite");
  },
};

/** Under reduced motion a new line just shows: no fade. */
export const PaymentLineReducedMotion: Story = {
  render: () => <AfterPayment />,
  parameters: { reducedMotion: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "pay" }));
    const paid = await waitFor(() => canvas.getByText(PAID_LINE));
    await expect(paid.getAnimations()).toHaveLength(0);
  },
};
