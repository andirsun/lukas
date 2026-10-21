import { createContext, type ReactNode, useContext, useEffect, useMemo, useState } from "react";
import { useLocation } from "react-router";
import { type AbstractIntlMessages, IntlProvider as UseIntlProvider } from "use-intl";
import { type Locale, localeFromPathname } from "./format.ts";
import en from "./messages/en.json" with { type: "json" };
import es from "./messages/es.json" with { type: "json" };

const MESSAGES: Record<Locale, AbstractIntlMessages> = { es, en };

interface LocaleContextValue {
  locale: Locale;
  /** Overrides the URL-derived locale until the URL's own locale changes. */
  setLocale: (locale: Locale) => void;
}

const LocaleContext = createContext<LocaleContextValue | null>(null);

/**
 * Provides the active locale and its ICU messages. Public pages derive the locale from the URL
 * (`/en/...` is English); `setLocale` lets later features (the profile setting) take over.
 * Keeps `<html lang>` in sync after hydration, since the prerendered fallback is Spanish.
 */
export function IntlProvider({ children }: { children: ReactNode }) {
  const { pathname } = useLocation();
  const urlLocale = localeFromPathname(pathname);
  const [override, setOverride] = useState<{ locale: Locale; urlLocale: Locale } | null>(null);
  const locale = override && override.urlLocale === urlLocale ? override.locale : urlLocale;

  useEffect(() => {
    document.documentElement.lang = locale;
  }, [locale]);

  const value = useMemo<LocaleContextValue>(
    () => ({ locale, setLocale: (next) => setOverride({ locale: next, urlLocale }) }),
    [locale, urlLocale],
  );

  return (
    <LocaleContext.Provider value={value}>
      <UseIntlProvider locale={locale} messages={MESSAGES[locale]}>
        {children}
      </UseIntlProvider>
    </LocaleContext.Provider>
  );
}

export function useLocale(): LocaleContextValue {
  const value = useContext(LocaleContext);
  if (!value) throw new Error("useLocale must be used inside <IntlProvider>");
  return value;
}
