import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { Lukas } from "../../lukas/Lukas.tsx";
import { LiveLukasBoundary, useLiveLukasReady } from "../../lukas/live-support.tsx";
import { TravelingLukas as TravelingLukas2D } from "../../lukas/TravelingLukas.tsx";
import { APP_ORIGIN, COMING_SOON } from "../../site/config.ts";
import { cx } from "../../ui/cx.ts";
import { PressLink } from "../../ui/PressLink.tsx";
import { WhatsNext } from "../roadmap/WhatsNext.tsx";
import { Faq } from "./Faq.tsx";
import { Footer } from "./Footer.tsx";
import { Hero } from "./Hero.tsx";
import { HowItWorks } from "./HowItWorks.tsx";
import { appLinkProps } from "./links.ts";
import { NewTabHint } from "./NewTabHint.tsx";
import { OpenSource } from "./OpenSource.tsx";
import { SiteHeader } from "./SiteHeader.tsx";
import { UseItYourWay } from "./UseItYourWay.tsx";
import "./landing.css";

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
  const app = appLinkProps(locale);
  // Honest about where the app is: not open yet, open to a small group, or open to everyone.
  const closingBody = COMING_SOON
    ? "closing.body_soon"
    : APP_ORIGIN
      ? "closing.body_invite"
      : "closing.body";
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
        <p>{t(closingBody)}</p>
        <PressLink {...app} className={cx(COMING_SOON && "is-soon")}>
          {t(COMING_SOON ? "hero.cta_soon" : "hero.cta")}
          <NewTabHint target={app.target} />
        </PressLink>
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
      <SiteHeader page="landing" />
      <main className="lk-landing-wrap">
        <Hero />
        <UseItYourWay />
        <HowItWorks />
        <OpenSource />
        <WhatsNext />
        <Faq />
        <Closing />
      </main>
      <Footer />
      <TravelingLukas />
    </div>
  );
}
