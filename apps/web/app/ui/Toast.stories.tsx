import type { Meta, StoryObj } from "@storybook/react-vite";
import { useEffect, useRef, useState } from "react";
import { expect, fireEvent, fn, screen, userEvent, waitFor, within } from "storybook/test";
import { useTranslations } from "use-intl";
import { Money } from "./Money.tsx";
import { PressButton } from "./PressButton.tsx";
import { Sheet } from "./Sheet.tsx";
import { ToastProvider, useToast } from "./Toast.tsx";

function SavedToastDemo({ onUndo, auto = false }: { onUndo?: () => void; auto?: boolean }) {
  const t = useTranslations();
  const toast = useToast();
  const showSaved = () =>
    toast.show({
      message: (
        <>
          Supermercado · <Money cents={-608} currency="EUR" />
        </>
      ),
      actions: [{ label: t("common.undo"), onClick: () => onUndo?.() }],
    });
  // Shows once on mount for the static stories.
  useEffect(() => {
    if (auto) showSaved();
  }, []);
  return (
    <PressButton variant="secondary" onClick={showSaved}>
      {t("common.save")}
    </PressButton>
  );
}

/** Waits for the toast in `region` to finish entering, so the a11y run sees its real colors. */
async function entered(region: HTMLElement): Promise<HTMLElement> {
  let toast: HTMLElement | null = null;
  await waitFor(() => {
    toast = region.querySelector<HTMLElement>(".lk-toast");
    expect(toast && getComputedStyle(toast).opacity).toBe("1");
  });
  return toast as unknown as HTMLElement;
}

const meta = {
  title: "UI/Toast",
  component: SavedToastDemo,
  args: { onUndo: fn() },
  decorators: [
    (Story, { parameters }) => (
      <ToastProvider dismissAfterMs={parameters.toastDismissMs}>
        <Story />
      </ToastProvider>
    ),
  ],
} satisfies Meta<typeof SavedToastDemo>;

export default meta;
type Story = StoryObj<typeof meta>;

/** "Supermercado · −6,08 €" with Deshacer: the action runs and the toast leaves. */
export const WithUndo: Story = {
  play: async ({ canvasElement, args }) => {
    await userEvent.click(within(canvasElement).getByRole("button", { name: "Guardar" }));
    const status = await screen.findByRole("status");
    await waitFor(() => expect(status).toHaveTextContent("Supermercado · −6,08 €"));
    const undo = within(status).getByRole("button", { name: "Deshacer" });
    await expect(undo.getBoundingClientRect().height).toBeGreaterThanOrEqual(44);
    await userEvent.click(undo);
    await expect(args.onUndo).toHaveBeenCalledOnce();
    await waitFor(() => expect(status).toBeEmptyDOMElement());
  },
};

/** A newer toast replaces the current one instead of stacking. */
export const ReplacesPrevious: Story = {
  play: async ({ canvasElement }) => {
    const save = within(canvasElement).getByRole("button", { name: "Guardar" });
    await userEvent.click(save);
    await userEvent.click(save);
    const status = await screen.findByRole("status");
    await waitFor(() =>
      expect(within(status).getAllByRole("button", { name: "Deshacer" })).toHaveLength(1),
    );
    await entered(status);
  },
};

function ErrorToastDemo({ onRetry }: { onRetry?: () => void }) {
  const t = useTranslations();
  const toast = useToast();
  // Shows once on mount.
  useEffect(() => {
    toast.show({
      tone: "error",
      message: t("errors.generic"),
      actions: [{ label: t("common.retry"), onClick: () => onRetry?.() }],
    });
  }, []);
  return null;
}

/** Errors are announced assertively (`role="alert"`) and marked with the `over` color. */
export const ErrorTone: Story = {
  render: (args) => <ErrorToastDemo onRetry={args.onUndo} />,
  play: async ({ args }) => {
    const alert = await screen.findByRole("alert");
    await expect(await entered(alert)).toHaveClass("border-over");
    await expect(alert).toHaveTextContent("Algo salió mal");
    await userEvent.click(within(alert).getByRole("button", { name: "Reintentar" }));
    await expect(args.onUndo).toHaveBeenCalledOnce();
  },
};

export const DayEnglish: Story = {
  args: { auto: true },
  globals: { theme: "day", locale: "en" },
  play: async () => {
    const status = await screen.findByRole("status");
    await entered(status);
    await expect(status).toHaveTextContent("Supermercado · −€6.08");
    await expect(within(status).getByRole("button", { name: "Undo" })).toBeVisible();
  },
};

/** Numbered toasts, so a replacement is distinguishable from the toast it replaced. */
function CountingDemo() {
  const toast = useToast();
  const count = useRef(0);
  return (
    <PressButton
      variant="secondary"
      onClick={() => {
        count.current += 1;
        toast.show({ message: `Toast ${count.current}`, actions: [{ label: "OK", onClick() {} }] });
      }}
    >
      Show
    </PressButton>
  );
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/** Leaves on its own once the time is up (shortened here; 5 seconds by default). */
export const AutoDismiss: Story = {
  parameters: { toastDismissMs: 400 },
  render: () => <CountingDemo />,
  play: async ({ canvasElement }) => {
    await userEvent.click(within(canvasElement).getByRole("button", { name: "Show" }));
    const status = await screen.findByRole("status");
    await waitFor(() => expect(status).toHaveTextContent("Toast 1"));
    await waitFor(() => expect(status).toBeEmptyDOMElement(), { timeout: 2000 });
  },
};

/** Hovering keeps it; leaving restarts the countdown. */
export const PausesWhileHovered: Story = {
  parameters: { toastDismissMs: 400 },
  render: () => <CountingDemo />,
  play: async ({ canvasElement }) => {
    await userEvent.click(within(canvasElement).getByRole("button", { name: "Show" }));
    const status = await screen.findByRole("status");
    const toast = await waitFor(() => status.querySelector<HTMLElement>(".lk-toast") ?? undefined);
    if (!toast) throw new Error("toast not shown");
    await userEvent.hover(toast);
    await sleep(900);
    await expect(status).toHaveTextContent("Toast 1");
    await userEvent.unhover(toast);
    await waitFor(() => expect(status).toBeEmptyDOMElement(), { timeout: 2000 });
  },
};

/** Keyboard focus on an action keeps it too, until focus leaves. */
export const PausesWhileFocused: Story = {
  parameters: { toastDismissMs: 400 },
  render: () => <CountingDemo />,
  play: async ({ canvasElement }) => {
    const show = within(canvasElement).getByRole("button", { name: "Show" });
    await userEvent.click(show);
    const status = await screen.findByRole("status");
    const action = await within(status).findByRole("button", { name: "OK" });
    action.focus();
    await sleep(900);
    await expect(status).toHaveTextContent("Toast 1");
    show.focus();
    await waitFor(() => expect(status).toBeEmptyDOMElement(), { timeout: 2000 });
  },
};

/**
 * A toast replaced while hovered never gets its pointer-leave; the new one must still count down
 * instead of inheriting the pause.
 */
export const ReplacedWhileHovered: Story = {
  parameters: { toastDismissMs: 400 },
  render: () => <CountingDemo />,
  play: async ({ canvasElement }) => {
    const show = within(canvasElement).getByRole("button", { name: "Show" });
    await userEvent.click(show);
    const status = await screen.findByRole("status");
    const first = await waitFor(() => status.querySelector<HTMLElement>(".lk-toast") ?? undefined);
    if (!first) throw new Error("toast not shown");
    await userEvent.hover(first);
    // A plain click: no pointer movement, so the hovered toast is removed without a leave.
    fireEvent.click(show);
    await waitFor(() => expect(status).toHaveTextContent("Toast 2"));
    await waitFor(() => expect(status).toBeEmptyDOMElement(), { timeout: 2000 });
  },
};

function FollowUpDemo({ onUndo }: { onUndo?: () => void }) {
  const t = useTranslations();
  const toast = useToast();
  return (
    <PressButton
      variant="secondary"
      onClick={() =>
        toast.show({
          message: "Supermercado · −6,08 €",
          actions: [
            {
              label: t("common.undo"),
              onClick: () => {
                onUndo?.();
                toast.show({ message: "Supermercado restaurado" });
              },
            },
          ],
        })
      }
    >
      {t("common.save")}
    </PressButton>
  );
}

/** An action that shows another toast (an "undone" confirmation, a retry that fails again). */
export const ActionShowsFollowUp: Story = {
  render: (args) => <FollowUpDemo onUndo={args.onUndo} />,
  play: async ({ canvasElement, args }) => {
    await userEvent.click(within(canvasElement).getByRole("button", { name: "Guardar" }));
    const status = await screen.findByRole("status");
    await userEvent.click(await within(status).findByRole("button", { name: "Deshacer" }));
    await expect(args.onUndo).toHaveBeenCalledOnce();
    await waitFor(() => expect(status).toHaveTextContent("Supermercado restaurado"));
    await entered(status);
  },
};

/** Reduced motion: the toast fades in place, it never rises. */
export const ReducedMotion: Story = {
  parameters: { reducedMotion: true },
  play: async ({ canvasElement }) => {
    await userEvent.click(within(canvasElement).getByRole("button", { name: "Guardar" }));
    const status = await screen.findByRole("status");
    const toast = await waitFor(() => status.querySelector<HTMLElement>(".lk-toast") ?? undefined);
    if (!toast) throw new Error("toast not shown");
    const offsets: number[] = [];
    await waitFor(() => {
      offsets.push(new DOMMatrix(getComputedStyle(toast).transform).m42);
      expect(getComputedStyle(toast).opacity).toBe("1");
    });
    await expect(offsets.every((y) => y === 0)).toBe(true);
  },
};

function SheetWithFailingSave() {
  const toast = useToast();
  const [open, setOpen] = useState(true);
  return (
    <Sheet open={open} onClose={() => setOpen(false)} title="Nuevo gasto">
      <PressButton
        onClick={() => toast.show({ tone: "error", message: "Sin conexión. Inténtalo de nuevo." })}
      >
        Guardar
      </PressButton>
    </Sheet>
  );
}

/**
 * An error while a modal sheet is open shows inside the dialog: announced as an alert (the
 * rest of the page is hidden from assistive technology) and reachable with Tab in its focus trap.
 * When the sheet closes, the toast moves back to the page.
 */
export const ErrorInsideSheet: Story = {
  render: () => <SheetWithFailingSave />,
  play: async () => {
    const dialog = await screen.findByRole("dialog", { name: "Nuevo gasto" });
    await userEvent.click(within(dialog).getByRole("button", { name: "Guardar" }));
    const alert = await within(dialog).findByRole("alert");
    await expect(alert).toHaveTextContent("Sin conexión. Inténtalo de nuevo.");
    await userEvent.keyboard("{Escape}");
    await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull(), { timeout: 4000 });
    await expect(screen.getByRole("alert")).toHaveTextContent("Sin conexión. Inténtalo de nuevo.");
  },
};
