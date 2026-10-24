import { useTranslations } from "use-intl";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { PressLink } from "../../ui/PressLink.tsx";
import { APP_VERSION, FEEDBACK_EMAIL, feedbackMailto } from "./feedback.ts";
import { SettingsSection } from "./parts.tsx";

/**
 * "Comentarios e ideas": a button that opens the person's email app with a message to the founder
 * ready to write. The subject says what it is, in the person's language, and the body carries only
 * the version and the language; nothing else of the account goes in it. A browser with no email app
 * does nothing with a `mailto:` link, so the address is also written out under the button.
 */
export function FeedbackSection() {
  const t = useTranslations("settings.feedback");
  const { locale } = useLocale();
  const link = feedbackMailto({
    subject: t("mail_subject"),
    body: `\n\n${t("mail_body", { version: APP_VERSION, language: locale })}`,
  });
  return (
    <SettingsSection title={t("title")} lead={t("lead")}>
      <PressLink to={link} variant="secondary" className="self-start">
        {t("action")}
      </PressLink>
      <p className="m-0 text-[14px] text-ink-muted">{t("address", { email: FEEDBACK_EMAIL })}</p>
    </SettingsSection>
  );
}
