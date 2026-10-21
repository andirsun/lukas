import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, waitFor } from "storybook/test";
import { Lukas3D } from "./Lukas3D.tsx";

/**
 * The 3D Lukas on his own (no Lukas spots on the page): he fills his box and takes the pose of
 * `mood`. Move the pointer around to see his eyes and body follow; hover for a jump, click for a
 * spin. On the landing page he travels between the sections' spots instead.
 */
const meta = {
  title: "Experimental/Lukas 3D",
  component: Lukas3D,
  args: { mood: "happy" },
  decorators: [
    (Story) => (
      <div style={{ width: 320, height: 320 }}>
        <Story />
      </div>
    ),
  ],
} satisfies Meta<typeof Lukas3D>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The layer is decorative and fills its box; the WebGL canvas comes up and marks him live. */
async function expectLive(root: HTMLElement, pose: string) {
  const layer = root.querySelector<HTMLElement>("[data-lukas3d-layer]");
  await expect(layer).not.toBeNull();
  await expect(layer?.getAttribute("aria-hidden")).toBe("true");
  await expect(layer?.dataset.pose).toBe(pose);
  await waitFor(
    () => {
      const canvas = layer?.querySelector("canvas");
      expect(canvas?.width).toBeGreaterThan(0);
      expect(document.documentElement.dataset.lukas3d).toBe("live");
    },
    { timeout: 10_000 },
  );
  const box = layer?.getBoundingClientRect();
  await expect(box?.width).toBe(320);
  await expect(box?.height).toBe(320);
  // Only his body takes the pointer (for the jump and the spin), never the rest of the box.
  await expect(layer && getComputedStyle(layer).pointerEvents).toBe("none");
  const hit = layer?.querySelector(".lk-lukas3d-hit");
  await expect(hit && getComputedStyle(hit).pointerEvents).toBe("auto");
}

/** Happy: waving, like the hero. */
export const Happy: Story = {
  play: async ({ canvasElement }) => expectLive(canvasElement, "wave"),
};

/** Celebrating: arms up, happy closed eyes, hopping among sparkles. */
export const Celebrating: Story = {
  args: { mood: "celebrating" },
  play: async ({ canvasElement }) => expectLive(canvasElement, "celebrate"),
};

/** Worried: raised inner brows, a small open mouth, hands in front. */
export const Worried: Story = {
  args: { mood: "worried" },
  play: async ({ canvasElement }) => expectLive(canvasElement, "worried"),
};

/** In the day theme (the canvas is transparent: the page shows through). */
export const Day: Story = {
  globals: { theme: "day" },
  play: async ({ canvasElement }) => expectLive(canvasElement, "wave"),
};
