import { useTranslations } from "use-intl";

/**
 * For a link that opens a new tab: a visually hidden hint after its text, so a screen reader says
 * so before the person activates it. Renders nothing for any other link (`target` is the link's).
 */
export function NewTabHint({ target }: { target?: string }) {
  const t = useTranslations("landing");
  if (target !== "_blank") return null;
  return <span className="sr-only">{` ${t("new_tab")}`}</span>;
}
