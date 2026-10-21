import type { MetaDescriptor } from "react-router";
import { createTranslator } from "use-intl/core";
import en from "../../i18n/messages/en.json" with { type: "json" };
import es from "../../i18n/messages/es.json" with { type: "json" };
import { langFrom } from "./auth.ts";

/** The tab title of a sign-in screen, in the language of `?lang=` (Spanish by default). Not indexed. */
export function signInMeta(screen: "sign_in" | "verify", search: string): MetaDescriptor[] {
  const locale = langFrom(new URLSearchParams(search).get("lang")) ?? "es";
  const t = createTranslator({ locale, messages: locale === "en" ? en : es, namespace: screen });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
}
