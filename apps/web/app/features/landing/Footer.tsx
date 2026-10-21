import { Link } from "react-router";
import { useTranslations } from "use-intl";
import type { Locale } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { COPYRIGHT_YEAR, PRIVACY_HREF } from "./links.ts";
import { LANDING_PATH } from "./seo.ts";

const LOCALES: Locale[] = ["es", "en"];

/** Language switch (the same page in the other language), the privacy link and the copyright. */
export function Footer() {
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
                    to={LANDING_PATH[option]}
                    className="lk-landing-link"
                    lang={option}
                    hrefLang={option}
                    aria-current={option === locale ? "page" : undefined}
                  >
                    {t(`language.${option}`)}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
          <a href={PRIVACY_HREF} className="lk-landing-link">
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
