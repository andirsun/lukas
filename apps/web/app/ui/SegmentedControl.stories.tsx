import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, userEvent, within } from "storybook/test";
import { useTranslations } from "use-intl";
import { SegmentedControl } from "./SegmentedControl.tsx";

type View = "budgets" | "transactions";

function HomeViewSwitch({ onChange }: { onChange?: (view: View) => void }) {
  const t = useTranslations("home.view");
  const [view, setView] = useState<View>("budgets");
  return (
    <div className="max-w-[360px]">
      <SegmentedControl<View>
        label={t("label")}
        value={view}
        options={[
          { value: "budgets", label: t("budgets") },
          { value: "transactions", label: t("transactions") },
        ]}
        onChange={(next) => {
          setView(next);
          onChange?.(next);
        }}
      />
    </div>
  );
}

const meta = {
  title: "UI/SegmentedControl",
  component: HomeViewSwitch,
  args: { onChange: fn() },
} satisfies Meta<typeof HomeViewSwitch>;

export default meta;
type Story = StoryObj<typeof meta>;

/** ARIA tabs: click or arrow keys move the selection; only the selected tab is in the tab order. */
export const Default: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const list = canvas.getByRole("tablist", { name: "Vista" });
    await expect(list).toHaveClass("lk-seg");
    const budgets = canvas.getByRole("tab", { name: "Categorías" });
    const transactions = canvas.getByRole("tab", { name: "Movimientos" });
    await expect(budgets).toHaveAttribute("aria-selected", "true");
    await expect(budgets).toHaveAttribute("tabindex", "0");
    await expect(transactions).toHaveAttribute("aria-selected", "false");
    await expect(transactions).toHaveAttribute("tabindex", "-1");
    await expect(transactions.getBoundingClientRect().height).toBeGreaterThanOrEqual(44);

    await userEvent.click(transactions);
    await expect(args.onChange).toHaveBeenLastCalledWith("transactions");
    await expect(transactions).toHaveAttribute("aria-selected", "true");

    await userEvent.keyboard("{ArrowLeft}");
    await expect(budgets).toHaveAttribute("aria-selected", "true");
    await expect(budgets).toHaveFocus();

    await userEvent.keyboard("{ArrowRight}");
    await expect(transactions).toHaveAttribute("aria-selected", "true");
    await expect(transactions).toHaveFocus();

    // Arrows wrap around; Home and End jump to the ends.
    await userEvent.keyboard("{ArrowRight}");
    await expect(budgets).toHaveFocus();
    await userEvent.keyboard("{End}");
    await expect(transactions).toHaveAttribute("aria-selected", "true");
    await userEvent.keyboard("{Home}");
    await expect(budgets).toHaveAttribute("aria-selected", "true");
  },
};

export const DayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("tablist", { name: "View" })).toBeVisible();
    await userEvent.click(canvas.getByRole("tab", { name: "Transactions" }));
    await expect(canvas.getByRole("tab", { name: "Transactions" })).toHaveAttribute(
      "aria-selected",
      "true",
    );
  },
};
