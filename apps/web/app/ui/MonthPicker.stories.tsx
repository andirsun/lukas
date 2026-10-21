import type { Month } from "@lukas/core";
import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, userEvent, within } from "storybook/test";
import { expectEdge, expectFocusRing, expectTarget } from "../../.storybook/story-utils.ts";
import { MonthPicker } from "./MonthPicker.tsx";

function MonthPickerHarness({
  initial,
  max,
  onChange,
}: {
  initial: Month;
  max: Month;
  onChange?: (month: Month) => void;
}) {
  const [month, setMonth] = useState(initial);
  return (
    <MonthPicker
      month={month}
      max={max}
      onChange={(next) => {
        setMonth(next);
        onChange?.(next);
      }}
    />
  );
}

const meta = {
  title: "UI/MonthPicker",
  component: MonthPickerHarness,
  args: { initial: "2026-10", max: "2026-10", onChange: fn() },
} satisfies Meta<typeof MonthPickerHarness>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The current month: no year, "next" is disabled at `max`, "previous" steps back. */
export const CurrentMonth: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const group = canvas.getByRole("group", { name: "Mes" });
    await expect(within(group).getByText("Octubre")).toBeVisible();
    const previous = canvas.getByRole("button", { name: "Mes anterior" });
    const next = canvas.getByRole("button", { name: "Mes siguiente" });
    await expect(next).toBeDisabled();
    await expectTarget(previous);
    await expectTarget(next);
    await expectEdge(previous, 3);

    await userEvent.click(previous);
    await expect(args.onChange).toHaveBeenLastCalledWith("2026-09");
    await expect(canvas.getByText("Septiembre")).toBeVisible();
    await expect(next).toBeEnabled();
    await userEvent.click(next);
    await expect(args.onChange).toHaveBeenLastCalledWith("2026-10");
    await expect(next).toBeDisabled();
  },
};

/** Months of another year than `max` carry the year; stepping crosses year boundaries. */
export const AcrossYears: Story = {
  args: { initial: "2026-01" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Enero")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Mes anterior" }));
    await expect(args.onChange).toHaveBeenLastCalledWith("2025-12");
    await expect(canvas.getByText("Diciembre 2025")).toBeVisible();
  },
};

/** The month label is announced politely when it changes. */
export const Announced: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const label = canvas.getByText("Octubre");
    await expect(label).toHaveAttribute("aria-live", "polite");
    await userEvent.tab();
    const previous = canvas.getByRole("button", { name: "Mes anterior" });
    await expect(previous).toHaveFocus();
    await expectFocusRing(previous);
    await userEvent.keyboard("{Enter}");
    await expect(label).toHaveTextContent("Septiembre");
  },
};

export const DayEnglish: Story = {
  args: { initial: "2025-11" },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("group", { name: "Month" })).toBeVisible();
    await expect(canvas.getByText("November 2025")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Next month" }));
    await expect(canvas.getByText("December 2025")).toBeVisible();
  },
};
