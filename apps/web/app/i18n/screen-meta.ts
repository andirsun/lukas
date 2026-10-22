import { createTranslator } from "use-intl/core";
import { demoLocale } from "../demo/demo-locale.ts";
import { CATALOGS } from "./catalog.ts";
import type { Locale } from "./format.ts";

/** Whether a path is one of the demo's screens. */
export const isDemoPath = (pathname: string) =>
  pathname === "/demo" || pathname.startsWith("/demo/");

/**
 * The `<title>` (and `noindex`) of one of the app's screens, from its catalog namespace's
 * `meta_title`. The app's titles are Spanish (as they always were). The demo reuses the same route
 * modules: there the title is in the demo's language and says it is the demo ("Demo · Home ·
 * Lukitas").
 */
export function screenMeta(namespace: string, location: { pathname: string; search: string }) {
  const demo = isDemoPath(location.pathname);
  const locale: Locale = demo ? demoLocale(location.search) : "es";
  const t = createTranslator({ locale, messages: CATALOGS[locale] }) as unknown as (
    key: string,
    values?: Record<string, string>,
  ) => string;
  const screen = t(`${namespace}.meta_title`);
  const title = demo ? t("demo.meta_title_screen", { screen }) : screen;
  return [{ title }, { name: "robots", content: "noindex" }];
}

/** The demo layout's own title ("Demo · Lukitas"), in the demo's language, while a screen loads. */
export function demoMeta(location: { search: string }) {
  const locale = demoLocale(location.search);
  const t = createTranslator({ locale, messages: CATALOGS[locale], namespace: "demo" });
  return [{ title: t("meta_title") }, { name: "robots", content: "noindex" }];
}
