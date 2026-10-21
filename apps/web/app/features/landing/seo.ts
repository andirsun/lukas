import type { LinkDescriptor, MetaDescriptor } from "react-router";
import { createTranslator } from "use-intl/core";
import type { Locale } from "../../i18n/format.ts";
import en from "../../i18n/messages/en.json" with { type: "json" };
import es from "../../i18n/messages/es.json" with { type: "json" };
import { SITE_ORIGIN } from "../../site/config.ts";
import { LANDING_PATH } from "../../site/paths.ts";

export { LANDING_PATH };

/** The 1200×630 share images rendered by `scripts/og/render.ts`. */
const OG_IMAGE = { width: 1200, height: 630 };

const CATALOGS = { es, en } as const;

/** Absolute URLs use the site's origin (`VITE_SITE_URL`, see `app/site/config.ts`). */
function absolute(path: string): string {
  return `${SITE_ORIGIN}${path}`;
}

/** Title, description and Open Graph / Twitter tags for a landing page. */
export function landingMeta(locale: Locale): MetaDescriptor[] {
  const t = createTranslator({ locale, messages: CATALOGS[locale], namespace: "landing.meta" });
  const title = t("title");
  const description = t("description");
  const url = absolute(LANDING_PATH[locale]);
  const image = absolute(`/og-${locale}.png`);
  return [
    { title },
    { name: "description", content: description },
    { property: "og:type", content: "website" },
    { property: "og:site_name", content: "Lukas" },
    { property: "og:title", content: title },
    { property: "og:description", content: description },
    { property: "og:url", content: url },
    { property: "og:image", content: image },
    { property: "og:image:width", content: String(OG_IMAGE.width) },
    { property: "og:image:height", content: String(OG_IMAGE.height) },
    { property: "og:image:alt", content: t("image_alt") },
    { name: "twitter:card", content: "summary_large_image" },
  ];
}

/**
 * Canonical and `hreflang` alternates (each page lists every language, itself included, plus
 * `x-default` → Spanish), and a preload for the hero's Lukas sprite so it isn't discovered late
 * through CSS.
 */
export function landingLinks(locale: Locale): LinkDescriptor[] {
  return [
    { rel: "canonical", href: absolute(LANDING_PATH[locale]) },
    { rel: "alternate", hrefLang: "es", href: absolute(LANDING_PATH.es) },
    { rel: "alternate", hrefLang: "en", href: absolute(LANDING_PATH.en) },
    { rel: "alternate", hrefLang: "x-default", href: absolute(LANDING_PATH.es) },
    { rel: "preload", as: "image", href: "/lukas/wave.webp", type: "image/webp" },
  ];
}
