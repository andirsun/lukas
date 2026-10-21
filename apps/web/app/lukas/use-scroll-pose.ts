import { useEffect, useRef, useState } from "react";

/** What Lukas does in a section of the landing page. */
export type LukasPose = "wave" | "point" | "carry" | "celebrate";

const POSES: readonly LukasPose[] = ["wave", "point", "carry", "celebrate"];

/** A stretch of the page: from `start` (page progress, 0 to 1) to the next section's start. */
export interface ScrollSection {
  id: string;
  start: number;
  pose: LukasPose;
}

function clamp01(value: number): number {
  return Math.min(1, Math.max(0, Number.isFinite(value) ? value : 0));
}

function byStart(sections: readonly ScrollSection[]): ScrollSection[] {
  return [...sections].sort((a, b) => a.start - b.start);
}

/** The index (in start order) of the section the page progress is in; -1 without sections. */
export function sectionIndexAt(progress: number, sections: readonly ScrollSection[]): number {
  const p = clamp01(progress);
  const sorted = byStart(sections);
  let index = sorted.length > 0 ? 0 : -1;
  sorted.forEach((section, i) => {
    if (section.start <= p) index = i;
  });
  return index;
}

/**
 * Lukas' pose for a page progress (0 at the top, 1 at the bottom; clamped): the pose of the
 * section the progress is in, and `y`, how far through that section the page has scrolled (0 at its
 * start, 1 at the next section's start, or at the end of the page for the last one). `y` is Lukas'
 * vertical travel: near 1 he leaves his spot for the next section's.
 */
export function scrollPose(
  progress: number,
  sections: readonly ScrollSection[],
): { pose: LukasPose; y: number } {
  const p = clamp01(progress);
  const sorted = byStart(sections);
  const index = sectionIndexAt(p, sorted);
  const current = sorted[index];
  if (!current) return { pose: "wave", y: 0 };
  const end = sorted[index + 1]?.start ?? 1;
  const length = end - current.start;
  const y = length > 0 ? clamp01((p - current.start) / length) : 1;
  return { pose: current.pose, y };
}

/** A place on the page where Lukas stands for a section (`data-lukas-spot`, `data-lukas-pose`). */
export interface LukasSpot extends ScrollSection {
  element: HTMLElement;
}

export interface ScrollPoseState {
  pose: LukasPose;
  /** Index of the current spot in page order. */
  index: number;
  spots: LukasSpot[];
}

/** Where on the screen a spot takes over: when its center crosses this fraction of the viewport. */
const TAKEOVER_LINE = 0.4;

function readSpots(): LukasSpot[] {
  const elements = [...document.querySelectorAll<HTMLElement>("[data-lukas-spot]")];
  const maxScroll = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
  const line = window.innerHeight * TAKEOVER_LINE;
  return elements
    .map((element, i) => {
      const box = element.getBoundingClientRect();
      const center = box.top + window.scrollY + box.height / 2;
      const pose = element.dataset.lukasPose as LukasPose;
      return {
        element,
        id: element.dataset.lukasSpot ?? String(i),
        pose: POSES.includes(pose) ? pose : "wave",
        start: i === 0 ? 0 : clamp01((center - line) / maxScroll),
      };
    })
    .sort((a, b) => a.start - b.start);
}

function pageProgress(): number {
  const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
  return maxScroll > 0 ? clamp01(window.scrollY / maxScroll) : 0;
}

/**
 * Maps the page scroll to Lukas' current section: its pose and index (state, so it re-renders
 * only when the section changes), and calls `onScroll` once per animation frame while the page
 * scrolls or resizes with the spots, the progress and `y` (for direct, render-free updates).
 * The sections are the page's `[data-lukas-spot]` elements, in page order; without any it
 * returns null and Lukas stays where he is rendered.
 */
export function useScrollPose(
  onScroll?: (frame: { spots: LukasSpot[]; progress: number; index: number; y: number }) => void,
): ScrollPoseState | null {
  const [state, setState] = useState<ScrollPoseState | null>(null);
  const onScrollRef = useRef(onScroll);
  onScrollRef.current = onScroll;

  useEffect(() => {
    let spots = readSpots();
    if (spots.length === 0) return;
    let frame = 0;
    let measureNext = false;

    const update = () => {
      frame = 0;
      if (measureNext) {
        spots = readSpots();
        measureNext = false;
      }
      const progress = pageProgress();
      const index = sectionIndexAt(progress, spots);
      const { pose, y } = scrollPose(progress, spots);
      setState((previous) =>
        previous && previous.index === index && previous.spots === spots
          ? previous
          : { pose, index, spots },
      );
      onScrollRef.current?.({ spots, progress, index, y });
    };
    const schedule = () => {
      if (!frame) frame = requestAnimationFrame(update);
    };
    const remeasure = () => {
      measureNext = true;
      schedule();
    };

    update();
    window.addEventListener("scroll", schedule, { passive: true });
    window.addEventListener("resize", remeasure, { passive: true });
    // Layout changes without a resize (an FAQ answer opening, fonts loading) move the spots.
    const resizes = new ResizeObserver(remeasure);
    resizes.observe(document.body);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("scroll", schedule);
      window.removeEventListener("resize", remeasure);
      resizes.disconnect();
    };
  }, []);

  return state;
}
