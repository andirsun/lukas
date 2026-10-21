import type { LukasMood } from "../../lukas/mood.ts";
import type { LukasPose } from "../../lukas/use-scroll-pose.ts";

/**
 * Where the traveling Lukas stands for a section (see `useScrollPose` and `TravelingLukas`): an
 * empty, decorative box in free space beside the section's heading, sized per viewport by
 * landing.css. He shows `mood` here (`data-lukas-mood`). Without him (no JavaScript, reduced
 * motion) it is just empty space.
 */
export function LukasSpot({ id, pose, mood }: { id: string; pose: LukasPose; mood: LukasMood }) {
  return (
    <span
      className={`lk-landing-spot is-${id}`}
      data-lukas-spot={id}
      data-lukas-pose={pose}
      data-lukas-mood={mood}
      aria-hidden="true"
    />
  );
}
