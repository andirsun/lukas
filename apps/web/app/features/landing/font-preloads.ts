// The fonts the landing paints above the fold, preloaded so they arrive before the first paint
// instead of swapping in after it. Where the fallback's metrics differ (Linux, Android), a late
// swap moves the hero and counts as layout shift. Same files as `app/styles/fonts.ts`, so Vite
// emits one asset per font and the preload is the request the @font-face rule then uses.
import fredoka600 from "@fontsource/fredoka/files/fredoka-latin-600-normal.woff2?url";
import fredoka700 from "@fontsource/fredoka/files/fredoka-latin-700-normal.woff2?url";
import nunito700 from "@fontsource/nunito/files/nunito-latin-700-normal.woff2?url";
import nunito800 from "@fontsource/nunito/files/nunito-latin-800-normal.woff2?url";

export const LANDING_FONTS = [fredoka700, fredoka600, nunito700, nunito800];

/** `<link rel="preload">` for each landing font (fonts need `crossorigin`, even on the same origin). */
export const landingFontPreloads = () =>
  LANDING_FONTS.map((href) => ({
    rel: "preload",
    as: "font",
    type: "font/woff2",
    href,
    crossOrigin: "anonymous" as const,
  }));
