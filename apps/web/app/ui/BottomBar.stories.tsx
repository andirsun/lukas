import type { Meta, StoryObj } from "@storybook/react-vite";
import { MemoryRouter } from "react-router";
import { expect, fn, userEvent, within } from "storybook/test";
import {
  expectEdge,
  expectFocusRing,
  expectSunk,
  expectTarget,
} from "../../.storybook/story-utils.ts";
import { BottomBar } from "./BottomBar.tsx";

const meta = {
  title: "UI/BottomBar",
  component: BottomBar,
  parameters: { layout: "fullscreen" },
  decorators: [
    (Story) => (
      <MemoryRouter>
        <div className="lk-screen max-w-[390px] pt-(--space-6)">
          <Story />
        </div>
      </MemoryRouter>
    ),
  ],
  args: { current: "home", onAdd: fn() },
} satisfies Meta<typeof BottomBar>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Inicio · ＋ · Análisis: two links (the current one marked) and the raised add button. */
export const Home: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const nav = canvas.getByRole("navigation", { name: "Navegación principal" });
    const home = within(nav).getByRole("link", { name: "Inicio" });
    const insights = within(nav).getByRole("link", { name: "Análisis" });
    await expect(home).toHaveAttribute("href", "/app");
    await expect(home).toHaveAttribute("aria-current", "page");
    await expect(insights).toHaveAttribute("href", "/app/insights");
    await expect(insights).not.toHaveAttribute("aria-current");

    const add = within(nav).getByRole("button", { name: "Agregar" });
    await expect(add).toHaveClass("lk-plus");
    await expectEdge(add, 6);
    for (const target of [home, insights, add]) await expectTarget(target);

    await userEvent.click(add);
    await expect(args.onAdd).toHaveBeenCalledOnce();
  },
};

/** The ＋ sinks into its edge while pressed; tabs and ＋ show the focus ring. */
export const PressAndFocus: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const add = canvas.getByRole("button", { name: "Agregar" });
    add.classList.add("is-pressed");
    await expectSunk(add, 5);
    add.classList.remove("is-pressed");

    await userEvent.tab();
    await expectFocusRing(canvas.getByRole("link", { name: "Inicio" }));
    await userEvent.tab();
    await expect(add).toHaveFocus();
    await expectFocusRing(add);
  },
};

export const InsightsDayEnglish: Story = {
  args: { current: "insights" },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("link", { name: "Insights" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    await expect(canvas.getByRole("link", { name: "Home" })).not.toHaveAttribute("aria-current");
    await expect(canvas.getByRole("button", { name: "Add" })).toBeVisible();
  },
};
