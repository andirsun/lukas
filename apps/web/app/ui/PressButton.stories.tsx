import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { useTranslations } from "use-intl";
import { PressButton } from "./PressButton.tsx";

function Variants({ onClick, pressed = false }: { onClick?: () => void; pressed?: boolean }) {
  const t = useTranslations();
  const state = pressed ? "is-pressed" : undefined;
  return (
    <div className="lk-pad">
      <div className="lk-row-flex">
        <PressButton className={state} onClick={onClick}>
          {t("transaction.add_expense")}
        </PressButton>
        <PressButton className={state} variant="secondary">
          {t("common.cancel")}
        </PressButton>
        <PressButton className={state} variant="ghost">
          {t("common.not_now")}
        </PressButton>
      </div>
      <div className="lk-row-flex">
        <PressButton size="sm">{t("common.save")}</PressButton>
        <PressButton size="sm" variant="secondary">
          {t("common.cancel")}
        </PressButton>
        <PressButton size="sm" variant="ghost">
          {t("common.close")}
        </PressButton>
        <PressButton disabled>{t("common.save")}</PressButton>
      </div>
    </div>
  );
}

const meta = {
  title: "UI/PressButton",
  component: Variants,
  args: { onClick: fn() },
} satisfies Meta<typeof Variants>;

export default meta;
type Story = StoryObj<typeof meta>;

const PX = (value: string) => Number.parseFloat(value);

/** Primary, secondary and ghost in both sizes: labels from the catalog, 44px targets, solid edges. */
export const AllVariants: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const primary = canvas.getByRole("button", { name: "Agregar gasto" });
    await expect(primary).toHaveClass("lk-btn", "lk-btn-primary");
    await expect(primary).toHaveAttribute("type", "button");

    for (const button of canvas.getAllByRole("button")) {
      const box = button.getBoundingClientRect();
      await expect(box.height).toBeGreaterThanOrEqual(44);
      await expect(box.width).toBeGreaterThanOrEqual(44);
    }

    // Primary and secondary sit on a solid (unblurred) bottom edge.
    await expect(getComputedStyle(primary).boxShadow).toMatch(/ 0px 6px 0px 0px/);
    const secondary = canvas.getAllByRole("button", { name: "Cancelar" })[0] as HTMLElement;
    await expect(getComputedStyle(secondary).boxShadow).toMatch(/ 0px 3px 0px 0px/);

    await userEvent.click(primary);
    await expect(args.onClick).toHaveBeenCalledOnce();
    await expect(canvas.getAllByRole("button", { name: "Guardar" })[1]).toBeDisabled();
  },
};

/** The pressed state: each button sinks by its edge height and the edge collapses to 1px. */
export const Pressed: Story = {
  args: { pressed: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const primary = canvas.getByRole("button", { name: "Agregar gasto" });
    const secondary = canvas.getAllByRole("button", { name: "Cancelar" })[0] as HTMLElement;
    const ghost = canvas.getByRole("button", { name: "Ahora no" });
    await expect(new DOMMatrix(getComputedStyle(primary).transform).m42).toBe(5);
    await expect(getComputedStyle(primary).boxShadow).toMatch(/ 0px 1px 0px 0px$/);
    await expect(new DOMMatrix(getComputedStyle(secondary).transform).m42).toBe(3);
    await expect(getComputedStyle(secondary).boxShadow).toMatch(/ 0px 1px 0px 0px$/);
    await expect(new DOMMatrix(getComputedStyle(ghost).transform).m42).toBeGreaterThan(0);
  },
};

/** Keyboard focus shows the 3px ring in the theme's focus color. */
export const KeyboardFocus: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.tab();
    const primary = canvas.getByRole("button", { name: "Agregar gasto" });
    await expect(primary).toHaveFocus();
    const style = getComputedStyle(primary);
    await expect(style.outlineStyle).toBe("solid");
    await expect(PX(style.outlineWidth)).toBe(3);
    const focus = getComputedStyle(document.documentElement).getPropertyValue("--focus").trim();
    const probe = document.createElement("span");
    probe.style.color = focus;
    document.body.append(probe);
    await expect(style.outlineColor).toBe(getComputedStyle(probe).color);
    probe.remove();
  },
};

/** Day theme, English. */
export const DayEnglish: Story = {
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    await expect(document.documentElement.dataset.theme).toBe("day");
    await expect(within(canvasElement).getByRole("button", { name: "Add expense" })).toBeVisible();
  },
};

/**
 * Under `prefers-reduced-motion: reduce` the press still moves the button down, but instantly:
 * the stylesheet zeroes the transitions of every pressable.
 */
export const ReducedMotionCss: Story = {
  play: async () => {
    const rules = [...document.styleSheets].flatMap((sheet) => {
      try {
        return [...sheet.cssRules];
      } catch {
        return [];
      }
    });
    const reduced = rules
      .filter((rule): rule is CSSMediaRule => rule instanceof CSSMediaRule)
      .filter((rule) => rule.conditionText.includes("prefers-reduced-motion: reduce"))
      .flatMap((rule) => [...rule.cssRules])
      .filter((rule): rule is CSSStyleRule => rule instanceof CSSStyleRule);
    const zeroed = reduced
      .filter((rule) => rule.style.transitionDuration === "0s")
      .map((rule) => rule.selectorText)
      .join(", ");
    for (const selector of [
      ".lk-press",
      ".lk-btn",
      ".lk-key",
      ".lk-seg button",
      ".lk-badge",
      ".lk-toast-actions button",
      ".lk-bar > span",
    ]) {
      await expect(zeroed).toContain(selector);
    }
  },
};
