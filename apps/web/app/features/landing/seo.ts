import type { LinkDescriptor, MetaDescriptor } from "react-router";
import { createTranslator } from "use-intl/core";
import type { Locale } from "../../i18n/format.ts";
import en from "../../i18n/messages/en.json" with { type: "json" };
import es from "../../i18n/messages/es.json" with { type: "json" };
import { SITE_ORIGIN } from "../../site/config.ts";
import { LANDING_PATH, PAGE_PATH, ROADMAP_PATH, type SitePage } from "../../site/paths.ts";
import { landingFontPreloads } from "./font-preloads.ts";

export { LANDING_PATH };

/** The 1200×630 share images rendered by `scripts/og/render.ts`. */
const OG_IMAGE = { width: 1200, height: 630 };

// Italian and Portuguese read Spanish until their catalogs land (spec §2.2).
const CATALOGS = { es, en, it: es, pt: es } as const;

/** Absolute URLs use the site's origin (`VITE_SITE_URL`, see `app/site/config.ts`). */
function absolute(path: string): string {
  return `${SITE_ORIGIN}${path}`;
}

interface PageTags {
  locale: Locale;
  path: string;
  title: string;
  description: string;
  imageAlt: string;
}

/** Title, description and Open Graph / Twitter tags of a public page. */
function pageMeta({ locale, path, title, description, imageAlt }: PageTags): MetaDescriptor[] {
  const url = absolute(path);
  const image = absolute(`/og-${locale}.png`);
  return [
    { title },
    { name: "description", content: description },
    { property: "og:type", content: "website" },
    { property: "og:site_name", content: "Lukitas" },
    { property: "og:title", content: title },
    { property: "og:description", content: description },
    { property: "og:url", content: url },
    { property: "og:image", content: image },
    { property: "og:image:width", content: String(OG_IMAGE.width) },
    { property: "og:image:height", content: String(OG_IMAGE.height) },
    { property: "og:image:alt", content: imageAlt },
    { name: "twitter:card", content: "summary_large_image" },
  ];
}

/** Canonical and `hreflang` alternates of a public page: every language, itself included, plus `x-default` → Spanish. */
function pageLinks(page: SitePage, locale: Locale): LinkDescriptor[] {
  const paths = PAGE_PATH[page];
  return [
    { rel: "canonical", href: absolute(paths[locale]) },
    { rel: "alternate", hrefLang: "es", href: absolute(paths.es) },
    { rel: "alternate", hrefLang: "en", href: absolute(paths.en) },
    { rel: "alternate", hrefLang: "x-default", href: absolute(paths.es) },
  ];
}

/** Title, description and Open Graph / Twitter tags for a landing page. */
export function landingMeta(locale: Locale): MetaDescriptor[] {
  const t = createTranslator({ locale, messages: CATALOGS[locale], namespace: "landing.meta" });
  return pageMeta({
    locale,
    path: LANDING_PATH[locale],
    title: t("title"),
    description: t("description"),
    imageAlt: t("image_alt"),
  });
}

/**
 * Canonical and `hreflang` alternates (each page lists every language, itself included, plus
 * `x-default` → Spanish), and a preload for the hero's Lukas sprite so it isn't discovered late
 * through CSS.
 */
export function landingLinks(locale: Locale): LinkDescriptor[] {
  return [
    ...pageLinks("landing", locale),
    ...landingFontPreloads(),
    { rel: "preload", as: "image", href: "/lukas/wave.webp", type: "image/webp" },
  ];
}

/**
 * The roadmap page's own title and description. It shares the landing's 1200×630 share image (and
 * its alt text, which describes that image).
 */
export function roadmapMeta(locale: Locale): MetaDescriptor[] {
  const messages = CATALOGS[locale];
  const t = createTranslator({ locale, messages, namespace: "roadmap.meta" });
  const image = createTranslator({ locale, messages, namespace: "landing.meta" });
  return pageMeta({
    locale,
    path: ROADMAP_PATH[locale],
    title: t("title"),
    description: t("description"),
    imageAlt: image("image_alt"),
  });
}

/** Canonical and `hreflang` alternates of the roadmap page. */
export function roadmapLinks(locale: Locale): LinkDescriptor[] {
  return [...pageLinks("roadmap", locale), ...landingFontPreloads()];
}
