import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, screen, spyOn, userEvent, waitFor, within } from "storybook/test";
import { useTranslations } from "use-intl";
import { fingerDrag } from "../../.storybook/story-utils.ts";
import { PressButton } from "./PressButton.tsx";
import { Sheet } from "./Sheet.tsx";

function SheetHarness({
  initiallyOpen = false,
  onClose,
}: {
  initiallyOpen?: boolean;
  onClose?: () => void;
}) {
  const t = useTranslations();
  const [open, setOpen] = useState(initiallyOpen);
  return (
    <>
      <PressButton onClick={() => setOpen(true)}>{t("transaction.add_expense")}</PressButton>
      <Sheet
        open={open}
        title={t("transaction.add_expense")}
        onClose={() => {
          setOpen(false);
          onClose?.();
        }}
      >
        <div className="lk-row-flex">
          <PressButton variant="secondary" className="flex-1">
            {t("common.cancel")}
          </PressButton>
          <PressButton className="flex-1">{t("common.save")}</PressButton>
        </div>
      </Sheet>
    </>
  );
}

/** Waits for the open sheet to finish sliding in, so the a11y run sees it in place. */
async function settled(name: string): Promise<HTMLElement> {
  const dialog = await screen.findByRole("dialog", { name });
  await waitFor(() => expect(new DOMMatrix(getComputedStyle(dialog).transform).m42).toBe(0));
  return dialog;
}

const meta = {
  title: "UI/Sheet",
  component: SheetHarness,
  args: { onClose: fn() },
} satisfies Meta<typeof SheetHarness>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Open: a modal dialog named by its title, with focus moved inside and trapped there. */
export const Open: Story = {
  args: { initiallyOpen: true },
  play: async () => {
    const dialog = await settled("Agregar gasto");
    await expect(dialog).toHaveAttribute("aria-modal", "true");
    await expect(dialog).toHaveClass("lk-sheet");
    await expect(dialog.contains(document.activeElement)).toBe(true);
    await expect(document.body.style.overflow).toBe("hidden");

    // Tab cycles through the sheet's controls and never leaves it.
    const sheet = within(dialog);
    const close = sheet.getByRole("button", { name: "Cerrar" });
    const save = sheet.getByRole("button", { name: "Guardar" });
    save.focus();
    await userEvent.tab();
    await expect(close).toHaveFocus();
    await userEvent.tab({ shift: true });
    await expect(save).toHaveFocus();
  },
};

/** Escape closes it. */
export const EscapeCloses: Story = {
  args: { initiallyOpen: true },
  play: async ({ args }) => {
    await settled("Agregar gasto");
    await userEvent.keyboard("{Escape}");
    await expect(args.onClose).toHaveBeenCalledOnce();
    await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());
    await expect(document.body.style.overflow).toBe("");
  },
};

/** Opened from a button, closed with its close button: focus returns to the opener. */
export const OpenAndClose: Story = {
  play: async ({ canvasElement, args }) => {
    const opener = within(canvasElement).getByRole("button", { name: "Agregar gasto" });
    await expect(screen.queryByRole("dialog")).toBeNull();
    await userEvent.click(opener);
    const dialog = await screen.findByRole("dialog", { name: "Agregar gasto" });
    await userEvent.click(within(dialog).getByRole("button", { name: "Cerrar" }));
    await expect(args.onClose).toHaveBeenCalledOnce();
    await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());
    await waitFor(() => expect(opener).toHaveFocus());
  },
};

/** Tapping the dimmed backdrop closes the sheet. */
export const BackdropCloses: Story = {
  args: { initiallyOpen: true },
  play: async ({ args }) => {
    await screen.findByRole("dialog");
    const backdrop = document.querySelector("[data-sheet-backdrop]") as HTMLElement;
    await userEvent.click(backdrop);
    await expect(args.onClose).toHaveBeenCalledOnce();
  },
};

export const OpenDayEnglish: Story = {
  args: { initiallyOpen: true },
  globals: { theme: "day", locale: "en" },
  play: async () => {
    const dialog = await settled("Add expense");
    await expect(within(dialog).getByRole("button", { name: "Close" })).toBeVisible();
  },
};

/** Reduced motion: the sheet fades in place; it never slides. */
export const OpenReducedMotion: Story = {
  args: { initiallyOpen: true },
  parameters: { reducedMotion: true },
  play: async () => {
    const dialog = await screen.findByRole("dialog", { name: "Agregar gasto" });
    const offsets: number[] = [];
    await waitFor(() => {
      offsets.push(new DOMMatrix(getComputedStyle(dialog).transform).m42);
      expect(getComputedStyle(dialog).opacity).toBe("1");
    });
    await expect(offsets.every((y) => y === 0)).toBe(true);
  },
};

/** How far the sheet is dragged down from where it rests, in px. */
const dragOffset = () =>
  new DOMMatrix(
    getComputedStyle(document.querySelector("[data-sheet-drag]") as HTMLElement).transform,
  ).m42;

/**
 * Dragged down from anywhere (here the Guardar button): it follows the finger, ticks once past a
 * quarter of its height, and closes on release, through the same path as Cerrar. The button a drag
 * starts on is never pressed.
 */
export const DragDownFromAnywhereCloses: Story = {
  args: { initiallyOpen: true },
  play: async ({ args }) => {
    const vibrate = spyOn(navigator, "vibrate").mockImplementation(() => true);
    try {
      const dialog = await settled("Agregar gasto");
      const save = within(dialog).getByRole("button", { name: "Guardar" });
      const height = dialog.getBoundingClientRect().height;
      await fingerDrag(save, {
        dy: height * 0.5,
        steps: 12,
        stepMs: 20,
        hold: async () => {
          await expect(dragOffset()).toBeGreaterThan(height * 0.5 - 12);
        },
      });
      await waitFor(() => expect(args.onClose).toHaveBeenCalledOnce());
      await expect(vibrate).toHaveBeenCalledWith([10]);
    } finally {
      vibrate.mockRestore();
    }
  },
};

/** A short drag springs back; upward it resists (0.3× the finger). */
export const ShortDragSpringsBack: Story = {
  args: { initiallyOpen: true },
  play: async ({ args }) => {
    const dialog = await settled("Agregar gasto");
    await fingerDrag(dialog, {
      dy: -100,
      steps: 10,
      stepMs: 20,
      hold: async () => {
        await expect(dragOffset()).toBeGreaterThan(-35);
        await expect(dragOffset()).toBeLessThan(-20);
      },
    });
    await fingerDrag(dialog, { dy: 40, steps: 10, stepMs: 24 });
    await waitFor(() => expect(Math.abs(dragOffset())).toBeLessThan(1));
    await expect(args.onClose).not.toHaveBeenCalled();
  },
};

/** Reduced motion: no follow-the-finger, but a drag down still closes it on release. */
export const DragClosesReducedMotion: Story = {
  args: { initiallyOpen: true },
  parameters: { reducedMotion: true },
  play: async ({ args }) => {
    const dialog = await screen.findByRole("dialog", { name: "Agregar gasto" });
    const height = dialog.getBoundingClientRect().height;
    await fingerDrag(dialog, {
      dy: height * 0.5,
      steps: 12,
      hold: async () => {
        await expect(dragOffset()).toBe(0);
      },
    });
    await waitFor(() => expect(args.onClose).toHaveBeenCalledOnce());
  },
};
