import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { ROADMAP_PATH } from "../../site/paths.ts";
import { PressLink } from "../../ui/PressLink.tsx";
import { RoadmapCard } from "./RoadmapCard.tsx";
import { LANDING_ROADMAP_IDS, roadmapItem } from "./roadmap.ts";

/**
 * "Lo que viene" on the landing, after "open source" and before the FAQ: the three next features
 * in the same cards as "use it your way", and a button to the whole roadmap. No spot for the
 * traveling Lukitas here: he flies from "how it works" to the FAQ, past this section.
 */
export function WhatsNext() {
  const t = useTranslations("roadmap");
  const { locale } = useLocale();
  return (
    <section id="whats-next" className="lk-landing-section" aria-labelledby="whats-next-title">
      <div className="lk-landing-section-head is-plain">
        <h2 id="whats-next-title">{t("landing.title")}</h2>
        <p className="lk-landing-lede">{t("intro")}</p>
      </div>
      <ul className="lk-landing-cards is-next">
        {LANDING_ROADMAP_IDS.map((id) => (
          <RoadmapCard key={id} item={roadmapItem(id)} />
        ))}
      </ul>
      <div className="lk-landing-more">
        <PressLink to={ROADMAP_PATH[locale]} variant="secondary">
          {t("landing.cta")}
        </PressLink>
      </div>
    </section>
  );
}
