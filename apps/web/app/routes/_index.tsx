import { Landing } from "../features/landing/Landing.tsx";
import { landingLinks, landingMeta } from "../features/landing/seo.ts";

export const meta = () => landingMeta("es");
export const links = () => landingLinks("es");

/** `/`: the landing page in Spanish (the default language), prerendered. */
export default function LandingEs() {
  return <Landing />;
}
