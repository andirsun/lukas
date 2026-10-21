import type { Meta, StoryObj } from "@storybook/react-vite";
import { useEffect } from "react";
import { expect, fn, screen, userEvent, waitFor, within } from "storybook/test";
import { useTranslations } from "use-intl";
import { Money } from "./Money.tsx";
import { PressButton } from "./PressButton.tsx";
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
    (Story) => (
      <ToastProvider>
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
