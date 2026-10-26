import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { useLocation } from "react-router";
import {
  type AbstractIntlMessages,
  type IntlError,
  IntlErrorCode,
  IntlProvider as UseIntlProvider,
} from "use-intl";
import { type Locale, localeFromPathname } from "./format.ts";
import en from "./messages/en.json" with { type: "json" };
import es from "./messages/es.json" with { type: "json" };

/**
 * The public pages' messages (the landing, the roadmap, the switches in their header and footer).
 * The app's screens add the rest with `AppMessages` (catalog.ts), so visitors of the landing do
 * not download them.
 */
// Italian and Portuguese read Spanish until their catalogs land (spec §2.2).
const MESSAGES: Record<Locale, AbstractIntlMessages> = { es, en, it: es, pt: es };

interface LocaleContextValue {
  locale: Locale;
  /** Overrides the URL-derived locale until the URL's own locale changes. */
  setLocale: (locale: Locale) => void;
}

const LocaleContext = createContext<LocaleContextValue | null>(null);

/**
 * use-intl's default reporting (console.error), minus one expected case: while prerendering there
 * is no visitor time zone, and the public pages format no dates, so its server-only "no timeZone
 * configured" fallback warning is noise in the build output.
 */
export function reportIntlError(error: IntlError) {
  if (error.code === IntlErrorCode.ENVIRONMENT_FALLBACK && typeof window === "undefined") return;
  console.error(error);
}

function IntlRoot({ locale, setLocale, children }: LocaleContextValue & { children: ReactNode }) {
  useEffect(() => {
    document.documentElement.lang = locale;
  }, [locale]);

  const value = useMemo<LocaleContextValue>(() => ({ locale, setLocale }), [locale, setLocale]);

  return (
    <LocaleContext.Provider value={value}>
      <UseIntlProvider locale={locale} messages={MESSAGES[locale]} onError={reportIntlError}>
        {children}
      </UseIntlProvider>
    </LocaleContext.Provider>
  );
}

function UrlIntlProvider({ children }: { children: ReactNode }) {
  const { pathname } = useLocation();
  const urlLocale = localeFromPathname(pathname);
  const [override, setOverride] = useState<{ locale: Locale; urlLocale: Locale } | null>(null);
  const locale = override && override.urlLocale === urlLocale ? override.locale : urlLocale;
  const setLocale = useCallback(
    (next: Locale) => setOverride({ locale: next, urlLocale }),
    [urlLocale],
  );

  return (
    <IntlRoot locale={locale} setLocale={setLocale}>
      {children}
    </IntlRoot>
  );
}

function ignoreLocaleChange() {}

/**
 * Provides the active locale and its ICU messages. Public pages derive the locale from the URL
 * (`/en/...` is English); `setLocale` lets later features (the profile setting) take over.
 * Keeps `<html lang>` in sync after hydration, since the prerendered fallback is Spanish.
 *
 * Passing `locale` forces it and needs no router (Storybook's locale toolbar); `setLocale` then
 * calls `onLocaleChange` when given (a story that holds the locale itself), and is ignored otherwise.
 */
export function IntlProvider({
  children,
  locale,
  onLocaleChange,
}: {
  children: ReactNode;
  locale?: Locale;
  onLocaleChange?: (locale: Locale) => void;
}) {
  if (locale) {
    return (
      <IntlRoot locale={locale} setLocale={onLocaleChange ?? ignoreLocaleChange}>
        {children}
      </IntlRoot>
    );
  }
  return <UrlIntlProvider>{children}</UrlIntlProvider>;
}

export function useLocale(): LocaleContextValue {
  const value = useContext(LocaleContext);
  if (!value) throw new Error("useLocale must be used inside <IntlProvider>");
  return value;
}
