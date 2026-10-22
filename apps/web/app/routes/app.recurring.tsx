import { createTranslator } from "use-intl/core";
import { RecurringPage } from "../features/recurring/RecurringPage.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "recurring" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
};

/** `/app/recurring`: the recurring transactions, with their next date. Signed in and onboarded: the `/app` layout checks it. */
export default function Route() {
  return <RecurringPage />;
}
