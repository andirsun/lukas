import { Lukas, type LukasMood } from "../lukas/Lukas.tsx";

export interface LukasBubbleProps {
  /** Lukas's line, already translated and filled with the real figures. */
  message: string;
  mood: LukasMood;
}

/**
 * Lukas beside his speech bubble. The line carries the meaning, so Lukas is decorative here; the
 * bubble is a polite live region, so a new line after a save or a month change is read out.
 */
export function LukasBubble({ message, mood }: LukasBubbleProps) {
  return (
    <div className="flex items-center gap-(--space-3)">
      <Lukas mood={mood} size={72} decorative />
      <p
        className="lk-bubble lk-bubble-tail m-0 min-w-0 flex-1 text-ink"
        aria-live="polite"
        aria-atomic="true"
      >
        {message}
      </p>
    </div>
  );
}
