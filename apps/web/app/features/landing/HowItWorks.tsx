import type { CSSProperties, ReactNode } from "react";
import { useTranslations } from "use-intl";
import { formatMoney } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { Lukas } from "../../lukas/Lukas.tsx";

/** Sample figures for the illustrations (cents, euros). */
const DEMO = {
  expense: -320,
  groceries: { remaining: 4633, filled: "62%" },
  goingOut: { remaining: 800, filled: "91%" },
  importedRows: 1248,
} as const;

function Step({ demo, title, body }: { demo: ReactNode; title: string; body: string }) {
  return (
    <li className="lk-landing-card">
      {/* The illustration repeats what the text says, so it is hidden from assistive technology. */}
      <div className="lk-landing-demo" aria-hidden="true">
        {demo}
      </div>
      <h3>{title}</h3>
      <p>{body}</p>
    </li>
  );
}

/**
 * How Lukas works, in four steps, each with a small illustration built from the app's own
 * pieces: logging in seconds, where the money goes, budgets that warn you, importing your history
 * from other apps (Budge today).
 */
export function HowItWorks() {
  const t = useTranslations("landing.how");
  const { locale } = useLocale();
  const money = (cents: number) => formatMoney(cents, "EUR", locale);
  const dot = (color: string) => ({ "--dot": color }) as CSSProperties;

  return (
    <section id="how" className="lk-landing-section" aria-labelledby="how-title">
      <h2 id="how-title">{t("title")}</h2>
      <ul className="lk-landing-cards is-how">
        <Step
          title={t("log.title")}
          body={t("log.body")}
          demo={
            <>
              <div className="lk-landing-demo-row">
                <span className="lk-tile">☕</span>
                <span className="lk-landing-demo-name">{t("log.demo_name")}</span>
                <span className="lk-amount lk-landing-demo-expense">{money(DEMO.expense)}</span>
              </div>
              <span className="lk-landing-saved">
                <Lukas mood="celebrating" size={40} decorative />
                {t("log.demo_saved")}
              </span>
            </>
          }
        />
        <Step
          title={t("spend.title")}
          body={t("spend.body")}
          demo={
            <div className="lk-landing-demo-row">
              <span className="lk-landing-donut" />
              <div className="grid gap-(--space-2)">
                <span className="lk-overline">{t("spend.demo_label")}</span>
                <ul className="lk-landing-legend">
                  <li style={dot("var(--candy)")}>{t("demo_categories.groceries")}</li>
                  <li style={dot("var(--brand-glow)")}>{t("demo_categories.home")}</li>
                  <li style={dot("var(--near)")}>{t("demo_categories.going_out")}</li>
                  <li style={dot("var(--good)")}>{t("demo_categories.transport")}</li>
                </ul>
              </div>
            </div>
          }
        />
        <Step
          title={t("budgets.title")}
          body={t("budgets.body")}
          demo={
            <>
              <div className="lk-landing-budget">
                <div className="lk-rowtop">
                  <span>{t("demo_categories.groceries")}</span>
                  <span className="lk-status">
                    {t("budgets.demo_remaining", { amount: money(DEMO.groceries.remaining) })}
                  </span>
                </div>
                <div className="lk-bar">
                  <span style={{ width: DEMO.groceries.filled }} />
                </div>
              </div>
              <div className="lk-landing-budget">
                <div className="lk-rowtop">
                  <span>{t("demo_categories.going_out")}</span>
                  <span className="lk-status is-near">
                    {t("budgets.demo_remaining", { amount: money(DEMO.goingOut.remaining) })}
                  </span>
                </div>
                <div className="lk-bar is-near">
                  <span style={{ width: DEMO.goingOut.filled }} />
                </div>
              </div>
            </>
          }
        />
        <Step
          title={t("import.title")}
          body={t("import.body")}
          demo={
            <div className="lk-landing-demo-row flex-wrap">
              <span className="lk-landing-file">{t("import.demo_file")}</span>
              <svg className="lk-landing-arrow" viewBox="0 0 24 24">
                <path d="M4 12h15M13 6l6 6-6 6" />
              </svg>
              <span className="lk-landing-imported">
                {t("import.demo_rows", { count: DEMO.importedRows })}
              </span>
            </div>
          }
        />
      </ul>
    </section>
  );
}
