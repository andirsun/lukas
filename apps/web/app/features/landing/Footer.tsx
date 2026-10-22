import { Link } from "react-router";
import { useTranslations } from "use-intl";
import type { Locale } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { LANDING_PATH, PAGE_PATH, ROADMAP_PATH, type SitePage } from "../../site/paths.ts";
import { COPYRIGHT_YEAR, PRIVACY_HREF } from "./links.ts";

const LOCALES: Locale[] = ["es", "en"];

/**
 * Language switch (the same page in the other language), the roadmap and privacy links and the
 * copyright. The active language is marked `aria-current="true"` (a filled pill) and the current
 * page `aria-current="page"` (the gold underline), so the two never look alike. `page` is the page
 * it sits on (the landing by default): the language switch keeps it, and on the roadmap the privacy
 * link leads to the landing's answer.
 */
export function Footer({ page = "landing" }: { page?: SitePage }) {
  const t = useTranslations();
  const { locale } = useLocale();
  return (
    <footer className="lk-landing-wrap">
      <div className="lk-landing-footer">
        <span className="lk-logo">{t("app.name")}</span>
        <div className="lk-landing-footer-links">
          <nav aria-label={t("landing.footer.language")}>
            <ul className="lk-landing-langs">
              {LOCALES.map((option) => (
                <li key={option}>
                  <Link
                    to={PAGE_PATH[page][option]}
                    className="lk-landing-link"
                    lang={option}
                    hrefLang={option}
                    aria-current={option === locale ? "true" : undefined}
                  >
                    {t(`language.${option}`)}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
          <Link
            to={ROADMAP_PATH[locale]}
            className="lk-landing-link"
            aria-current={page === "roadmap" ? "page" : undefined}
          >
            {t("landing.footer.roadmap")}
          </Link>
          <a
            href={page === "landing" ? PRIVACY_HREF : `${LANDING_PATH[locale]}${PRIVACY_HREF}`}
            className="lk-landing-link"
          >
            {t("landing.footer.privacy")}
          </a>
        </div>
        <p className="lk-landing-copyright">
          {t("landing.footer.copyright", { year: String(COPYRIGHT_YEAR) })}
        </p>
      </div>
    </footer>
  );
}
