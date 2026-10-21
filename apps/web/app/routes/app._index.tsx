import { createTranslator } from "use-intl/core";
import { Home } from "../features/home/Home.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "home" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
};

/** `/app`: home. */
export default function HomeRoute() {
  return <Home />;
}
