import { type CSSProperties, useEffect, useState } from "react";
import { Lukas } from "../lukas/Lukas.tsx";
import { durationToken, useReducedMotionPreference } from "../ui/motion-tokens.ts";
import { FEEDBACK_DOM_EVENT, type FeedbackDetail, type FeedbackEvent } from "./feedback.ts";
import "./Celebration.css";

/** The events worth a party. Near the limit, over budget, undo and plain taps are not. */
export const CELEBRATED_EVENTS: readonly FeedbackEvent[] = ["expenseSaved", "incomeSaved", "paid"];

const TONES = ["gold", "candy", "good"] as const;
const PIECES = 28;
/** Used when the `--celebrate` token cannot be read (no stylesheet). */
const FALLBACK_MS = 1200;
/** How long to wait for a landing spot to appear (a screen still arriving, as after onboarding). */
const FIND_SPOT_MS = 800;

/**
 * Marks where Lukitas may land: free space that never holds text or figures (an empty spot in the
 * sidebar), or, with `data-celebration-place="above"`, the element he stands just above (the ＋ of
 * the bottom bar, which stays in view and tappable). Its value is his size in px. The first one on
 * screen wins.
 */
export const CELEBRATION_ANCHOR = "data-celebration-anchor";
/** px between Lukitas's feet and the element he stands above. */
const ABOVE_GAP = 4;

/**
 * Marks what Lukitas must never cover besides his spot: the toasts (with their Deshacer), which a
 * save shows at the same moment. Its box is its layout box (an entering toast's slide is ignored).
 */
export const CELEBRATION_AVOID = "data-celebration-avoid";

/** Lukitas's box at `spot`, in viewport px. */
const boxAt = (spot: Spot) => ({
  left: spot.x - spot.size / 2,
  right: spot.x + spot.size / 2,
  top: spot.top,
  bottom: spot.top + spot.size,
});

/** Moves `spot` up until Lukitas's box clears every `CELEBRATION_AVOID` box on screen. */
function clearOfObstacles(spot: Spot): Spot {
  const obstacles = [...document.querySelectorAll<HTMLElement>(`[${CELEBRATION_AVOID}]`)]
    .map((element) => element.getBoundingClientRect())
    .filter((rect) => rect.width > 0 && rect.height > 0);
  let current = spot;
  // Each step only moves him up, so a few passes settle it (he can't bounce between two).
  for (let pass = 0; pass < obstacles.length + 1; pass++) {
    const box = boxAt(current);
    const hit = obstacles.find(
      (rect) =>
        box.left < rect.right &&
        rect.left < box.right &&
        box.top < rect.bottom + ABOVE_GAP &&
        rect.top < box.bottom + ABOVE_GAP,
    );
    if (!hit) return current;
    current = { ...current, top: hit.top - current.size - ABOVE_GAP };
  }
  return current;
}

interface Spot {
  /** The spot's horizontal center and top, in viewport px. */
  x: number;
  top: number;
  size: number;
}

/** The first landing spot on screen, or null while there is none. */
function findSpot(): Spot | null {
  for (const element of document.querySelectorAll<HTMLElement>(`[${CELEBRATION_ANCHOR}]`)) {
    const rect = element.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0) continue;
    const size = Number(element.getAttribute(CELEBRATION_ANCHOR)) || rect.width;
    const above = element.dataset.celebrationPlace === "above";
    return {
      x: rect.left + rect.width / 2,
      top: above ? rect.top - size - ABOVE_GAP : rect.top,
      size,
    };
  }
  return null;
}

/** No spot at all (a screen without a bottom bar or sidebar): the top of the screen. */
function fallbackSpot(): Spot {
  return { x: window.innerWidth / 2, top: 8, size: 72 };
}

interface Piece {
  tone: (typeof TONES)[number];
  round: boolean;
  dx: number;
  rise: number;
  fall: number;
  spin: number;
}

/** Evenly fanned (golden angle) so the same burst always looks the same, with no randomness. */
const BURST: readonly Piece[] = Array.from({ length: PIECES }, (_, index) => {
  const angle = index * 2.399963;
  const reach = 70 + ((index * 37) % 90);
  const dx = Math.round(Math.cos(angle) * reach * 1.5);
  const rise = -Math.round(60 + ((index * 53) % 110));
  return {
    tone: TONES[index % TONES.length] as Piece["tone"],
    round: index % 4 === 3,
    dx,
    rise,
    fall: Math.round(rise + 150 + ((index * 29) % 90)),
    spin: (index % 2 === 0 ? 1 : -1) * (240 + ((index * 61) % 300)),
  };
});

/**
 * Confetti and a celebrating Lukitas, shown when `feedback()` reports something worth
 * celebrating. Lukitas lands in free space, never over text or figures: just above the ＋ of the
 * bottom bar on phones (never on it: it stays visible and tappable), and above the undo toast while
 * one is up (`CELEBRATION_AVOID`), in the sidebar's empty spot on wide screens (`CELEBRATION_ANCHOR`), and the confetti
 * bursts from there. Purely decorative (hidden from assistive technology: the toast or screen
 * already says what happened) and it never takes a tap. Under reduced motion there is no confetti:
 * Lukitas shows as his still celebrating frame and only fades in and out. Mounted once, in the app
 * layout.
 */
export function Celebration() {
  const reduceMotion = useReducedMotionPreference();
  const [shown, setShown] = useState<({ id: number } & Spot) | null>(null);

  useEffect(() => {
    let id = 0;
    let timer: ReturnType<typeof setTimeout> | undefined;
    let frame = 0;
    const onFeedback = (event: Event) => {
      const detail = (event as CustomEvent<FeedbackDetail>).detail;
      if (!detail || !CELEBRATED_EVENTS.includes(detail.event)) return;
      id += 1;
      const mine = id;
      clearTimeout(timer);
      cancelAnimationFrame(frame);
      const started = performance.now();
      // The screen may still be arriving (onboarding hands over to home): look for a spot.
      const place = () => {
        if (mine !== id) return;
        const spot = findSpot();
        if (!spot && performance.now() - started < FIND_SPOT_MS) {
          frame = requestAnimationFrame(place);
          return;
        }
        let placed = clearOfObstacles(spot ?? fallbackSpot());
        setShown({ id: mine, ...placed });
        const ms = durationToken("--celebrate") * 1000 || FALLBACK_MS;
        timer = setTimeout(() => setShown(null), ms + 50);
        // A toast that shows a moment later (or grows) pushes him up; he never moves down.
        const follow = () => {
          if (mine !== id || performance.now() - started > ms) return;
          const next = clearOfObstacles(placed);
          if (next.top < placed.top - 0.5) {
            placed = next;
            setShown({ id: mine, ...placed });
          }
          frame = requestAnimationFrame(follow);
        };
        frame = requestAnimationFrame(follow);
      };
      // One frame on: the toast a save shows with its celebration is on the page by then.
      frame = requestAnimationFrame(place);
    };
    window.addEventListener(FEEDBACK_DOM_EVENT, onFeedback);
    return () => {
      window.removeEventListener(FEEDBACK_DOM_EVENT, onFeedback);
      clearTimeout(timer);
      cancelAnimationFrame(frame);
    };
  }, []);

  if (!shown) return null;
  return (
    // The key restarts the animation when another event arrives mid-celebration.
    <div
      key={shown.id}
      className={`lk-celebration${reduceMotion ? " is-reduced" : ""}`}
      aria-hidden="true"
      data-testid="celebration"
    >
      <div className="lk-celebration-burst" style={{ left: shown.x, top: shown.top }}>
        {!reduceMotion &&
          BURST.map((piece, index) => (
            <span
              key={index}
              className={`lk-confetti is-${piece.tone}${piece.round ? " is-round" : ""}`}
              style={
                {
                  "--lk-dx": `${piece.dx}px`,
                  "--lk-rise": `${piece.rise}px`,
                  "--lk-fall": `${piece.fall}px`,
                  "--lk-spin": `${piece.spin}deg`,
                } as CSSProperties
              }
            />
          ))}
        <span className="lk-celebration-lukas" style={{ width: shown.size, height: shown.size }}>
          <Lukas mood="celebrating" size={shown.size} decorative />
        </span>
      </div>
    </div>
  );
}
