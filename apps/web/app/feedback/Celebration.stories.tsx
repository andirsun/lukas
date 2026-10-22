import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { resolveColor } from "../../.storybook/story-utils.ts";
import { PressButton } from "../ui/PressButton.tsx";
import { Celebration } from "./Celebration.tsx";
import { type FeedbackEvent, feedback } from "./feedback.ts";

function CelebrationDemo({ event, spot = true }: { event: FeedbackEvent; spot?: boolean }) {
  return (
    <>
      <PressButton variant="primary" onClick={() => feedback(event)}>
        {event}
      </PressButton>
      {/* A landing spot, as the bottom bar's ＋ is in the app. */}
      {spot && (
        <span
          data-testid="spot"
          data-celebration-anchor="64"
          className="fixed bottom-6 left-1/2 block size-[58px] -translate-x-1/2"
        />
      )}
      <Celebration />
    </>
  );
}

const meta = {
  title: "Feedback/Celebration",
  component: CelebrationDemo,
  args: { event: "paid" },
} satisfies Meta<typeof CelebrationDemo>;

export default meta;
type Story = StoryObj<typeof meta>;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Lukitas lands on the spot (the ＋ in the app): his box starts at its top and stays in its column,
 * never above it, where the list's text would be.
 */
export const LandsOnTheSpot: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "paid" }));
    const overlay = await canvas.findByTestId("celebration");
    const lukas = overlay.querySelector<HTMLElement>(".lk-celebration-lukas") as HTMLElement;
    const spot = canvas.getByTestId("spot").getBoundingClientRect();
    await sleep(500);
    const box = lukas.getBoundingClientRect();
    await expect(box.top).toBeGreaterThanOrEqual(spot.top - 4);
    await expect(box.left).toBeGreaterThanOrEqual(spot.left - 8);
    await expect(box.right).toBeLessThanOrEqual(spot.right + 8);
  },
};

/** No spot on the screen at all: he waits a moment for one, then shows at the top. */
export const NoSpot: Story = {
  args: { spot: false },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "paid" }));
    const overlay = await canvas.findByTestId("celebration", {}, { timeout: 3000 });
    const lukas = overlay.querySelector<HTMLElement>(".lk-celebration-lukas") as HTMLElement;
    await waitFor(() => expect(lukas.getBoundingClientRect().top).toBeLessThan(40), {
      timeout: 3000,
    });
  },
};

/** `paid` fires the confetti and a celebrating Lukitas, decorative and untouchable, then leaves. */
export const Paid: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByTestId("celebration")).toBeNull();
    await userEvent.click(canvas.getByRole("button", { name: "paid" }));

    const overlay = await canvas.findByTestId("celebration");
    // Decorative: out of the accessibility tree, and it never takes a tap.
    await expect(overlay).toHaveAttribute("aria-hidden", "true");
    await expect(getComputedStyle(overlay).pointerEvents).toBe("none");
    await expect(canvas.queryByRole("img")).toBeNull();

    // The confetti uses only the brand tokens.
    const pieces = overlay.querySelectorAll<HTMLElement>(".lk-confetti");
    await expect(pieces.length).toBeGreaterThanOrEqual(20);
    const colors = new Set([...pieces].map((p) => getComputedStyle(p).backgroundColor));
    await expect(colors).toEqual(
      new Set([
        resolveColor("var(--gold)"),
        resolveColor("var(--candy)"),
        resolveColor("var(--good)"),
      ]),
    );

    // Lukitas celebrates, on his own sheet, and both animations run.
    const sheet = overlay.querySelector(".lk-lukas.is-celebrating .lk-lukas-sprite");
    await expect(sheet).not.toBeNull();
    await expect(getComputedStyle(sheet as Element).backgroundImage).toContain("celebrate.webp");
    const running = overlay
      .getAnimations({ subtree: true })
      .map((animation) => (animation as CSSAnimation).animationName);
    await expect(running).toContain("lk-confetti-burst");
    await expect(running).toContain("lk-celebration-pop");

    await waitFor(() => expect(canvas.queryByTestId("celebration")).toBeNull(), { timeout: 3000 });
  },
};

/** Near the limit is not a party: sound and vibration only. */
export const NearLimit: Story = {
  args: { event: "nearLimit" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "nearLimit" }));
    await sleep(150);
    await expect(canvas.queryByTestId("celebration")).toBeNull();
  },
};

/** Under reduced motion there is no confetti: Lukitas shows as a still frame and only fades. */
export const ReducedMotion: Story = {
  parameters: { reducedMotion: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "paid" }));

    const overlay = await canvas.findByTestId("celebration");
    await expect(overlay).toHaveClass("is-reduced");
    await expect(overlay).toHaveAttribute("aria-hidden", "true");
    await expect(overlay.querySelectorAll(".lk-confetti")).toHaveLength(0);

    // His still celebrating frame (frame 4 of the 4x2 sheet), not the playing loop.
    const sheet = overlay.querySelector(".lk-lukas.is-celebrating .lk-lukas-sprite") as HTMLElement;
    await expect(sheet).not.toBeNull();
    await expect(sheet).not.toHaveClass("is-playing");
    await expect(sheet.style.backgroundPosition).toBe("0% 100%");

    // Only a fade runs: no pop and no confetti burst.
    const running = overlay
      .getAnimations({ subtree: true })
      .map((animation) => (animation as CSSAnimation).animationName);
    await expect(running).toEqual(["lk-celebration-fade"]);

    await waitFor(() => expect(canvas.queryByTestId("celebration")).toBeNull(), { timeout: 3000 });
  },
};

/** The same celebration by day, so the a11y checks cover both themes. */
export const DayExpenseSaved: Story = {
  args: { event: "expenseSaved" },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "expenseSaved" }));
    const overlay = await canvas.findByTestId("celebration");
    await expect(overlay.querySelectorAll(".lk-confetti").length).toBeGreaterThanOrEqual(20);
    await expect(
      getComputedStyle(overlay.querySelector(".lk-confetti.is-gold") as Element).backgroundColor,
    ).toBe(resolveColor("var(--gold)"));
  },
};

/** At night, left on screen when the story ends, so the a11y checks run over the live overlay. */
export const NightIncomeSaved: Story = {
  args: { event: "incomeSaved" },
  globals: { theme: "night", locale: "es" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "incomeSaved" }));
    await expect(await canvas.findByTestId("celebration")).toBeVisible();
  },
};
