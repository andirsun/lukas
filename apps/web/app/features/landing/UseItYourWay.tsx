import type { ReactNode } from "react";
import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { cx } from "../../ui/cx.ts";
import { PressLink } from "../../ui/PressLink.tsx";
import { LukasSpot } from "./LukasSpot.tsx";
import { signInHref } from "./links.ts";

function Icon({ tone, children }: { tone: "gold" | "candy" | "good"; children: ReactNode }) {
  return (
    <span className={cx("lk-landing-icon", `is-${tone}`)} aria-hidden="true">
      <svg viewBox="0 0 24 24">{children}</svg>
    </span>
  );
}

/**
 * Where Lukas lives: the web app today ("Empezar"), the Android and iOS app and your AI assistant
 * (Claude or ChatGPT, through MCP) marked as coming soon.
 */
export function UseItYourWay() {
  const t = useTranslations("landing.ways");
  const { locale } = useLocale();
  return (
    <section id="ways" className="lk-landing-section" aria-labelledby="ways-title">
      <div className="lk-landing-section-head">
        <h2 id="ways-title">{t("title")}</h2>
        <LukasSpot id="ways" pose="point" />
      </div>
      <ul className="lk-landing-cards is-ways">
        <li className="lk-landing-card is-live">
          <div className="lk-landing-card-head">
            <Icon tone="good">
              <circle cx="12" cy="12" r="9" />
              <path d="M3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3z" />
            </Icon>
            <h3>{t("web.title")}</h3>
          </div>
          <p>{t("web.body")}</p>
          <div className="lk-landing-card-foot">
            <PressLink to={signInHref(locale)} variant="secondary" size="sm">
              {t("web.cta")}
            </PressLink>
          </div>
        </li>
        <li className="lk-landing-card">
          <div className="lk-landing-card-head">
            <Icon tone="candy">
              <rect x="6.5" y="2.5" width="11" height="19" rx="2.5" />
              <path d="M11 18h2" />
            </Icon>
            <h3>{t("mobile.title")}</h3>
          </div>
          <p>{t("mobile.body")}</p>
          <div className="lk-landing-card-foot">
            <span className="lk-landing-soon">{t("soon")}</span>
          </div>
        </li>
        <li className="lk-landing-card">
          <div className="lk-landing-card-head">
            <Icon tone="gold">
              <path d="M11 3c.6 4.6 2.4 6.4 7 7-4.6.6-6.4 2.4-7 7-.6-4.6-2.4-6.4-7-7 4.6-.6 6.4-2.4 7-7z" />
              <path d="M19 14.5c.3 1.6.9 2.2 2.5 2.5-1.6.3-2.2.9-2.5 2.5-.3-1.6-.9-2.2-2.5-2.5 1.6-.3 2.2-.9 2.5-2.5z" />
            </Icon>
            <div>
              <h3>{t("ai.title")}</h3>
              <span className="lk-landing-with">{t("ai.with")}</span>
            </div>
          </div>
          <p>{t("ai.body")}</p>
          <div className="lk-landing-card-foot">
            <span className="lk-landing-soon">{t("soon")}</span>
          </div>
        </li>
      </ul>
    </section>
  );
}
