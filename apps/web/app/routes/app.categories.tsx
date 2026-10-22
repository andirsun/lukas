import { createTranslator } from "use-intl/core";
import { CategoriesPage } from "../features/categories/CategoriesPage.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "categories" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
};

/** `/app/categories`: create, edit, archive and restore categories. Signed in and onboarded: the `/app` layout checks it. */
export default function Route() {
  return <CategoriesPage />;
}
