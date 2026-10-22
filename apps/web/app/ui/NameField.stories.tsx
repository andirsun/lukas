import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, userEvent, within } from "storybook/test";
import {
  expectEdge,
  expectFocusRing,
  expectSunk,
  expectTarget,
} from "../../.storybook/story-utils.ts";
import { NameField, type NameSuggestion } from "./NameField.tsx";

const RECENT: (NameSuggestion & { categoryId: string })[] = [
  { name: "continente", categoryName: "Supermercado", categoryId: "super" },
  { name: "pingo doce", categoryName: "Supermercado", categoryId: "super" },
  { name: "lidl", categoryName: "Supermercado", categoryId: "super" },
  { name: "café", categoryName: "Restaurante", categoryId: "food" },
  { name: "pintura", categoryName: "Casa", categoryId: "home" },
];

/**
 * The add sheet's wiring: typing filters the shortcuts (the API does it with `?q=`; here a
 * prefix-then-contains filter), picking one fills the name and selects its category.
 */
function NameFieldHarness({
  initial = "",
  onChange,
  onPick,
}: {
  initial?: string;
  onChange?: (value: string) => void;
  onPick?: (suggestion: NameSuggestion & { categoryId: string }) => void;
}) {
  const [value, setValue] = useState(initial);
  const [picked, setPicked] = useState<string | null>(null);
  const query = value.trim().toLowerCase();
  const exact = RECENT.some((s) => s.name.toLowerCase() === query);
  const suggestions =
    !query || exact
      ? RECENT
      : [
          ...RECENT.filter((s) => s.name.toLowerCase().startsWith(query)),
          ...RECENT.filter(
            (s) => !s.name.toLowerCase().startsWith(query) && s.name.toLowerCase().includes(query),
          ),
        ];
  return (
    <div className="flex max-w-[340px] flex-col gap-(--space-2)">
      <NameField
        value={value}
        placeholder="Supermercado"
        suggestions={suggestions}
        onChange={(next) => {
          setValue(next);
          onChange?.(next);
        }}
        onPick={(s) => {
          setValue(s.name);
          setPicked(s.categoryId);
          onPick?.(s);
        }}
      />
      <output aria-label="category">{picked}</output>
    </div>
  );
}

const meta = {
  title: "UI/NameField",
  component: NameFieldHarness,
  args: { onChange: fn(), onPick: fn() },
} satisfies Meta<typeof NameFieldHarness>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Empty: the placeholder is the name that will be used; recent names sit under the field. */
export const Empty: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const input = canvas.getByRole("textbox", { name: "Nombre (opcional)" });
    await expect(input).toHaveAttribute("placeholder", "Supermercado");
    await expect(input).not.toBeRequired();
    const group = canvas.getByRole("group", { name: "Nombres recientes" });
    const shortcuts = within(group).getAllByRole("button");
    await expect(shortcuts).toHaveLength(5);
    for (const shortcut of shortcuts) await expectTarget(shortcut);
    // Not typing: names only.
    await expect(within(group).queryByText("Supermercado")).toBeNull();
  },
};

/** Picking "continente" calls `onPick` with the suggestion; the caller fills the name and category. */
export const PickShortcut: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "continente" }));
    await expect(args.onPick).toHaveBeenCalledOnce();
    await expect(args.onPick).toHaveBeenCalledWith(
      expect.objectContaining({ name: "continente", categoryId: "super" }),
    );
    await expect(canvas.getByRole("textbox")).toHaveValue("continente");
    await expect(canvas.getByRole("status", { name: "category" })).toHaveTextContent("super");
    // The matching shortcut is marked; the others stay available.
    const hit = canvas.getByRole("button", { name: "continente" });
    await expect(hit).toHaveAttribute("aria-pressed", "true");
    await expect(canvas.getByRole("button", { name: "lidl" })).toHaveAttribute(
      "aria-pressed",
      "false",
    );
  },
};

/** Typing reports each change; the filtered shortcuts are labelled with their category. */
export const Typing: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const input = canvas.getByRole("textbox");
    await userEvent.type(input, "pin");
    await expect(args.onChange).toHaveBeenLastCalledWith("pin");
    const group = canvas.getByRole("group", { name: "Nombres recientes" });
    const shortcuts = within(group).getAllByRole("button");
    await expect(shortcuts.map((b) => b.textContent)).toEqual([
      "pingo doce · Supermercado",
      "pintura · Casa",
    ]);
    await expect(shortcuts[0]).toHaveAccessibleName("pingo doce · Supermercado");
    await userEvent.click(shortcuts[1] as HTMLElement);
    await expect(args.onPick).toHaveBeenCalledWith(expect.objectContaining({ name: "pintura" }));
  },
};

/** The field shows the focus ring while typing; shortcuts sit on an edge and sink when pressed. */
export const FocusAndPress: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.tab();
    const input = canvas.getByRole("textbox");
    await expect(input).toHaveFocus();
    await expectFocusRing(input.closest(".lk-input") as HTMLElement);
    const box = (input.closest(".lk-input") as HTMLElement).getBoundingClientRect();
    await expect(box.height).toBeGreaterThanOrEqual(44);

    const shortcut = canvas.getByRole("button", { name: "lidl" });
    const pill = shortcut.querySelector(".lk-shortcut") as HTMLElement;
    await expectEdge(pill, 3);
    shortcut.classList.add("is-pressed");
    await expectSunk(pill, 3);
    shortcut.classList.remove("is-pressed");

    await userEvent.tab();
    await expect(canvas.getByRole("button", { name: "continente" })).toHaveFocus();
    await expectFocusRing(
      canvas.getByRole("button", { name: "continente" }).querySelector(".lk-shortcut") as Element,
    );
  },
};

export const DayEnglish: Story = {
  args: { initial: "lidl" },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("textbox", { name: "Name (optional)" })).toHaveValue("lidl");
    await expect(canvas.getByRole("group", { name: "Recent names" })).toBeVisible();
    await expect(canvas.getByRole("button", { name: "lidl" })).toHaveAttribute(
      "aria-pressed",
      "true",
    );
  },
};

const MANY: NameSuggestion[] = [
  "lidl",
  "desayuno",
  "filtro cafetera delonghi",
  "continente",
  "contador octubre",
  "gas y luz",
  "super",
  "almuerzo con papás Rita",
  "farmacia",
  "gasolina",
].map((name) => ({ name, categoryName: "Casa" }));

/**
 * Only the two rows of shortcuts that fit show (the most used first: the API's order), so the
 * categories under the field stay in view; the rest are out of sight and out of the tab order.
 */
export const TwoRowsAtMost: Story = {
  render: () => (
    <div className="max-w-[340px]">
      <NameField
        value=""
        placeholder="Supermercado"
        suggestions={MANY}
        onChange={() => {}}
        onPick={() => {}}
      />
    </div>
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const shown = canvas.getAllByRole("button");
    const rows = new Set(shown.map((button) => Math.round(button.getBoundingClientRect().top)));
    await expect(rows.size).toBe(2);
    await expect(shown.length).toBeLessThan(MANY.length);
    // The first ones are kept, in order.
    await expect(shown.map((button) => button.textContent)).toEqual(
      MANY.slice(0, shown.length).map((s) => s.name),
    );
  },
};
