import type { ReactNode } from "react";
import { useTranslations } from "use-intl";
import { PressLink } from "../../ui/PressLink.tsx";
import { GITHUB_HREF } from "./links.ts";

/** A text link to the source code on GitHub, opened in a new tab. */
export function CodeLink({ className, children }: { className?: string; children: ReactNode }) {
  return (
    <a href={GITHUB_HREF} target="_blank" rel="noopener" className={className}>
      {children}
    </a>
  );
}

/**
 * Lukas is open source: anyone can read the code (AGPL-3.0). One short paragraph and a link to
 * the repository, right before the FAQ.
 */
export function OpenSource() {
  const t = useTranslations("landing.open_source");
  return (
    <section id="open-source" className="lk-landing-section" aria-labelledby="open-source-title">
      <div className="lk-landing-card lk-landing-open">
        <span className="lk-landing-icon is-good" aria-hidden="true">
          <svg viewBox="0 0 24 24">
            <path d="M8.5 7 3.5 12l5 5M15.5 7l5 5-5 5M13.5 4.5l-3 15" />
          </svg>
        </span>
        <div className="lk-landing-open-text">
          <h2 id="open-source-title">{t("title")}</h2>
          <p>{t("body")}</p>
        </div>
        <PressLink to={GITHUB_HREF} target="_blank" rel="noopener" variant="secondary">
          {t("cta")}
        </PressLink>
      </div>
    </section>
  );
}
