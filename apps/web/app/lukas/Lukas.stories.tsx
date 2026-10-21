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
    const lukas = canvas.getByRole("img", { name: "Lukas, contento" });
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

/** Worried: frame 1 (no wave) with a small side-to-side shiver and a sweat drop. */
export const Worried: Story = {
  args: { mood: "worried" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const lukas = canvas.getByRole("img", { name: "Lukas, preocupado" });
    const sheet = sprite(lukas);
    await expect(getComputedStyle(sheet).backgroundPosition).toBe("0% 0%");
    await expect(sheet.getAnimations()).toHaveLength(0);
    await expect(lukas.querySelector(".lk-lukas-sweat")).not.toBeNull();
    await expect(animationNames(lukas)).toEqual(["lk-lukas-shiver"]);
  },
};

/** Celebrating: a hop with squash and stretch, and sparkles in the celebration colors. */
export const Celebrating: Story = {
  args: { mood: "celebrating" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const lukas = canvas.getByRole("img", { name: "Lukas, celebrando" });
    await expect(getComputedStyle(sprite(lukas)).backgroundPosition).toBe("0% 0%");
    const sparkles = lukas.querySelectorAll(".lk-lukas-sparkle");
    await expect(sparkles.length).toBeGreaterThanOrEqual(3);
    await expect(animationNames(lukas)).toContain("lk-lukas-hop");
    await expect(animationNames(lukas)).toContain("lk-lukas-twinkle");
    await expect(lukas.querySelector(".lk-lukas-sweat")).toBeNull();
  },
};

/** Reduced motion: still frames only (frame 1 happy and worried, frame 5 celebrating). */
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
    await expect(getComputedStyle(sprite(happy as HTMLElement)).backgroundPosition).toBe("0% 0%");
    await expect(getComputedStyle(sprite(worried as HTMLElement)).backgroundPosition).toBe("0% 0%");
    // Frame 5 of the 4×2 sheet: first column, second row.
    await expect(getComputedStyle(sprite(celebrating as HTMLElement)).backgroundPosition).toBe(
      "0% 100%",
    );
    // The mood still reads without motion.
    await expect((worried as HTMLElement).querySelector(".lk-lukas-sweat")).not.toBeNull();
    await expect(
      (celebrating as HTMLElement).querySelectorAll(".lk-lukas-sparkle").length,
    ).toBeGreaterThan(0);
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
 * Final per-mood art drops in through `art` (or `LUKAS_ART`) without changing callers: here the
 * worried mood plays its own sheet and needs no CSS treatment.
 */
export const CustomArt: Story = {
  args: {
    mood: "worried",
    art: {
      sprite: { ...LUKAS_ART.happy.sprite, loopMs: 2400 },
      play: true,
      frame: 0,
      stillFrame: 7,
      treatment: "none",
    },
  },
  play: async ({ canvasElement }) => {
    const lukas = within(canvasElement).getByRole("img", { name: "Lukas, preocupado" });
    await expect(lukas.querySelector(".lk-lukas-sweat")).toBeNull();
    await expect(animationNames(lukas)).toEqual(["lk-sprite-x", "lk-sprite-y"]);
    const [, y] = sprite(lukas).getAnimations();
    await expect(y?.effect?.getComputedTiming().duration).toBe(2400);
  },
};

export const DayEnglish: Story = {
  args: { mood: "celebrating" },
  globals: { theme: "day", locale: "en" },
  play: async ({ canvasElement }) => {
    await expect(
      within(canvasElement).getByRole("img", { name: "Lukas, celebrating" }),
    ).toBeVisible();
  },
};
