import type { Meta, StoryObj } from "@storybook/react-vite";
import { useState } from "react";
import { expect, fn, spyOn, userEvent, waitFor, within } from "storybook/test";
import { fingerDrag, translateX } from "../../.storybook/story-utils.ts";
import { GESTURE } from "./motion-tokens.ts";
import { PagerTrack, usePager } from "./Pager.tsx";
import { SegmentedControl } from "./SegmentedControl.tsx";
import { SwipeRow } from "./SwipeRow.tsx";
import { TransactionRow } from "./TransactionRow.tsx";

type View = "transactions" | "budgets";
const VIEWS: View[] = ["transactions", "budgets"];

/**
 * Home's two lists as a pager: the surface (here the whole column, the summary card included)
 * takes sideways drags, the track follows the finger, the tabs' thumb follows the track.
 */
function Demo({ onChange }: { onChange?: (view: View) => void }) {
  const [view, setView] = useState<View>("transactions");
  const choose = (next: View) => {
    setView(next);
    onChange?.(next);
  };
  const pager = usePager({
    index: VIEWS.indexOf(view),
    count: 2,
    onIndexChange: (index) => choose(VIEWS[index] as View),
  });
  return (
    <div
      {...pager.surface}
      data-testid="surface"
      className="flex max-w-[390px] flex-col gap-(--space-3)"
    >
      <section className="lk-hero" data-testid="card">
        <h1 className="lk-hero-label m-0 text-[13px]">Te quedan este mes</h1>
        <p className="lk-hero-amount m-0">562,92 €</p>
      </section>
      <SegmentedControl<View>
        label="Vista"
        value={view}
        position={pager.position}
        options={[
          { value: "transactions", label: "Movimientos" },
          { value: "budgets", label: "Presupuestos" },
        ]}
        onChange={choose}
      />
      <PagerTrack pager={pager}>
        <section role="tabpanel" aria-label="Movimientos" className="lk-panel flex">
          <h2 className="lk-panel-title">Movimientos</h2>
          <SwipeRow onDelete={() => {}} right={{ kind: "edit", run: () => {} }}>
            <TransactionRow
              name="continente"
              categoryName="Supermercado"
              glyph="🛒"
              amount={-608}
              currency="EUR"
              status="paid"
              onOpen={() => {}}
            />
          </SwipeRow>
          <div className="h-[200px]" />
        </section>
        <section role="tabpanel" aria-label="Presupuestos" className="lk-panel flex">
          <h2 className="lk-panel-title">Presupuestos</h2>
          <p className="m-0">Supermercado · quedan 120 €</p>
        </section>
      </PagerTrack>
    </div>
  );
}

const meta = {
  title: "UI/Pager",
  component: Demo,
  args: { onChange: fn() },
} satisfies Meta<typeof Demo>;

export default meta;

/** Springs settle well within this, even on a busy machine running every story at once. */
const SETTLE = { timeout: 4000 };
type Story = StoryObj<typeof meta>;

const trackOf = (canvasElement: HTMLElement) =>
  canvasElement.querySelector<HTMLElement>("[data-pager-track]") as HTMLElement;
const thumbOf = (canvasElement: HTMLElement) =>
  canvasElement.querySelector<HTMLElement>(".lk-seg-thumb") as HTMLElement;

/**
 * The track follows the finger 1:1 (and the tab's thumb with it); let go past half the width it
 * springs to Presupuestos, with a light vibration.
 */
export const DragAndSnap: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const vibrate = spyOn(navigator, "vibrate").mockImplementation(() => true);
    try {
      const card = canvas.getByTestId("card");
      const track = trackOf(canvasElement);
      const width = track.getBoundingClientRect().width;
      await fingerDrag(card, {
        dx: -width * 0.6,
        steps: 20,
        stepMs: 20,
        hold: async () => {
          const offset = translateX(track);
          // 1:1 with the finger, less the 8 px slop at most.
          await expect(offset).toBeLessThan(-width * 0.6 + 12);
          await expect(offset).toBeGreaterThan(-width * 0.6 - 2);
          await expect(translateX(thumbOf(canvasElement))).toBeGreaterThan(20);
          await new Promise((resolve) => setTimeout(resolve, 200));
        },
      });
      await waitFor(() => expect(args.onChange).toHaveBeenCalledWith("budgets"), SETTLE);
      await waitFor(() =>
        expect(canvas.getByRole("tab", { name: "Presupuestos" })).toHaveAttribute(
          "aria-selected",
          "true",
        ),
      );
      await waitFor(
        () => expect(translateX(track)).toBeCloseTo(-(width + GESTURE.pagerGap), 0),
        SETTLE,
      );
      await expect(vibrate).toHaveBeenCalledWith([15]);
      // At rest the other page is out of reach: hidden, not just off screen.
      await waitFor(
        () => expect(canvas.queryByRole("tabpanel", { name: "Movimientos" })).toBeNull(),
        SETTLE,
      );
    } finally {
      vibrate.mockRestore();
    }
  },
};

/** A short, fast flick switches; a short, slow drag snaps back; past the last page it resists. */
export const Flick: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const card = canvas.getByTestId("card");
    const track = trackOf(canvasElement);
    await fingerDrag(card, { dx: -50, steps: 25, stepMs: 20 });
    await waitFor(() => expect(translateX(track)).toBeCloseTo(0, 0), SETTLE);
    await expect(args.onChange).not.toHaveBeenCalled();

    // Fast: 80 px (under a quarter of the width) in two quick moves.
    await fingerDrag(card, { dx: -80, steps: 2, stepMs: 1 });
    await waitFor(() => expect(args.onChange).toHaveBeenCalledWith("budgets"), SETTLE);

    // Past the last page: 0.3× the finger.
    const width = track.getBoundingClientRect().width;
    await waitFor(
      () => expect(translateX(track)).toBeCloseTo(-(width + GESTURE.pagerGap), 0),
      SETTLE,
    );
    await fingerDrag(card, {
      dx: -100,
      steps: 20,
      stepMs: 20,
      hold: async () => {
        const past = -translateX(track) - (width + GESTURE.pagerGap);
        await expect(past).toBeGreaterThan(20);
        await expect(past).toBeLessThan(40);
      },
    });
    await waitFor(
      () => expect(translateX(track)).toBeCloseTo(-(width + GESTURE.pagerGap), 0),
      SETTLE,
    );
  },
};

/** Mostly down is a scroll: the track never moves sideways, and the tab stays. */
export const AxisLock: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const track = trackOf(canvasElement);
    await fingerDrag(canvas.getByTestId("card"), {
      dx: -40,
      dy: -160,
      steps: 16,
      hold: async () => {
        await expect(translateX(track)).toBe(0);
      },
    });
    await expect(args.onChange).not.toHaveBeenCalled();
  },
};

/** A sideways drag that starts on a swipeable row is the row's: the pager stays put. */
export const RowsOwnTheirGestures: Story = {
  play: async ({ canvasElement, args }) => {
    const row = canvasElement.querySelector<HTMLElement>("[data-swipe-row]") as HTMLElement;
    const track = trackOf(canvasElement);
    await fingerDrag(row, {
      dx: -70,
      steps: 12,
      stepMs: 24,
      hold: async () => {
        await expect(translateX(track)).toBe(0);
      },
    });
    await expect(args.onChange).not.toHaveBeenCalled();
    await expect(
      await within(canvasElement).findByRole("button", { name: "Borrar" }),
    ).toBeVisible();
  },
};

/** A tap on the other tab slides there too. */
export const TapSlides: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const track = trackOf(canvasElement);
    const width = track.getBoundingClientRect().width;
    await userEvent.click(canvas.getByRole("tab", { name: "Presupuestos" }));
    await expect(args.onChange).toHaveBeenCalledWith("budgets");
    // Mid-slide, then settled.
    await waitFor(
      () => expect(translateX(track)).toBeCloseTo(-(width + GESTURE.pagerGap), 0),
      SETTLE,
    );
  },
};

/** Reduced motion: no follow-the-finger; on release it switches with a short cross-fade. */
export const ReducedMotion: Story = {
  parameters: { reducedMotion: true },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const track = trackOf(canvasElement);
    const width = track.getBoundingClientRect().width;
    await fingerDrag(canvas.getByTestId("card"), {
      dx: -width * 0.6,
      steps: 12,
      hold: async () => {
        await expect(translateX(track)).toBe(0);
      },
    });
    await waitFor(() => expect(args.onChange).toHaveBeenCalledWith("budgets"), SETTLE);
    await waitFor(
      () => expect(translateX(track)).toBeCloseTo(-(width + GESTURE.pagerGap), 0),
      SETTLE,
    );
    const page = canvas.getByRole("tabpanel", { name: "Presupuestos" });
    // The short cross-fade, then fully there.
    await waitFor(
      () => expect(getComputedStyle(page.parentElement as HTMLElement).opacity).toBe("1"),
      SETTLE,
    );
  },
};

/** A tap on the card while the track slides to a tab's page still lets it settle there. */
export const TapMidSpringSettles: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const track = trackOf(canvasElement);
    const width = track.getBoundingClientRect().width;
    await userEvent.click(canvas.getByRole("tab", { name: "Presupuestos" }));
    await fingerDrag(canvas.getByTestId("card"), { steps: 0 });
    await waitFor(
      () => expect(translateX(track)).toBeCloseTo(-(width + GESTURE.pagerGap), 0),
      SETTLE,
    );
  },
};
