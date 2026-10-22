import { roadmapLinks, roadmapMeta } from "../features/landing/seo.ts";
import { Roadmap } from "../features/roadmap/Roadmap.tsx";

export const meta = () => roadmapMeta("es");
export const links = () => roadmapLinks("es");

/** `/roadmap`: what is planned, in Spanish (the default language), prerendered. */
export default function RoadmapEs() {
  return <Roadmap />;
}
