import type { ReactNode } from "react";
import { IntlProvider as UseIntlProvider } from "use-intl";
import { CATALOGS } from "./catalog.ts";
import { reportIntlError, useLocale } from "./IntlProvider.tsx";

/**
 * Gives the app's screens every message, in the locale of the IntlProvider above. The root holds
 * the public pages' messages only, so the landing does not download the app's; the app's layouts
 * (routes/app-layout.tsx, routes/demo.tsx) wrap their screens, fallbacks and error screens in this.
 */
export function AppMessages({ children }: { children: ReactNode }) {
  const { locale } = useLocale();
  return (
    <UseIntlProvider locale={locale} messages={CATALOGS[locale]} onError={reportIntlError}>
      {children}
    </UseIntlProvider>
  );
}
