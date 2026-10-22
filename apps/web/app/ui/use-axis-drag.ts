import { type MouseEvent, type PointerEvent, useRef } from "react";
import { type Axis, lockAxis, velocityTracker } from "./gesture.ts";
import { GESTURE } from "./motion-tokens.ts";

export interface AxisDragHandlers {
  /**
   * A finger came down on something this component owns. Stop any spring here (a touch catches
   * the motion where it is) and return false to ignore the touch altogether.
   */
  onStart(event: PointerEvent<HTMLElement>): boolean | undefined;
  /**
   * The gesture just turned this drag's way (after the slop), `delta` so far: it is a drag from
   * now on, unless this returns false (then it is left to the browser, as a scroll would be).
   */
  onLock?(delta: number): boolean | undefined;
  /** Every move along the axis: `delta` from where the finger came down. */
  onMove(delta: number): void;
  /** The drag ended: `velocity` along the axis in px/s (0 when the browser cancelled it). */
  onRelease(delta: number, velocity: number, cancelled: boolean): void;
  /**
   * The touch ended without becoming this drag (a tap, a move the other way, a cancel before the
   * slop): whatever `onStart` stopped must go back to rest now.
   */
  onSettle(): void;
}

export interface AxisDragOptions {
  /** The drag's direction: sideways (the pager, the rows) or down (the sheet). */
  axis?: Axis;
  /** Whether a touch that starts on `target` is this drag's to take (see `gestureOwner`). */
  accept?(target: EventTarget | null): boolean;
  /** A mouse press on `target` drags too (the sheet's grab bar); otherwise the mouse is ignored. */
  mouse?(target: EventTarget | null): boolean;
  enabled?: boolean;
}

interface Drag {
  pointerId: number;
  x: number;
  y: number;
  axis: Axis | null;
  tracker: ReturnType<typeof velocityTracker>;
}

/**
 * One finger's drag along one axis, shared by the home pager, the swipeable rows and the sheet:
 * it takes the touches `accept` allows (the mouse only where `mouse` says), picks the axis after
 * `GESTURE.axisSlop` px, follows a drag its way with pointer capture, measures the release speed,
 * and swallows the click a drag may end with. A touch that never becomes this drag always ends in
 * `onSettle`, so an interrupted spring never stays where the touch caught it.
 */
export function useAxisDrag(
  { axis = "x", accept = () => true, mouse = () => false, enabled = true }: AxisDragOptions,
  handlers: AxisDragHandlers,
) {
  const drag = useRef<Drag | null>(null);
  const dragged = useRef(false);
  // The latest handlers (they close over render state).
  const latest = useRef(handlers);
  latest.current = handlers;
  const along = (event: { clientX: number; clientY: number }) =>
    axis === "x" ? event.clientX : event.clientY;

  const end = (event: PointerEvent<HTMLElement>, cancelled: boolean) => {
    const current = drag.current;
    if (!current || event.pointerId !== current.pointerId) return;
    drag.current = null;
    if (current.axis !== axis) {
      latest.current.onSettle();
      return;
    }
    // The click a drag may produce comes before any timer: forget the drag after it.
    setTimeout(() => {
      dragged.current = false;
    }, 0);
    const velocity = cancelled ? 0 : current.tracker.velocity(event.timeStamp);
    const start = axis === "x" ? current.x : current.y;
    latest.current.onRelease(along(event) - start, velocity, cancelled);
  };

  return {
    /** Whether a drag (or a touch that may become one) is under way. */
    active: () => drag.current !== null,
    /** Whether the touch under way has become this drag. */
    locked: () => drag.current?.axis === axis,
    onPointerDown(event: PointerEvent<HTMLElement>) {
      // Any new press starts clean: a touch drag is never followed by a click to swallow.
      dragged.current = false;
      if (!enabled || !event.isPrimary) return;
      if (event.pointerType === "mouse" ? !mouse(event.target) : !accept(event.target)) return;
      if (latest.current.onStart(event) === false) return;
      const tracker = velocityTracker();
      tracker.add(event.timeStamp, along(event));
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
      if (current.axis === null) {
        current.axis = lockAxis(
          event.clientX - current.x,
          event.clientY - current.y,
          GESTURE.axisSlop,
        );
        if (current.axis === null) return;
        if (current.axis !== axis) {
          // The other way (a scroll, a sideways swipe): not ours. What the touch caught rests.
          drag.current = null;
          latest.current.onSettle();
          return;
        }
        const delta = along(event) - (axis === "x" ? current.x : current.y);
        if (latest.current.onLock?.(delta) === false) {
          drag.current = null;
          latest.current.onSettle();
          return;
        }
        dragged.current = true;
        try {
          event.currentTarget.setPointerCapture(event.pointerId);
        } catch {
          // Synthetic pointers (tests) cannot be captured; moves still arrive here.
        }
      }
      current.tracker.add(event.timeStamp, along(event));
      latest.current.onMove(along(event) - (axis === "x" ? current.x : current.y));
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
