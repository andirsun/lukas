import type { Meta, StoryObj } from "@storybook/react-vite";
import { type ReactNode, useEffect, useState } from "react";
import { expect, waitFor } from "storybook/test";
import { ENTRANCE_KEY } from "./entrance.ts";
import { TravelingLukas } from "./TravelingLukas.tsx";

/**
 * The landing's traveling Lukas on a small page with three spots (like the landing's hero, "how it
 * works" and closing): he rolls in once per session, stands on the spot in view in its mood, turns
 * edge-on between spots, and hops on hover or tap. On the landing the page mounts him only once it
 * has loaded and is idle, and never under reduced motion.
 */
/** Like the landing, he mounts once the page (and its spots) is on screen. */
function AfterThePage({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false);
  useEffect(() => setReady(true), []);
  return ready ? children : null;
}

const meta = {
  title: "Lukas/TravelingLukas",
  component: TravelingLukas,
  decorators: [
    (Story) => (
      <div style={{ position: "relative", minHeight: "260vh" }}>
        <div
          data-lukas-spot="hero"
          data-lukas-pose="wave"
          data-lukas-mood="happy"
          data-lukas-enter-from="right"
          style={{ width: 220, height: 220, marginInline: "auto" }}
        />
        <div style={{ height: "90vh" }} />
        <div
          data-lukas-spot="how"
          data-lukas-pose="carry"
          data-lukas-mood="worried"
          style={{ width: 120, height: 120, marginInlineStart: "auto" }}
        />
        <div style={{ height: "90vh" }} />
        <div
          data-lukas-spot="closing"
          data-lukas-pose="celebrate"
          data-lukas-mood="celebrating"
          style={{ width: 160, height: 160, marginInline: "auto" }}
        />
        <AfterThePage>
          <Story />
        </AfterThePage>
      </div>
    ),
  ],
  beforeEach: () => {
    window.scrollTo({ top: 0, behavior: "instant" });
    sessionStorage.removeItem(ENTRANCE_KEY);
    return () => {
      window.scrollTo({ top: 0, behavior: "instant" });
      document.documentElement.removeAttribute("data-lukas-live");
    };
  },
} satisfies Meta<typeof TravelingLukas>;

export default meta;
type Story = StoryObj<typeof meta>;

function layerOf(root: HTMLElement): HTMLElement {
  const layer = root.ownerDocument.querySelector<HTMLElement>("[data-lukas-traveler]");
  if (!layer) throw new Error("no traveling Lukas");
  return layer;
}

function activeSheet(layer: HTMLElement): string {
  const sprite = layer.querySelector(".lk-traveler-mood.is-active .lk-lukas-sprite");
  return sprite ? getComputedStyle(sprite).backgroundImage : "";
}

/** Scrolls so the spot's center sits where it takes over (40% down the viewport). */
function scrollToSpot(id: string) {
  const spot = document.querySelector<HTMLElement>(`[data-lukas-spot='${id}']`);
  const box = spot?.getBoundingClientRect();
  if (!box) return;
  const top = box.top + window.scrollY + box.height / 2 - window.innerHeight * 0.4 + 2;
  window.scrollTo({ top, behavior: "instant" });
}

/** First visit: he rolls in (tucked into his coin), unfolds and waves, then stands on the hero. */
export const Entrance: Story = {
  play: async ({ canvasElement }) => {
    const layer = layerOf(canvasElement);
    await expect(layer).toHaveAttribute("aria-hidden", "true");
    await expect(layer.dataset.entrance).toBe("playing");
    await expect(sessionStorage.getItem(ENTRANCE_KEY)).toBe("seen");
    await expect(document.documentElement.dataset.lukasLive).toBe("live");
    await waitFor(() => expect(layer.dataset.entrance).toBe("done"), { timeout: 6000 });
    await expect(layer.dataset.spot).toBe("hero");
    await expect(layer.dataset.mood).toBe("happy");
    await expect(activeSheet(layer)).toContain("/lukas/wave.webp");
    // Standing: the coin isn't clipped or turned any more, and the wave sheet plays.
    const body = layer.querySelector<HTMLElement>(".lk-traveler-body");
    await expect(body?.style.transform).toBe("");
    await expect(body?.style.clipPath).toBe("");
    const sprite = layer.querySelector(".lk-traveler-mood.is-active .lk-lukas-sprite");
    await expect(sprite?.classList.contains("is-playing")).toBe(true);
  },
};

/** He takes each spot's mood, and only his body takes the pointer: a tap makes him hop. */
export const SpotsAndHop: Story = {
  beforeEach: () => {
    sessionStorage.setItem(ENTRANCE_KEY, "seen");
  },
  play: async ({ canvasElement }) => {
    const layer = layerOf(canvasElement);
    await expect(layer.dataset.entrance).toBe("skipped");
    await expect(getComputedStyle(layer).pointerEvents).toBe("none");
    const hit = layer.querySelector<HTMLElement>(".lk-traveler-hit");
    await expect(hit && getComputedStyle(hit).pointerEvents).toBe("auto");

    hit?.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, pointerType: "touch" }));
    await waitFor(() => expect(layer.querySelector(".lk-traveler-hop.is-hopping")).not.toBeNull());
    await waitFor(() => expect(layer.querySelector(".lk-traveler-hop.is-hopping")).toBeNull(), {
      timeout: 3000,
    });

    scrollToSpot("how");
    await waitFor(() => expect(layer.dataset.mood).toBe("worried"));
    await expect(layer.dataset.spot).toBe("how");
    await waitFor(() => expect(activeSheet(layer)).toContain("/lukas/worried.webp"));

    window.scrollTo({ top: document.documentElement.scrollHeight, behavior: "instant" });
    await waitFor(() => expect(layer.dataset.mood).toBe("celebrating"));
    await waitFor(() => expect(activeSheet(layer)).toContain("/lukas/celebrate.webp"));
  },
};
