import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, userEvent, within } from "storybook/test";
import {
  expectEdge,
  expectFocusRing,
  expectSunk,
  expectTarget,
  resolveColor,
} from "../../.storybook/story-utils.ts";
import { CategoryChip } from "./CategoryChip.tsx";

const CATEGORIES = [
  { id: "super", glyph: "🛒", label: "Supermercado" },
  { id: "food", glyph: "🍽️", label: "Restaurante" },
  { id: "fun", glyph: "⭐", label: "Ocio" },
  { id: "car", glyph: "🚗", label: "Transporte" },
];

/** The add sheet's picker: four per row, one selected. */
function Picker({ onSelect }: { onSelect?: (id: string) => void }) {
  const [selected, setSelected] = useState("super");
  return (
    <div className="lk-chips max-w-[320px]">
      {CATEGORIES.map((c) => (
        <CategoryChip
          key={c.id}
          glyph={c.glyph}
          label={c.label}
          selected={selected === c.id}
          onSelect={() => {
            setSelected(c.id);
            onSelect?.(c.id);
          }}
        />
      ))}
    </div>
  );
}

const meta = {
  title: "UI/CategoryChip",
  component: Picker,
  args: { onSelect: fn() },
} satisfies Meta<typeof Picker>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Each chip is a toggle named by its label; the selected one has the gold outline. */
export const Picker4: Story = {
  name: "Picker",
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const superChip = canvas.getByRole("button", { name: "Supermercado" });
    const fun = canvas.getByRole("button", { name: "Ocio" });
    await expect(superChip).toHaveAttribute("aria-pressed", "true");
    await expect(fun).toHaveAttribute("aria-pressed", "false");
    for (const chip of canvas.getAllByRole("button")) await expectTarget(chip);

    const tile = (chip: HTMLElement) => chip.querySelector(".lk-chip-tile") as HTMLElement;
    await expectEdge(tile(fun), 3);
    await expect(getComputedStyle(tile(superChip)).outlineColor).toBe(resolveColor("var(--gold)"));

    await userEvent.click(fun);
    await expect(args.onSelect).toHaveBeenCalledWith("fun");
    await expect(fun).toHaveAttribute("aria-pressed", "true");
    await expect(superChip).toHaveAttribute("aria-pressed", "false");
  },
};

/** The tile sinks into its edge while pressed; keyboard focus rings the whole chip. */
export const PressAndFocus: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const food = canvas.getByRole("button", { name: "Restaurante" });
    food.classList.add("is-pressed");
    const tile = food.querySelector(".lk-chip-tile") as HTMLElement;
    await expectSunk(tile, 3);
    food.classList.remove("is-pressed");

    await userEvent.tab();
    await userEvent.tab();
    await expect(food).toHaveFocus();
    await expectFocusRing(food);
    await userEvent.keyboard(" ");
    await expect(args.onSelect).toHaveBeenCalledWith("food");
  },
};

export const Day: Story = {
  globals: { theme: "day" },
  play: async ({ canvasElement }) => {
    const chip = within(canvasElement).getByRole("button", { name: "Supermercado" });
    await expect(chip).toHaveAttribute("aria-pressed", "true");
  },
};
