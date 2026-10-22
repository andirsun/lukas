import { createTranslator } from "use-intl/core";
import { CategoryDetail } from "../features/categories/CategoryDetail.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "categories.detail" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
};

/** `/app/categories/:id`: one category's month (`?month=`): its budget and its transactions. Signed in and onboarded: the `/app` layout checks it. */
export default function Route() {
  return <CategoryDetail />;
}
