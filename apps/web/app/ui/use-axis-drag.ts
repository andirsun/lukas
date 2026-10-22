import { type MouseEvent, type PointerEvent, useRef } from "react";
import { type GestureOwner, gestureOwner, lockAxis, velocityTracker } from "./gesture.ts";
import { GESTURE } from "./motion-tokens.ts";

export interface AxisDragHandlers {
  /**
   * A finger came down on something this component owns. Stop any spring here (a touch catches
   * the motion where it is) and return false to ignore the touch altogether.
   */
  onStart(event: PointerEvent<HTMLElement>): boolean | undefined;
  /** The gesture just turned sideways (after the slop): it is a drag from now on. */
  onLock?(): void;
  /** Every sideways move: `dx` from where the finger came down. */
  onMove(dx: number): void;
  /** The sideways drag ended: `vx` in px/s (0 when the browser cancelled it). */
  onRelease(dx: number, vx: number, cancelled: boolean): void;
  /**
   * The touch ended without becoming a sideways drag (a tap, a scroll, a cancel before the slop):
   * whatever its `onStart` stopped must go back to rest now.
   */
  onSettle(): void;
}

interface Drag {
  pointerId: number;
  x: number;
  y: number;
  axis: "x" | "y" | null;
  tracker: ReturnType<typeof velocityTracker>;
}

/**
 * One finger's sideways drag, shared by the home pager and the swipeable rows: it takes touches
 * that `gestureOwner` gives to `owner` (never the mouse), picks the axis after `GESTURE.axisSlop`
 * px, follows a sideways drag with pointer capture, measures the release speed, and swallows the
 * click a drag may end with. A touch that never turns sideways always ends in `onSettle`, so an
 * interrupted spring never stays where the touch caught it.
 */
export function useAxisDrag(owner: GestureOwner, handlers: AxisDragHandlers, enabled = true) {
  const drag = useRef<Drag | null>(null);
  const dragged = useRef(false);
  // The latest handlers (they close over render state), without re-creating the listeners' logic.
  const latest = useRef(handlers);
  latest.current = handlers;

  const end = (event: PointerEvent<HTMLElement>, cancelled: boolean) => {
    const current = drag.current;
    if (!current || event.pointerId !== current.pointerId) return;
    drag.current = null;
    if (current.axis !== "x") {
      latest.current.onSettle();
      return;
    }
    // The click a drag may produce comes before any timer: forget the drag after it.
    setTimeout(() => {
      dragged.current = false;
    }, 0);
    const vx = cancelled ? 0 : current.tracker.velocity(event.timeStamp);
    latest.current.onRelease(event.clientX - current.x, vx, cancelled);
  };

  return {
    onPointerDown(event: PointerEvent<HTMLElement>) {
      // Any new press starts clean: a touch drag is never followed by a click to swallow.
      dragged.current = false;
      if (!enabled || event.pointerType === "mouse" || !event.isPrimary) return;
      if (gestureOwner(event.target) !== owner) return;
      if (latest.current.onStart(event) === false) return;
      const tracker = velocityTracker();
      tracker.add(event.timeStamp, event.clientX);
      drag.current = {
        pointerId: event.pointerId,
        x: event.clientX,
        y: event.clientY,
        axis: null,
        tracker,
      };
    },
    onPointerMove(event: PointerEvent<HTMLElement>) {
      const current = drag.current;
      if (!current || event.pointerId !== current.pointerId) return;
      const dx = event.clientX - current.x;
      if (current.axis === null) {
        current.axis = lockAxis(dx, event.clientY - current.y, GESTURE.axisSlop);
        if (current.axis === "y") {
          // A scroll: the browser's. What the touch caught goes back to rest.
          drag.current = null;
          latest.current.onSettle();
          return;
        }
        if (current.axis === null) return;
        dragged.current = true;
        try {
          event.currentTarget.setPointerCapture(event.pointerId);
        } catch {
          // Synthetic pointers (tests) cannot be captured; moves still arrive here.
        }
        latest.current.onLock?.();
      }
      current.tracker.add(event.timeStamp, event.clientX);
      latest.current.onMove(dx);
    },
    onPointerUp(event: PointerEvent<HTMLElement>) {
      end(event, false);
    },
    onPointerCancel(event: PointerEvent<HTMLElement>) {
      end(event, true);
    },
    /** A drag is never also a tap on what it started on. Returns whether it swallowed the click. */
    swallowClick(event: MouseEvent<HTMLElement>): boolean {
      if (!dragged.current) return false;
      dragged.current = false;
      event.preventDefault();
      event.stopPropagation();
      return true;
    },
  };
}
