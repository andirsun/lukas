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
 * celebrating. Purely decorative (hidden from assistive technology: the toast or screen already
 * says what happened) and it never takes a tap. Under reduced motion there is no confetti: Lukitas
 * shows as his still celebrating frame and only fades in and out. Mounted once, in the app layout.
 */
export function Celebration() {
  const reduceMotion = useReducedMotionPreference();
  const [shown, setShown] = useState<{ id: number } | null>(null);

  useEffect(() => {
    let id = 0;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const onFeedback = (event: Event) => {
      const detail = (event as CustomEvent<FeedbackDetail>).detail;
      if (!detail || !CELEBRATED_EVENTS.includes(detail.event)) return;
      id += 1;
      setShown({ id });
      clearTimeout(timer);
      const ms = durationToken("--celebrate") * 1000 || FALLBACK_MS;
      timer = setTimeout(() => setShown(null), ms + 50);
    };
    window.addEventListener(FEEDBACK_DOM_EVENT, onFeedback);
    return () => {
      window.removeEventListener(FEEDBACK_DOM_EVENT, onFeedback);
      clearTimeout(timer);
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
      <div className="lk-celebration-burst">
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
        <span className="lk-celebration-lukas">
          <Lukas mood="celebrating" size={120} decorative />
        </span>
      </div>
    </div>
  );
}
