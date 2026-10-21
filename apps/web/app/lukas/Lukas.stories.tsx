import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, waitFor, within } from "storybook/test";
import { LUKAS_ART, Lukas } from "./Lukas.tsx";

const meta = {
  title: "Lukas/Lukas",
  component: Lukas,
  args: { mood: "happy", size: 160 },
} satisfies Meta<typeof Lukas>;

export default meta;
type Story = StoryObj<typeof meta>;

function sprite(root: HTMLElement): HTMLElement {
  return root.querySelector(".lk-lukas-sprite") as HTMLElement;
}

function animationNames(element: Element): string[] {
  return element
    .getAnimations({ subtree: true })
    .map((a) => (a as CSSAnimation).animationName)
    .sort();
}

/** Resolves once the sprite sheet has actually loaded from `public/`. */
function loads(src: string): Promise<{ width: number; height: number }> {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve({ width: image.naturalWidth, height: image.naturalHeight });
    image.onerror = reject;
    image.src = src;
  });
}

/** Happy: the waving loop, 8 frames of a 4×2 sheet stepped over ~1.2s. */
export const Happy: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const lukas = canvas.getByRole("img", { name: "Lukitas, contento" });
    const box = lukas.getBoundingClientRect();
    await expect(box.width).toBe(160);
    await expect(box.height).toBe(160);

    const sheet = sprite(lukas);
    const style = getComputedStyle(sheet);
    await expect(style.backgroundImage).toContain("/lukas/wave.webp");
    await expect(style.backgroundSize).toBe("400% 200%");
    await expect(await loads("/lukas/wave.webp")).toEqual({ width: 2000, height: 1000 });

    // Columns step 4× per row (600ms) and rows 2× per loop (1.2s): 8 frames of 150ms in reading order.
    await expect(animationNames(lukas)).toEqual(["lk-sprite-x", "lk-sprite-y"]);
    const [x, y] = sheet.getAnimations() as CSSAnimation[];
    const timing = (a: Animation | undefined) => a?.effect?.getComputedTiming();
    await expect(timing(x)?.duration).toBe(600);
    await expect(timing(y)?.duration).toBe(1200);
    await expect(timing(x)?.iterations).toBe(Number.POSITIVE_INFINITY);
    await expect(getComputedStyle(sheet).animationTimingFunction).toBe("steps(4), steps(2)");

    // Frames really change over time.
    const seen = new Set<string>();
    await waitFor(
      () => {
        seen.add(getComputedStyle(sheet).backgroundPosition);
        expect(seen.size).toBeGreaterThanOrEqual(3);
      },
      { timeout: 2000, interval: 60 },
    );
  },
};

/** The stepping of a playing sheet: its loop, half of it per row, 4 columns and 2 rows. */
async function expectPlaying(lukas: HTMLElement, src: string, loopMs: number) {
  const sheet = sprite(lukas);
  await expect(getComputedStyle(sheet).backgroundImage).toContain(src);
  await expect(getComputedStyle(sheet).backgroundSize).toBe("400% 200%");
  await expect(await loads(src)).toEqual({ width: 2000, height: 1000 });
  await expect(animationNames(lukas)).toEqual(["lk-sprite-x", "lk-sprite-y"]);
  const [x, y] = sheet.getAnimations() as CSSAnimation[];
  await expect(x?.effect?.getComputedTiming().duration).toBe(loopMs / 2);
  await expect(y?.effect?.getComputedTiming().duration).toBe(loopMs);
  // Each mood has its own sheet now: no CSS stand-ins.
  await expect(lukas.querySelector(".lk-lukas-sweat")).toBeNull();
  await expect(lukas.querySelectorAll(".lk-lukas-sparkle")).toHaveLength(0);
}

/** Worried: his own sheet, wringing his hands with a sweat drop; a slower 2s loop. */
export const Worried: Story = {
  args: { mood: "worried" },
  play: async ({ canvasElement }) => {
    const lukas = within(canvasElement).getByRole("img", { name: "Lukitas, preocupado" });
    await expectPlaying(lukas, "/lukas/worried.webp", 2000);
  },
};

/** Celebrating: his own sheet, jumping with fists up among sparkles; a bouncier 1s loop. */
export const Celebrating: Story = {
  args: { mood: "celebrating" },
  play: async ({ canvasElement }) => {
    const lukas = within(canvasElement).getByRole("img", { name: "Lukitas, celebrando" });
    await expectPlaying(lukas, "/lukas/celebrate.webp", 1000);
  },
};

/** Every mood side by side, each playing its own sheet. */
export const Moods: Story = {
  render: (args) => (
    <div className="lk-row-flex">
      <Lukas {...args} mood="happy" />
      <Lukas {...args} mood="worried" />
      <Lukas {...args} mood="celebrating" />
    </div>
  ),
  args: { size: 140 },
  play: async ({ canvasElement }) => {
    const [happy, worried, celebrating] = within(canvasElement).getAllByRole(
      "img",
    ) as HTMLElement[];
    await expectPlaying(happy as HTMLElement, "/lukas/wave.webp", 1200);
    await expectPlaying(worried as HTMLElement, "/lukas/worried.webp", 2000);
    await expectPlaying(celebrating as HTMLElement, "/lukas/celebrate.webp", 1000);
  },
};

/**
 * Reduced motion: one still frame per sheet. Happy frame 0 (a soft smile), worried frame 3 (hands
 * clasped, a sweat drop), celebrating frame 4 (fists up among sparkles).
 */
export const ReducedMotion: Story = {
  parameters: { reducedMotion: true },
  render: (args) => (
    <div className="lk-row-flex">
      <Lukas {...args} mood="happy" />
      <Lukas {...args} mood="worried" />
      <Lukas {...args} mood="celebrating" />
    </div>
  ),
  args: { size: 120 },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const [happy, worried, celebrating] = canvas.getAllByRole("img") as HTMLElement[];
    for (const lukas of [happy, worried, celebrating] as HTMLElement[]) {
      await expect(lukas.getAnimations({ subtree: true })).toHaveLength(0);
    }
    const still = (lukas: HTMLElement | undefined) => {
      const style = getComputedStyle(sprite(lukas as HTMLElement));
      return [style.backgroundImage.match(/\/lukas\/\w+\.webp/)?.[0], style.backgroundPosition];
    };
    await expect(still(happy)).toEqual(["/lukas/wave.webp", "0% 0%"]);
    // Frame 3: last column, first row.
    await expect(still(worried)).toEqual(["/lukas/worried.webp", "100% 0%"]);
    // Frame 4: first column, second row.
    await expect(still(celebrating)).toEqual(["/lukas/celebrate.webp", "0% 100%"]);
  },
};

/** Decorative (next to a message that says the same): hidden from assistive technology. */
export const Decorative: Story = {
  args: { decorative: true, size: 96 },
  play: async ({ canvasElement }) => {
    const lukas = canvasElement.querySelector(".lk-lukas") as HTMLElement;
    await expect(lukas).toHaveAttribute("aria-hidden", "true");
    await expect(within(canvasElement).queryByRole("img")).toBeNull();
  },
};

/**
 * The `treatment` seam, for a future mood that has no sheet yet: a still frame of an existing sheet
 * plus a CSS treatment. `shiver` shakes him side to side with a sweat drop.
 */
export const TreatmentShiver: Story = {
  args: {
    mood: "worried",
    art: {
      sprite: LUKAS_ART.happy.sprite,
      play: false,
      frame: 0,
      stillFrame: 0,
      treatment: "shiver",
    },
  },
  play: async ({ canvasElement }) => {
    const lukas = within(canvasElement).getByRole("img", { name: "Lukitas, preocupado" });
    const sheet = sprite(lukas);
    await expect(getComputedStyle(sheet).backgroundPosition).toBe("0% 0%");
    await expect(sheet.getAnimations()).toHaveLength(0);
    await expect(lukas.querySelector(".lk-lukas-sweat")).not.toBeNull();
    await expect(animationNames(lukas)).toEqual(["lk-lukas-shiver"]);
    // Timed by the `--shiver` token (1600ms).
    const [shiver] = lukas.getAnimations({ subtree: true });
    await expect(shiver?.effect?.getComputedTiming().duration).toBe(1600);
  },
};

/** The `hop` treatment: a hop with squash and stretch among sparkles that twinkle in turn. */
export const TreatmentHop: Story = {
  args: {
    mood: "celebrating",
    art: { sprite: LUKAS_ART.happy.sprite, play: false, frame: 0, stillFrame: 4, treatment: "hop" },
  },
  play: async ({ canvasElement }) => {
    const lukas = within(canvasElement).getByRole("img", { name: "Lukitas, celebrando" });
    const sparkles = lukas.querySelectorAll(".lk-lukas-sparkle");
    await expect(sparkles.length).toBeGreaterThanOrEqual(3);
    await expect(animationNames(lukas)).toContain("lk-lukas-hop");
    await expect(animationNames(lukas)).toContain("lk-lukas-twinkle");
    // Each twinkle lasts `--celebrate` and starts a quarter of it after the previous one.
    const twinkles = [...sparkles].map((sparkle) => sparkle.getAnimations()[0]);
    await expect(twinkles.map((a) => a?.effect?.getComputedTiming().duration)).toEqual([
      1200, 1200, 1200, 1200,
    ]);
    await expect(
      twinkles.map((a) => Math.round(a?.effect?.getComputedTiming().delay ?? -1)),
    ).toEqual([0, 300, 600, 900]);
  },
};

export const DayEnglish: Story = {
  args: { mood: "celebrating" },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    await expect(
      within(canvasElement).getByRole("img", { name: "Lukitas, celebrating" }),
    ).toBeVisible();
  },
};
