import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { HeroMascot } from "./HeroMascot.tsx";
import { signInHref } from "./links.ts";

/**
 * The questions people ask about their money, crossed out; then the answer (the headline), the
 * promise, one primary action and Lukas waving.
 */
export function Hero() {
  const t = useTranslations("landing.hero");
  const { locale } = useLocale();
  return (
    <section id="hero" className="lk-landing-hero" aria-labelledby="hero-title">
      <div className="lk-landing-hero-text">
        <ul className="lk-landing-questions">
          <li>
            <s>{t("question_spend")}</s>
          </li>
          <li>
            <s>{t("question_living")}</s>
          </li>
        </ul>
        <h1 id="hero-title" className="lk-landing-headline">
          {t("headline")}
        </h1>
        <p className="lk-landing-tagline">{t("tagline")}</p>
        <p className="lk-landing-description">{t("description")}</p>
        <div className="lk-landing-cta">
          <PressLink to={signInHref(locale)}>{t("cta")}</PressLink>
          <p className="lk-landing-perks">{t("perks")}</p>
        </div>
      </div>
      <HeroMascot />
    </section>
  );
}
