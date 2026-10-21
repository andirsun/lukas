import { Landing } from "../features/landing/Landing.tsx";
import { landingLinks, landingMeta } from "../features/landing/seo.ts";

export const meta = () => landingMeta("en");
export const links = () => landingLinks("en");

/** `/en`: the landing page in English, prerendered. */
export default function LandingEn() {
  return <Landing />;
}
