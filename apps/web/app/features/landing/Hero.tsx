import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { COMING_SOON } from "../../site/config.ts";
import { cx } from "../../ui/cx.ts";
import { PressLink } from "../../ui/PressLink.tsx";
import { HeroMascot } from "./HeroMascot.tsx";
import { appLinkProps, demoLinkProps } from "./links.ts";
import { MoneyHeadline } from "./MoneyHeadline.tsx";
import { NewTabHint } from "./NewTabHint.tsx";
import { CodeLink } from "./OpenSource.tsx";

/**
 * The headline with "lukas" on a gold marker (in Spanish, taking turns with what money is called elsewhere), what Lukas is, one primary action and "Pruébalo sin cuenta" (the demo) beside it, with
 * the perks under them, and Lukas waving. Without an app to open (landing-only, coming soon) there
 * is no demo either, so only the primary action shows.
 */
export function Hero() {
  const t = useTranslations("landing.hero");
  const { locale } = useLocale();
  const app = appLinkProps(locale);
  const demo = demoLinkProps(locale);
  return (
    <section id="hero" className="lk-landing-hero" aria-labelledby="hero-title">
      <div className="lk-landing-hero-text">
        {locale === "es" ? (
          <MoneyHeadline />
        ) : (
          <h1 id="hero-title" className="lk-landing-headline">
            {t.rich("headline", {
              mark: (chunks) => <span className="lk-landing-marker">{chunks}</span>,
            })}
          </h1>
        )}
        <p className="lk-landing-description">
          {t.rich("description", {
            lead: (chunks) => <span className="lk-landing-lead">{chunks}</span>,
          })}
        </p>
        <div className="lk-landing-cta">
          <div className="lk-landing-cta-actions">
            <PressLink {...app} className={cx(COMING_SOON && "is-soon")}>
              {t(COMING_SOON ? "cta_soon" : "cta")}
              <NewTabHint target={app.target} />
            </PressLink>
            {demo && (
              <PressLink {...demo} variant="secondary">
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
