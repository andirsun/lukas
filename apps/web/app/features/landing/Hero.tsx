import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { LANDING_ONLY } from "../../site/config.ts";
import { cx } from "../../ui/cx.ts";
import { PressLink } from "../../ui/PressLink.tsx";
import { HeroMascot } from "./HeroMascot.tsx";
import { appLinkProps, DEMO_PATH } from "./links.ts";
import { NewTabHint } from "./NewTabHint.tsx";
import { CodeLink } from "./OpenSource.tsx";

export type HeroProps = {
  /**
   * Also offer "Pruébalo sin cuenta" → the demo, as a secondary action. Off until the demo exists
   * (Task 18a turns it on).
   */
  secondaryCta?: boolean;
};

/**
 * A handwritten promise (free, and it always will be), the headline with "lukas" on a gold
 * marker, what Lukas is, one primary action with the perks under it, and Lukas waving.
 */
export function Hero({ secondaryCta = false }: HeroProps) {
  const t = useTranslations("landing.hero");
  const { locale } = useLocale();
  const app = appLinkProps(locale);
  return (
    <section id="hero" className="lk-landing-hero" aria-labelledby="hero-title">
      <div className="lk-landing-hero-text">
        <p className="lk-landing-annotation">{t("annotation")}</p>
        <h1 id="hero-title" className="lk-landing-headline">
          {t.rich("headline", {
            mark: (chunks) => <span className="lk-landing-marker">{chunks}</span>,
          })}
        </h1>
        <p className="lk-landing-description">
          {t.rich("description", {
            lead: (chunks) => <span className="lk-landing-lead">{chunks}</span>,
          })}
        </p>
        <div className="lk-landing-cta">
          <div className="lk-landing-cta-actions">
            <PressLink {...app} className={cx(LANDING_ONLY && "is-soon")}>
              {t(LANDING_ONLY ? "cta_soon" : "cta")}
              <NewTabHint target={app.target} />
            </PressLink>
            {secondaryCta && (
              <PressLink to={DEMO_PATH} variant="secondary">
                {t("cta_demo")}
              </PressLink>
            )}
          </div>
          <p className="lk-landing-perks">
            {t.rich("perks", { github: (chunks) => <CodeLink>{chunks}</CodeLink> })}
          </p>
        </div>
      </div>
      <HeroMascot />
    </section>
  );
}
