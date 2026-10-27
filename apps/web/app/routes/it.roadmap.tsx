import { roadmapLinks, roadmapMeta } from "../features/landing/seo.ts";
import { Roadmap } from "../features/roadmap/Roadmap.tsx";

export const meta = () => roadmapMeta("it");
export const links = () => roadmapLinks("it");

/** `/it/roadmap`: what is planned, in Italian, prerendered. */
export default function RoadmapIt() {
  return <Roadmap />;
}
