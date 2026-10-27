import { Link } from "react-router";
import { useTranslations } from "use-intl";
import { createTranslator } from "use-intl/core";
import { intlTag, LOCALES, type Locale } from "../../i18n/format.ts";
import en from "../../i18n/messages/en.json" with { type: "json" };
import es from "../../i18n/messages/es.json" with { type: "json" };
import it from "../../i18n/messages/it.json" with { type: "json" };
import pt from "../../i18n/messages/pt.json" with { type: "json" };
import { Lukas } from "../../lukas/Lukas.tsx";
import { LANDING_PATH } from "../../site/paths.ts";
import { PressLink } from "../../ui/PressLink.tsx";
import { ThemeToggle } from "../../ui/ThemeToggle.tsx";
import "./landing.css";

const CATALOGS = { es, en, it, pt } as const;

/** The page's tags: titled in every language and kept out of search results. */
export const notFoundMeta = () => [
  { title: "Lukitas · 404" },
  { name: "robots", content: "noindex" },
];

function Message({ locale, primary }: { locale: Locale; primary: boolean }) {
  const t = createTranslator({
    locale: intlTag(locale),
    messages: CATALOGS[locale],
    namespace: "landing.not_found",
  });
  const Heading = primary ? "h1" : "h2";
  return (
    <div className="lk-landing-notfound-message" lang={locale}>
      <Heading>{t("title")}</Heading>
      <p>{t("body")}</p>
      <PressLink to={LANDING_PATH[locale]} variant={primary ? "primary" : "secondary"}>
        {t("home")}
      </PressLink>
    </div>
  );
}

/**
 * The page for any path that is not the landing, in the landing look. It speaks all four languages
 * (an unknown path says nothing about which one the visitor reads), each with a link to its own
 * home. Prerendered to `404.html` in the landing-only release, which Cloudflare
 * Pages serves for unknown paths.
 */
export function NotFound() {
  const name = useTranslations("app")("name");
  const t = useTranslations("landing.not_found");
  return (
    <div className="lk-screen lk-landing">
      <header className="lk-landing-wrap">
        <div className="lk-landing-header">
          <Link to={LANDING_PATH.es} className="lk-landing-logo" aria-label={`${name}, inicio`}>
            <span className="lk-logo">{name}</span>
          </Link>
          <nav className="lk-landing-nav">
            <ThemeToggle />
          </nav>
        </div>
      </header>
      <main className="lk-landing-wrap lk-landing-notfound">
        <div className="lk-landing-notfound-lukas" role="img" aria-label={t("mascot")}>
          <Lukas mood="worried" size="100%" decorative />
        </div>
        {LOCALES.map((locale) => (
          <Message key={locale} locale={locale} primary={locale === "es"} />
        ))}
      </main>
    </div>
  );
}
