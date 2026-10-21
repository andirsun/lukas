import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, screen, userEvent, waitFor, within } from "storybook/test";
import { useTranslations } from "use-intl";
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
