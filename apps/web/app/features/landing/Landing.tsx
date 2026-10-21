import { Link } from "react-router";
import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { Lukas } from "../../lukas/Lukas.tsx";
import { LiveLukasBoundary, useLiveLukasReady } from "../../lukas/live-support.tsx";
import { TravelingLukas as TravelingLukas2D } from "../../lukas/TravelingLukas.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { ThemeToggle } from "../../ui/ThemeToggle.tsx";
import { Faq } from "./Faq.tsx";
import { Footer } from "./Footer.tsx";
import { Hero } from "./Hero.tsx";
import { HowItWorks } from "./HowItWorks.tsx";
import { signInHref } from "./links.ts";
import { OpenSource } from "./OpenSource.tsx";
import { LANDING_PATH } from "./seo.ts";
import { UseItYourWay } from "./UseItYourWay.tsx";
import "./landing.css";

function Header() {
  const t = useTranslations("landing.nav");
  const name = useTranslations("app")("name");
  const { locale } = useLocale();
  return (
    <header className="lk-landing-wrap">
      <div className="lk-landing-header">
        <Link to={LANDING_PATH[locale]} className="lk-landing-logo" aria-label={t("home")}>
          <span className="lk-logo">{name}</span>
        </Link>
        <nav aria-label={t("label")} className="lk-landing-nav">
          <a href="#how" className="lk-landing-link lk-landing-nav-section">
            {t("how")}
          </a>
          <a href="#faq" className="lk-landing-link lk-landing-nav-section">
            {t("faq")}
          </a>
          <PressLink to={signInHref(locale)} variant="secondary" size="sm">
            {t("sign_in")}
          </PressLink>
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}

/**
 * The live, 2.5D Lukas (the founder's sprite sheets plus CSS depth), mounted once the page has
 * loaded and the browser is idle. He stands on the page's Lukas spots (hero → ways → how it works
 * → FAQ → closing) in each spot's mood. Until then, under reduced motion and without JavaScript,
 * the prerendered 2D Lukas in the hero and the closing stays. (The 3D Lukas is an experiment in
 * `app/lukas/experimental/` and never loads here.)
 */
function TravelingLukas() {
  const ready = useLiveLukasReady();
  if (!ready) return null;
  return (
    <LiveLukasBoundary>
      <TravelingLukas2D />
    </LiveLukasBoundary>
  );
}

/** The last nudge, where Lukas lands to celebrate. */
function Closing() {
  const t = useTranslations("landing");
  const { locale } = useLocale();
  return (
    <section id="closing" className="lk-landing-section" aria-labelledby="closing-title">
      <div className="lk-landing-closing">
        <span
          className="lk-landing-spot is-closing"
          data-lukas-spot="closing"
          data-lukas-pose="celebrate"
          data-lukas-mood="celebrating"
          aria-hidden="true"
        >
          <Lukas mood="celebrating" size="100%" decorative deferUntilNear />
        </span>
        <h2 id="closing-title">{t("closing.title")}</h2>
        <p>{t("closing.body")}</p>
        <PressLink to={signInHref(locale)}>{t("hero.cta")}</PressLink>
      </div>
    </section>
  );
}

/**
 * The landing page (`/` in Spanish, `/en` in English), prerendered to static HTML: everything here
 * renders without JavaScript and in the URL's language.
 */
export function Landing() {
  return (
    <div className="lk-screen lk-landing">
      <Header />
      <main className="lk-landing-wrap">
        <Hero />
        <UseItYourWay />
        <HowItWorks />
        <OpenSource />
        <Faq />
        <Closing />
      </main>
      <Footer />
      <TravelingLukas />
    </div>
  );
}
