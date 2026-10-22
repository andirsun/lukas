import appEn from "./messages/app.en.json" with { type: "json" };
import appEs from "./messages/app.es.json" with { type: "json" };
import en from "./messages/en.json" with { type: "json" };
import es from "./messages/es.json" with { type: "json" };

/**
 * Every message, per locale. The catalogs come in two parts: `es.json`/`en.json` hold what the
 * public pages say (the landing, the roadmap, the theme and language switches, Lukas' name), and
 * `app.es.json`/`app.en.json` everything else. The landing and roadmap ship the first part only
 * (IntlProvider); the app's screens (sign-in, welcome, /app, the demo) import this module, which
 * adds the second (`AppMessages`). A namespace lives in exactly one part (messages.test.ts).
 */
export const CATALOGS = {
  es: { ...es, ...appEs },
  en: { ...en, ...appEn },
} as const;
