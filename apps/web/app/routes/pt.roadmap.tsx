import { roadmapLinks, roadmapMeta } from "../features/landing/seo.ts";
import { Roadmap } from "../features/roadmap/Roadmap.tsx";

export const meta = () => roadmapMeta("pt");
export const links = () => roadmapLinks("pt");

/** `/pt/roadmap`: what is planned, in European Portuguese, prerendered. */
export default function RoadmapPt() {
  return <Roadmap />;
}
