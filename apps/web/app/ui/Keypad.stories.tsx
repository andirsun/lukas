import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, userEvent, within } from "storybook/test";
import { expectEdge, expectFocusRing, expectTarget } from "../../.storybook/story-utils.ts";
import { type Locale, parseAmountInput } from "../i18n/format.ts";
import { Keypad } from "./Keypad.tsx";

/**
 * The keypad as the add sheet uses it: it owns the raw text, and the caller parses it with
 * `parseAmountInput`. The two outputs show both (story scaffolding, not app copy).
 */
function KeypadHarness({
  locale,
  initial = "",
  onChange,
}: {
  locale: Locale;
  initial?: string;
  onChange?: (value: string) => void;
}) {
  const [value, setValue] = useState(initial);
  let cents = "";
  try {
    cents = value ? String(parseAmountInput(value, locale)) : "";
  } catch {
    cents = "invalid";
  }
  return (
    <div className="flex max-w-[320px] flex-col gap-(--space-3)">
      <output aria-label="raw" className="lk-amount-display text-ink">
        {value}
      </output>
      <output aria-label="cents" className="text-ink-muted">
        {cents}
      </output>
      <Keypad
        value={value}
        locale={locale}
        onChange={(next) => {
          setValue(next);
          onChange?.(next);
        }}
      />
    </div>
  );
}

const meta = {
  title: "UI/Keypad",
  component: KeypadHarness,
  args: { locale: "es", onChange: fn() },
} satisfies Meta<typeof KeypadHarness>;

export default meta;
type Story = StoryObj<typeof meta>;

async function press(canvas: ReturnType<typeof within>, ...keys: string[]) {
  const names: Record<string, RegExp | string> = {
    ",": "Coma decimal",
    ".": "Decimal point",
    "⌫": /Borrar|Delete/,
  };
  for (const key of keys)
    await userEvent.click(canvas.getByRole("button", { name: names[key] ?? key }));
}

/** Review focus #3 (es): 6 , 0 8 → "6,08", which parses to 608 cents. */
export const Spanish: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const pad = canvas.getByRole("group", { name: "Teclado numérico" });
    await expect(within(pad).getAllByRole("button")).toHaveLength(12);
    for (const key of within(pad).getAllByRole("button")) await expectTarget(key);
    await expect(canvas.getByRole("button", { name: "Coma decimal" })).toHaveTextContent(",");
    await expect(canvas.queryByRole("button", { name: "Decimal point" })).toBeNull();

    await press(canvas, "6", ",", "0", "8");
    await expect(args.onChange).toHaveBeenLastCalledWith("6,08");
    await expect(canvas.getByRole("status", { name: "raw" })).toHaveTextContent("6,08");
    await expect(canvas.getByRole("status", { name: "cents" })).toHaveTextContent("608");
  },
};

/** Review focus #3 (en): the decimal key shows "." and 6 . 0 8 → "6.08" → 608 cents. */
export const English: Story = {
  args: { locale: "en" },
  globals: { locale: "en" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const decimal = canvas.getByRole("button", { name: "Decimal point" });
    await expect(decimal).toHaveTextContent(".");
    await expect(canvas.queryByText(",")).toBeNull();
    await expect(canvas.getByRole("group", { name: "Keypad" })).toBeVisible();

    await press(canvas, "6", ".", "0", "8");
    await expect(args.onChange).toHaveBeenLastCalledWith("6.08");
    await expect(canvas.getByRole("status", { name: "cents" })).toHaveTextContent("608");
  },
};

/** At most two decimals: a third one is ignored, and so is a second decimal key. */
export const MaxTwoDecimals: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await press(canvas, "6", ",", "0", ",");
    await expect(canvas.getByRole("status", { name: "raw" })).toHaveTextContent("6,0");
    await press(canvas, "8", "9");
    await expect(canvas.getByRole("status", { name: "raw" })).toHaveTextContent("6,08");
    await expect(args.onChange).toHaveBeenLastCalledWith("6,08");
    // The ignored keys did not report a change.
    await expect(args.onChange).toHaveBeenCalledTimes(4);
  },
};

/** A leading decimal becomes "0,"; a leading zero is replaced by the next digit. */
export const LeadingZero: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const raw = canvas.getByRole("status", { name: "raw" });
    await press(canvas, ",", "5");
    await expect(raw).toHaveTextContent("0,5");
    await expect(canvas.getByRole("status", { name: "cents" })).toHaveTextContent("50");
    await press(canvas, "⌫", "⌫", "⌫");
    await expect(raw).toHaveTextContent(/^$/);
    await press(canvas, "0", "0", "7");
    await expect(raw).toHaveTextContent(/^7$/);
  },
};

/** Backspace removes the last character; on an empty value it does nothing. */
export const Backspace: Story = {
  args: { initial: "6,08" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const raw = canvas.getByRole("status", { name: "raw" });
    await press(canvas, "⌫");
    await expect(raw).toHaveTextContent("6,0");
    await press(canvas, "⌫", "⌫", "⌫");
    await expect(raw).toHaveTextContent(/^$/);
    await press(canvas, "⌫");
    await expect(args.onChange).toHaveBeenCalledTimes(4);
  },
};

/** The whole part stops at seven digits (9.999.999,99 €), far below the safe-integer limit. */
export const MaxLength: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await press(canvas, ...Array.from({ length: 9 }, () => "1"));
    await expect(canvas.getByRole("status", { name: "raw" })).toHaveTextContent(/^1111111$/);
    await press(canvas, ",", "9", "9");
    await expect(canvas.getByRole("status", { name: "cents" })).toHaveTextContent("111111199");
  },
};

/** Keys sit on a solid edge and show the focus ring from the keyboard. */
export const KeysPressAndFocus: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const one = canvas.getByRole("button", { name: "1" });
    await expectEdge(one, 3);
    await userEvent.tab();
    await expect(one).toHaveFocus();
    await expectFocusRing(one);
    await userEvent.keyboard("{Enter}");
    await expect(canvas.getByRole("status", { name: "raw" })).toHaveTextContent("1");
  },
};

export const Day: Story = {
  globals: { theme: "day" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await press(canvas, "4", ",", "7", "5");
    await expect(canvas.getByRole("status", { name: "cents" })).toHaveTextContent("475");
  },
};
