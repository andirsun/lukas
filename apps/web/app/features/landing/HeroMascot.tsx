import { useTranslations } from "use-intl";
import { Lukas } from "../../lukas/Lukas.tsx";

/**
 * The hero's Lukas: the 2D waving sprite, filling a square box that the stylesheet sizes per
 * viewport. This is the seam for Task 17, which loads `Lukas3D` lazily into this same slot (and
 * keeps this still version under reduced motion, without WebGL or on low-memory devices). The box
 * carries the accessible name, so whatever renders inside stays decorative.
 */
export function HeroMascot() {
  const t = useTranslations("landing.hero");
  return (
    <div className="lk-landing-mascot" data-slot="hero-mascot" role="img" aria-label={t("mascot")}>
      <Lukas mood="happy" size="100%" decorative />
    </div>
  );
}
