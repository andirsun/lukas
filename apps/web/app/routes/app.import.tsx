import { createTranslator } from "use-intl/core";
import { requireOnboarded } from "../auth/session.ts";
import { ImportPage } from "../features/onboarding/ImportPage.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };
import type { Route } from "./+types/app.import";

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "onboarding.import" });
  return [{ title: `${t("page_title")} · Lukitas` }, { name: "robots", content: "noindex" }];
};

/** Signed in and onboarded (the `/app` layout checks it too; this keeps the route safe alone). */
export async function clientLoader({ request }: Route.ClientLoaderArgs) {
  await requireOnboarded(new URL(request.url).pathname);
  return null;
}

/** `/app/import`: bring a history from another app, after onboarding. */
export default function ImportRoute() {
  return <ImportPage />;
}
