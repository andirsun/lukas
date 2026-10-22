import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { PendingBadge } from "./PendingBadge.tsx";

const meta = {
  title: "UI/PendingBadge",
  component: PendingBadge,
  args: { onPay: fn(async () => {}) },
} satisfies Meta<typeof PendingBadge>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Tapping "Pendiente" pays it; once `onPay` resolves it turns into "✓ Pagado". */
export const IdleToPaid: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const badge = canvas.getByRole("button", { name: /Pendiente/ });
    await expect(badge).toHaveAccessibleName("Pendiente, marcar como pagado");
    const box = badge.getBoundingClientRect();
    await expect(box.height).toBeGreaterThanOrEqual(44);
    await expect(box.width).toBeGreaterThanOrEqual(44);

    await userEvent.click(badge);
    await expect(args.onPay).toHaveBeenCalledOnce();
    await expect(await canvas.findByText("Pagado")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Pagado/ })).toHaveAttribute(
      "aria-disabled",
      "true",
    );
    // Paying twice is not possible.
    await userEvent.click(canvas.getByRole("button", { name: /Pagado/ }));
    await expect(args.onPay).toHaveBeenCalledOnce();
  },
};

/** While the request is in flight the badge is busy and ignores further taps. */
export const Paying: Story = {
  args: { onPay: fn(() => new Promise<void>(() => {})) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const badge = canvas.getByRole("button", { name: /Pendiente/ });
    await userEvent.click(badge);
    await expect(badge).toHaveAttribute("aria-busy", "true");
    await userEvent.click(badge);
    await expect(args.onPay).toHaveBeenCalledOnce();
  },
};

/** If paying fails the badge goes back to "Pendiente" so it can be retried. */
export const PayFails: Story = {
  args: { onPay: fn(async () => Promise.reject(new Error("offline"))) },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Pendiente/ }));
    await expect(args.onPay).toHaveBeenCalledOnce();
    await waitFor(() =>
      expect(canvas.getByRole("button", { name: /Pendiente/ })).not.toHaveAttribute("aria-busy"),
    );
    await expect(canvas.queryByText("Pagado")).toBeNull();
  },
};

export const DayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Pending, mark as paid" }));
    await expect(await canvas.findByText("Paid")).toBeVisible();
  },
};
