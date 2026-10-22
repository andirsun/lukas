import { createTranslator } from "use-intl/core";
import { Settings } from "../features/settings/Settings.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "settings" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
};

/**
 * `/app/settings`: language, theme, sound, time zone, currency, passkeys, import, export and
 * deleting the account. Signed in and onboarded: the `/app` layout checks it.
 */
export default function Route() {
  return <Settings />;
}
