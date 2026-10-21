import { roadmapLinks, roadmapMeta } from "../features/landing/seo.ts";
import { Roadmap } from "../features/roadmap/Roadmap.tsx";

export const meta = () => roadmapMeta("en");
export const links = () => roadmapLinks("en");

/** `/en/roadmap`: what is planned, in English, prerendered. */
export default function RoadmapEn() {
  return <Roadmap />;
}
