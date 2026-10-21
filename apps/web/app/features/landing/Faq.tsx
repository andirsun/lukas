import { useTranslations } from "use-intl";

/** The questions, in order. `privacy` is also the footer's privacy link target. */
const QUESTIONS = ["what", "budge", "passwords", "privacy", "free", "languages"] as const;

/**
 * Frequently asked questions as native `<details>`: they open and close without JavaScript, and
 * following the footer's `#privacy` link opens the privacy answer (it holds the anchor).
 */
export function Faq() {
  const t = useTranslations("landing.faq");
  return (
    <section id="faq" className="lk-landing-section" aria-labelledby="faq-title">
      <h2 id="faq-title">{t("title")}</h2>
      <ul className="lk-landing-faq">
        {QUESTIONS.map((key) => (
          <li key={key}>
            <details>
              <summary>{t(`${key}.q`)}</summary>
              <p className="lk-landing-answer" id={key === "privacy" ? "privacy" : undefined}>
                {t(`${key}.a`)}
              </p>
            </details>
          </li>
        ))}
      </ul>
    </section>
  );
}
