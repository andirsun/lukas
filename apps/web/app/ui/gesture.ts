/**
 * The math behind the swipes (the home pager and the transaction rows), pure so every rule is
 * unit-tested. The feel values themselves (slop, flick speed, rubber band, threshold) live in
 * `GESTURE` in motion-tokens.ts; callers pass them in.
 */

export type Axis = "x" | "y";

/**
 * Which way a gesture goes, decided once the finger has moved more than `slop` px: sideways only
 * when the move is more sideways than down (a perfect diagonal scrolls). Null until then. Once a
 * gesture is vertical it stays the browser's: the list scrolls untouched.
 */
export function lockAxis(dx: number, dy: number, slop: number): Axis | null {
  const ax = Math.abs(dx);
  const ay = Math.abs(dy);
  if (Math.max(ax, ay) <= slop) return null;
  return ax > ay ? "x" : "y";
}

/** `value` inside [min, max]; past either bound it moves only `factor` as much (the rubber band). */
export function rubberBand(value: number, min: number, max: number, factor: number): number {
  if (value < min) return min + (value - min) * factor;
  if (value > max) return max + (value - max) * factor;
  return value;
}

/**
 * The finger's speed (px/s) from its last moves within `windowMs`: a pause before lifting the
 * finger is not a flick.
 */
export function velocityTracker(windowMs = 100) {
  let samples: { t: number; x: number }[] = [];
  return {
    add(t: number, x: number) {
      samples.push({ t, x });
      samples = samples.filter((s) => t - s.t <= windowMs);
    },
    velocity(now: number): number {
      const recent = samples.filter((s) => now - s.t <= windowMs);
      const first = recent[0];
      const last = recent.at(-1);
      if (!first || !last || last.t === first.t) return 0;
      return ((last.x - first.x) / (last.t - first.t)) * 1000;
    },
    reset() {
      samples = [];
    },
  };
}

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

/**
 * The page a released pager settles on. A flick (|vx| over `flick` px/s) goes one page its way,
 * whatever the distance; otherwise the nearer page wins. `dx` is how far the finger moved (right is
 * positive, toward the previous page). It never leaves the pages.
 */
export function pagerTarget({
  index,
  dx,
  vx,
  width,
  count,
  flick,
}: {
  index: number;
  dx: number;
  vx: number;
  width: number;
  count: number;
  flick: number;
}): number {
  const last = count - 1;
  if (Math.abs(vx) >= flick) return clamp(index - Math.sign(vx), 0, last);
  return clamp(Math.round(index - dx / (width || 1)), 0, last);
}

/**
 * Where a dragged row sits: from where it started (`start`: 0, or open at ±the action's width)
 * plus the finger's move, 1:1 toward a side that has an action (up to the row's width), with the
 * rubber band toward a side that has none. Negative is left (the delete side).
 */
export function rowOffset({
  start,
  dx,
  width,
  factor,
  left,
  right,
}: {
  start: number;
  dx: number;
  width: number;
  factor: number;
  /** Whether swiping left (delete) does something. */
  left: boolean;
  /** Whether swiping right (edit, paid) does something. */
  right: boolean;
}): number {
  const min = left ? -width : 0;
  const max = right ? width : 0;
  const raw = start + dx;
  return clamp(rubberBand(raw, min, max, factor), -width, width);
}

/** The side whose action a release would run: past `threshold` (a fraction of the row's width). */
export function armedSide(
  offset: number,
  width: number,
  threshold: number,
): "left" | "right" | null {
  if (Math.abs(offset) < threshold * width) return null;
  return offset < 0 ? "left" : "right";
}

export type RowRelease = "commit-left" | "commit-right" | "open-left" | "open-right" | "close";

/**
 * What a released row does: past the threshold, or flicked toward a side, it runs that side's
 * action; a shorter swipe (past half the action's width) leaves the action open; anything less,
 * or a flick back, closes it.
 */
export function rowRelease({
  offset,
  vx,
  width,
  threshold,
  flick,
  openWidth,
  left,
  right,
}: {
  offset: number;
  vx: number;
  width: number;
  threshold: number;
  flick: number;
  openWidth: number;
  left: boolean;
  right: boolean;
}): RowRelease {
  const side = offset < 0 ? "left" : offset > 0 ? "right" : null;
  if (side === null) return "close";
  const has = side === "left" ? left : right;
  if (!has) return "close";
  const toward = side === "left" ? vx <= -flick : vx >= flick;
  const back = side === "left" ? vx >= flick : vx <= -flick;
  if (toward || armedSide(offset, width, threshold) === side) return `commit-${side}`;
  if (back) return "close";
  return Math.abs(offset) >= openWidth / 2 ? `open-${side}` : "close";
}

// -- Who owns a gesture ----------------------------------------------------------------------------

/** Marks an element as a swipeable row (`SwipeRow` sets it). */
export const SWIPE_ROW_ATTRIBUTE = "data-swipe-row";

export type GestureOwner = "row" | "pager";

/**
 * THE one place that decides who owns a sideways gesture (founder ruling, 2026-10-22; it may
 * change): a gesture that starts on a swipeable row belongs to the row; anything else (the summary
 * card, the tabs, the day headings, empty space, the whole Categorías page) belongs to the tab
 * pager. Both the pager and the rows ask this, so changing the rule here changes it everywhere.
 */
export function gestureOwner(
  start: EventTarget | { closest?(selector: string): unknown } | null,
): GestureOwner {
  const element = start as { closest?(selector: string): unknown } | null;
  return element &&
    typeof element.closest === "function" &&
    element.closest(`[${SWIPE_ROW_ATTRIBUTE}]`)
    ? "row"
    : "pager";
}
