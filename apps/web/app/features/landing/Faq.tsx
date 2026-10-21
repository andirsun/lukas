import { useTranslations } from "use-intl";
import { LukasSpot } from "./LukasSpot.tsx";
import { CodeLink } from "./OpenSource.tsx";

/** The questions, in order. `privacy` is also the footer's privacy link target. */
const QUESTIONS = ["what", "import", "passwords", "privacy", "free", "languages"] as const;

/**
 * Frequently asked questions as native `<details>`: they open and close without JavaScript, and
 * following the footer's `#privacy` link opens the privacy answer (it holds the anchor). An answer
 * can link to the source code (`<github>GitHub</github>` in the catalog).
 */
export function Faq() {
  const t = useTranslations("landing.faq");
  return (
    <section id="faq" className="lk-landing-section" aria-labelledby="faq-title">
      <div className="lk-landing-section-head">
        <h2 id="faq-title">{t("title")}</h2>
        <LukasSpot id="faq" pose="point" />
      </div>
      <ul className="lk-landing-faq">
        {QUESTIONS.map((key) => (
          <li key={key}>
            <details>
              <summary>{t(`${key}.q`)}</summary>
              <p className="lk-landing-answer" id={key === "privacy" ? "privacy" : undefined}>
                {t.rich(`${key}.a`, { github: (chunks) => <CodeLink>{chunks}</CodeLink> })}
              </p>
            </details>
          </li>
        ))}
      </ul>
    </section>
  );
}
