import type { LukasPose } from "../../lukas/use-scroll-pose.ts";

/**
 * Where the 3D Lukas stands for a section (see `useScrollPose`): an empty, decorative box in free
 * space beside the section's heading, sized per viewport by landing.css. Without the 3D Lukas
 * (no JavaScript, reduced motion, no WebGL) it is just empty space.
 */
export function LukasSpot({ id, pose }: { id: string; pose: LukasPose }) {
  return (
    <span
      className={`lk-landing-spot is-${id}`}
      data-lukas-spot={id}
      data-lukas-pose={pose}
      aria-hidden="true"
    />
  );
}
