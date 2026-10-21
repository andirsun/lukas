import type { CSSProperties } from "react";
import { useTranslations } from "use-intl";
import { Footer } from "../landing/Footer.tsx";
import { SiteHeader } from "../landing/SiteHeader.tsx";
import { RoadmapCard } from "./RoadmapCard.tsx";
import { type RoadmapColumn, roadmapColumns } from "./roadmap.ts";
import "../landing/landing.css";
import "./roadmap.css";

function Column({ column }: { column: RoadmapColumn }) {
  const t = useTranslations("roadmap");
  const id = `roadmap-${column.status}`;
  return (
    <section className={`lk-roadmap-column is-${column.status}`} aria-labelledby={id}>
      <h2 id={id} className="lk-roadmap-label">
        <span className="lk-roadmap-dot" aria-hidden="true" />
        {t(`status.${column.status}`)}
      </h2>
      <ul className="lk-roadmap-list">
        {column.items.map((item) => (
          <RoadmapCard key={item.id} item={item} />
        ))}
      </ul>
    </section>
  );
}

/**
 * The public roadmap (`/roadmap`, `/en/roadmap`), prerendered: what is planned, in a column per
 * status (only those that have items), a single column on a phone and side by side on a desktop.
 * No dates, and nothing to propose or vote on yet.
 */
export function Roadmap() {
  const t = useTranslations("roadmap");
  const columns = roadmapColumns();
  return (
    <div className="lk-screen lk-landing">
      <SiteHeader page="roadmap" />
      <main className="lk-landing-wrap lk-roadmap">
        <div className="lk-roadmap-intro">
          <h1>{t("title")}</h1>
          <p className="lk-landing-lede">{t("intro")}</p>
        </div>
        <div
          className="lk-roadmap-board"
          style={{ "--lk-columns": columns.length } as CSSProperties}
        >
          {columns.map((column) => (
            <Column key={column.status} column={column} />
          ))}
        </div>
      </main>
      <Footer page="roadmap" />
    </div>
  );
}
