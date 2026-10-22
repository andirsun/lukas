import { useEffect, useRef } from "react";
import { Lukas, type LukasMood } from "../lukas/Lukas.tsx";
import { durationToken, useReducedMotionPreference } from "./motion-tokens.ts";

export interface LukasBubbleProps {
  /** Lukas's line, already translated and filled with the real figures. */
  message: string;
  mood: LukasMood;
  /**
   * Changing it swaps the line in quietly: the bubble is a new live region, and a live region
   * that appears with its text is not announced. Home changes it when a line about a save or a
   * payment ends, so going back to the month's line is never read out a second time.
   */
  quietKey?: string | number;
}

/**
 * Lukas beside his speech bubble. The line carries the meaning, so Lukas is decorative here; the
 * bubble is a polite live region, so a new line after a save or a month change is read out (once).
 * A new line fades in (`--fade`); under reduced motion it just shows.
 */
export function LukasBubble({ message, mood, quietKey }: LukasBubbleProps) {
  const line = useRef<HTMLParagraphElement>(null);
  const reduceMotion = useReducedMotionPreference();
  const shown = useRef(message);

  useEffect(() => {
    if (shown.current === message) return;
    shown.current = message;
    const seconds = durationToken("--fade");
    if (reduceMotion || !seconds) return;
    line.current?.animate?.([{ opacity: 0 }, { opacity: 1 }], {
      duration: seconds * 1000,
      easing: "ease-out",
    });
  }, [message, reduceMotion]);

  return (
    <div className="flex items-center gap-(--space-3)">
      <Lukas mood={mood} size={72} decorative />
      <p
        key={quietKey}
        ref={line}
        className="lk-bubble lk-bubble-tail m-0 min-w-0 flex-1 text-ink"
        aria-live="polite"
        aria-atomic="true"
      >
        {message}
      </p>
    </div>
  );
}
