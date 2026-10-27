import { Landing } from "../features/landing/Landing.tsx";
import { landingLinks, landingMeta } from "../features/landing/seo.ts";

export const meta = () => landingMeta("pt");
export const links = () => landingLinks("pt");

/** `/pt`: the landing page in European Portuguese, prerendered. */
export default function LandingPt() {
  return <Landing />;
}
