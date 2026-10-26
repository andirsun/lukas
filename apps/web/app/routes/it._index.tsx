import { Landing } from "../features/landing/Landing.tsx";
import { landingLinks, landingMeta } from "../features/landing/seo.ts";

export const meta = () => landingMeta("it");
export const links = () => landingLinks("it");

/** `/it`: the landing page in Italian, prerendered. */
export default function LandingIt() {
  return <Landing />;
}
