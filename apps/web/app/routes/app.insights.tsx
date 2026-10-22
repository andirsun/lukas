import { createTranslator } from "use-intl/core";
import { Insights } from "../features/insights/Insights.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "insights" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
};

/**
 * `/app/insights`: where the money goes, month by month, and what living costs. Signed in and
 * onboarded: the `/app` layout checks it. Its own chunk (with the charts' code split off again),
 * so home's first load does not carry it.
 */
export default function Route() {
  return <Insights />;
}
