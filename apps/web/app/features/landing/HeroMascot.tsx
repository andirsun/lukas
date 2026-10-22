import { useTranslations } from "use-intl";
import { Lukas } from "../../lukas/Lukas.tsx";

/**
 * The hero's Lukas: the 2D waving sprite, filling a square box that the stylesheet sizes per
 * viewport. It is also the first Lukas spot: once the traveling Lukas is live (see `Landing`), he
 * stands here waving and the sprite steps aside; the sprite stays under reduced motion and without
 * JavaScript (it is the prerendered content). Once per session the traveling Lukas rolls in from
 * `data-lukas-enter-from` (the side away from the text). The box carries the accessible name, so
 * whatever renders inside stays decorative.
 */
export function HeroMascot() {
  const t = useTranslations("landing.hero");
  return (
    <div
      className="lk-landing-mascot"
      data-slot="hero-mascot"
      data-lukas-spot="hero"
      data-lukas-pose="wave"
      data-lukas-mood="happy"
      // Opposite the headline on desktop, and from the right on phones: he never rolls over text.
      data-lukas-enter-from="right"
      role="img"
      aria-label={t("mascot")}
    >
      <Lukas mood="happy" size="100%" decorative />
    </div>
  );
}
