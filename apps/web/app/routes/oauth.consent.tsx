import { createTranslator } from "use-intl/core";
import { requireSession } from "../auth/session.ts";
import { Consent } from "../features/assistants/Consent.tsx";
import { liveConsentApi } from "../features/assistants/consent-api.ts";
import { CATALOGS } from "../i18n/catalog.ts";
import type { Route } from "./+types/oauth.consent";

/** The query carries the assistant's state and a signature: this page never sends a referrer. */
export const meta = () => {
  const t = createTranslator({ locale: "es", messages: CATALOGS.es, namespace: "consent" });
  return [
    { title: t("meta_title") },
    { name: "robots", content: "noindex" },
    { name: "referrer", content: "no-referrer" },
  ];
};

/**
 * Signed in only: a visitor who is not goes to sign-in and comes back to this very URL, signed
 * query and all. A failed session check throws to the error boundary.
 */
export async function clientLoader({ request }: Route.ClientLoaderArgs) {
  const url = new URL(request.url);
  const user = await requireSession(`${url.pathname}${url.search}`);
  return { guest: user.isAnonymous === true };
}

/** While the session is checked: the screen's background, nothing to read yet. */
export function HydrateFallback() {
  return <div className="lk-screen min-h-dvh" />;
}

/** `/oauth/consent?client_id&scope&…&sig`: an assistant asks to connect (spec §6.1). */
export default function ConsentRoute({ loaderData }: Route.ComponentProps) {
  return <Consent api={liveConsentApi} guest={loaderData.guest} />;
}
