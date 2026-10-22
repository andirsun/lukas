import { useTranslations } from "use-intl";
import type { RoadmapItem } from "./roadmap.ts";

/** One planned feature: a glyph, its title and one line, in the landing's card look. */
export function RoadmapCard({ item }: { item: RoadmapItem }) {
  const t = useTranslations();
  return (
    <li className="lk-landing-card">
      <div className="lk-landing-card-head">
        <span className="lk-landing-icon is-glyph" aria-hidden="true">
          {item.glyph}
        </span>
        <h3>{t(item.title)}</h3>
      </div>
      <p>{t(item.body)}</p>
    </li>
  );
}
