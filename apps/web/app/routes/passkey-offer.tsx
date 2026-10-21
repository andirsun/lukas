import { createTranslator } from "use-intl/core";
import { DEFAULT_NEXT } from "../auth/next.ts";
import { requireSession } from "../auth/session.ts";
import { livePasskeyOffer, PasskeyOffer } from "../features/sign-in/PasskeyOffer.tsx";
import es from "../i18n/messages/es.json" with { type: "json" };
import type { Route } from "./+types/passkey-offer";

export const meta = () => {
  const t = createTranslator({ locale: "es", messages: es, namespace: "passkey_offer" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
};

/**
 * Signed in only: the offer is for someone who just signed in with their email. (A visitor who
 * is not goes to sign-in and, afterwards, to the app.) A failed session check throws to the
 * error boundary.
 */
export async function clientLoader() {
  const user = await requireSession(DEFAULT_NEXT);
  return { userId: user.id };
}

/** While the session is checked: the screen's background, nothing to read yet. */
export function HydrateFallback() {
  return <div className="lk-screen min-h-dvh" />;
}

/** `/passkey-offer?next=…`: "¿Entrar con tu huella la próxima vez?" (after an email sign-in). */
export default function PasskeyOfferRoute({ loaderData }: Route.ComponentProps) {
  return <PasskeyOffer offer={livePasskeyOffer} userId={loaderData.userId} />;
}
