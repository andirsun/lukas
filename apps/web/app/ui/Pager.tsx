import { animate, type MotionValue, motion, useMotionValue, useTransform } from "motion/react";
import {
  Children,
  type CSSProperties,
  type MouseEvent,
  type PointerEvent,
  type ReactNode,
  useEffect,
  useRef,
  useState,
} from "react";
import { feedback } from "../feedback/feedback.ts";
import { gestureOwner, lockAxis, pagerTarget, rubberBand, velocityTracker } from "./gesture.ts";
import { durationToken, GESTURE, SPRINGS, useReducedMotionPreference } from "./motion-tokens.ts";

export interface PagerOptions {
  /** The page shown (and remembered by the caller). */
  index: number;
  count: number;
  onIndexChange(index: number): void;
  /** Off (wide screens, where the pages sit side by side): no gestures. */
  enabled?: boolean;
}

interface Drag {
  pointerId: number;
  x: number;
  y: number;
  /** Where the track was (in pages) when the finger came down: mid-spring, between two. */
  from: number;
  width: number;
  axis: "x" | "y" | null;
  tracker: ReturnType<typeof velocityTracker>;
}

export interface Pager {
  /**
   * Where the track is, in pages (0 = the first page, 0.5 = halfway to the second). It follows
   * the finger while dragging and springs to `index` after; the tabs' thumb follows it.
   */
  position: MotionValue<number>;
  /** Spread on the element whose sideways drags turn the pages (it may hold more than the track). */
  surface: {
    onPointerDown(event: PointerEvent<HTMLElement>): void;
    onPointerMove(event: PointerEvent<HTMLElement>): void;
    onPointerUp(event: PointerEvent<HTMLElement>): void;
    onPointerCancel(event: PointerEvent<HTMLElement>): void;
    onClickCapture(event: MouseEvent<HTMLElement>): void;
    style: CSSProperties;
  };
  index: number;
  /** Nothing is moving: the pages that are not shown are hidden (and out of reach). */
  settled: boolean;
  /** The track, measured for the drag's width (one page). */
  frame: React.RefObject<HTMLDivElement | null>;
  /** The page elements, for the reduced-motion cross-fade. */
  pages: React.RefObject<(HTMLDivElement | null)[]>;
}

/**
 * Pages that follow the finger (home's Movimientos ⇄ Presupuestos, spec §2.5): the content tracks
 * a sideways drag 1:1, resists past the first and last page (0.3×), and on release springs to the
 * nearer page, or one page on in a flick's direction. A drag picks its axis after a few pixels:
 * mostly down is the page's scroll, untouched. A drag that starts on a swipeable row is the row's
 * (`gestureOwner`). A light vibration marks each page change; a tap on the tabs slides the same
 * way. A new drag mid-spring carries on from where the track is. Under reduced motion nothing
 * follows the finger: on release the page switches with a short cross-fade.
 */
export function usePager({ index, count, onIndexChange, enabled = true }: PagerOptions): Pager {
  const reduceMotion = useReducedMotionPreference();
  const position = useMotionValue(index);
  const [settled, setSettled] = useState(true);
  const drag = useRef<Drag | null>(null);
  const dragged = useRef(false);
  const frame = useRef<HTMLDivElement>(null);
  const pages = useRef<(HTMLDivElement | null)[]>([]);
  /** The velocity (pages/s) a release hands to the spring that follows its page change. */
  const handoff = useRef(0);
  const shown = useRef(index);

  const settle = (target: number, velocity: number) => {
    setSettled(false);
    if (reduceMotion) {
      position.set(target);
      const page = pages.current[target];
      if (page && target !== shown.current) {
        animate(page, { opacity: [0, 1] }, { duration: durationToken("--fade") });
      }
      shown.current = target;
      setSettled(true);
      return;
    }
    shown.current = target;
    animate(position, target, { ...SPRINGS.pager, velocity }).then(() => {
      if (position.get() === target) setSettled(true);
    });
  };

  // The page changed (a release, a tap on the tabs, the keyboard): slide there, with a tick.
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    feedback("pageChange");
    const velocity = handoff.current;
    handoff.current = 0;
    settle(index, velocity);
  }, [index]);

  const onPointerDown = (event: PointerEvent<HTMLElement>) => {
    // Any new press starts clean: a touch drag is never followed by a click to swallow.
    dragged.current = false;
    if (!enabled || event.pointerType === "mouse" || !event.isPrimary) return;
    if (gestureOwner(event.target) !== "pager") return;
    const page = frame.current?.offsetWidth ?? 0;
    if (page === 0) return;
    // One page further along is a page and the gap between two.
    const width = page + GESTURE.pagerGap;
    // Mid-spring: catch the track where it is.
    position.stop();
    const tracker = velocityTracker();
    tracker.add(event.timeStamp, event.clientX);
    drag.current = {
      pointerId: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      from: position.get(),
      width,
      axis: null,
      tracker,
    };
    dragged.current = false;
  };

  const onPointerMove = (event: PointerEvent<HTMLElement>) => {
    const current = drag.current;
    if (!current || event.pointerId !== current.pointerId) return;
    const dx = event.clientX - current.x;
    const dy = event.clientY - current.y;
    if (current.axis === null) {
      current.axis = lockAxis(dx, dy, GESTURE.axisSlop);
      if (current.axis === "y") {
        drag.current = null;
        if (!settled || position.get() !== index) settle(index, 0);
        return;
      }
      if (current.axis === null) return;
      dragged.current = true;
      setSettled(false);
      try {
        event.currentTarget.setPointerCapture(event.pointerId);
      } catch {
        // Synthetic pointers (tests) cannot be captured; moves still arrive here.
      }
    }
    current.tracker.add(event.timeStamp, event.clientX);
    if (reduceMotion) return;
    position.set(rubberBand(current.from - dx / current.width, 0, count - 1, GESTURE.rubberBand));
  };

  const release = (event: PointerEvent<HTMLElement>, cancelled: boolean) => {
    const current = drag.current;
    if (!current || event.pointerId !== current.pointerId) return;
    drag.current = null;
    if (current.axis !== "x") return;
    // The click a drag may produce comes before any timer: forget the drag after it.
    setTimeout(() => {
      dragged.current = false;
    }, 0);
    const vx = cancelled ? 0 : current.tracker.velocity(event.timeStamp);
    const base = Math.round(current.from);
    const dx = event.clientX - current.x;
    const target = cancelled
      ? index
      : pagerTarget({
          index: base,
          // Measured from the page it started nearest to, so a catch mid-spring counts right.
          dx: dx + (current.from - base) * -current.width,
          vx,
          width: current.width,
          count,
          flick: GESTURE.flickVelocity,
        });
    const max = GESTURE.pagerMaxVelocity;
    const velocity = Math.max(-max, Math.min(max, -vx / current.width));
    if (target !== index) {
      handoff.current = velocity;
      onIndexChange(target);
    } else {
      settle(index, velocity);
    }
  };

  // A drag is never also a tap on what it started on.
  const onClickCapture = (event: MouseEvent<HTMLElement>) => {
    if (!dragged.current) return;
    dragged.current = false;
    event.preventDefault();
    event.stopPropagation();
  };

  return {
    position,
    index,
    settled,
    frame,
    pages,
    surface: {
      onPointerDown,
      onPointerMove,
      onPointerUp: (event) => release(event, false),
      onPointerCancel: (event) => release(event, true),
      onClickCapture,
      // Vertical scrolling and zoom stay the browser's; sideways drags are ours.
      style: enabled ? { touchAction: "pan-y pinch-zoom" } : {},
    },
  };
}

/**
 * The pages of a `usePager`, side by side on a track that moves with `position`. The shown page is
 * in the flow (the pager takes its height); the others sit beside it, hidden once nothing moves.
 */
export function PagerTrack({ pager, children }: { pager: Pager; children: ReactNode }) {
  const gap = GESTURE.pagerGap;
  const x = useTransform(pager.position, (p) => `calc(${-p * 100}% - ${p * gap}px)`);
  const pages = Children.toArray(children);
  return (
    <div className="lk-pager">
      <motion.div ref={pager.frame} data-pager-track="" className="lk-pager-track" style={{ x }}>
        {pages.map((page, i) => {
          const shown = i === pager.index;
          const hidden = !shown && pager.settled;
          return (
            <div
              key={i}
              ref={(node) => {
                pager.pages.current[i] = node;
              }}
              className="lk-pager-page"
              inert={hidden}
              style={{
                position: shown ? "relative" : "absolute",
                left: `calc(${i * 100}% + ${i * gap}px)`,
                visibility: hidden ? "hidden" : undefined,
              }}
            >
              {page}
            </div>
          );
        })}
      </motion.div>
    </div>
  );
}
