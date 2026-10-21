import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { expectEdge, expectFocusRing, expectTarget } from "../../.storybook/story-utils.ts";
import { ThemeToggle } from "./ThemeToggle.tsx";

const meta = {
  title: "UI/ThemeToggle",
  component: ThemeToggle,
} satisfies Meta<typeof ThemeToggle>;

export default meta;
type Story = StoryObj<typeof meta>;

const stored = () => localStorage.getItem("lukas.theme");
const theme = () => document.documentElement.dataset.theme;

/** Night (the default): a moon, labeled with what a press does; it switches to day and back, and remembers. */
export const Night: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const toggle = await canvas.findByRole("button", { name: "Cambiar a modo día" });
    await expect(toggle).not.toHaveAttribute("aria-pressed");
    await expect(toggle).toHaveClass("lk-btn");
    await expectTarget(toggle);
    await expectEdge(toggle, 3);
    await expect(toggle.querySelector("svg")).toHaveAttribute("aria-hidden", "true");

    await userEvent.click(toggle);
    await waitFor(() => expect(theme()).toBe("day"));
    await expect(stored()).toBe("day");
    const back = await canvas.findByRole("button", { name: "Cambiar a modo noche" });

    await userEvent.click(back);
    await waitFor(() => expect(theme()).toBe("night"));
    await expect(stored()).toBe("night");
    await expect(await canvas.findByRole("button", { name: "Cambiar a modo día" })).toBeVisible();
  },
};

/** Day: a sun; a press goes to night. */
export const Day: Story = {
  globals: { theme: "day" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(theme()).toBe("day");
    const toggle = await canvas.findByRole("button", { name: "Cambiar a modo noche" });
    await expectTarget(toggle);
    await expectEdge(toggle, 3);
    await userEvent.click(toggle);
    await waitFor(() => expect(theme()).toBe("night"));
    await expect(stored()).toBe("night");
  },
};

/** English labels, night. */
export const NightEnglish: Story = {
  globals: { locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const toggle = await canvas.findByRole("button", { name: "Switch to day mode" });
    await userEvent.click(toggle);
    await waitFor(() => expect(theme()).toBe("day"));
    await expect(await canvas.findByRole("button", { name: "Switch to night mode" })).toBeVisible();
  },
};

/** English labels, day. */
export const DayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("button", { name: "Switch to night mode" })).toBeVisible();
    await expect(theme()).toBe("day");
  },
};

/** Keyboard: Tab reaches it, the focus ring shows, Enter and Space switch the theme. */
export const Keyboard: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const toggle = await canvas.findByRole("button", { name: "Cambiar a modo día" });
    await userEvent.tab();
    await expect(toggle).toHaveFocus();
    await expectFocusRing(toggle);
    await userEvent.keyboard("{Enter}");
    await waitFor(() => expect(theme()).toBe("day"));
    await userEvent.keyboard(" ");
    await waitFor(() => expect(theme()).toBe("night"));
  },
};
