import { useTranslations } from "use-intl";
import { useLocale } from "../i18n/IntlProvider.tsx";
import { PressLink } from "../ui/PressLink.tsx";

export interface DemoBannerProps {
  /**
   * Where "Crear mi cuenta" goes: the app's sign-in in the visitor's language by default. The demo
   * is part of the app, so sign-in is on the same origin.
   */
  signInHref?: string;
}

/**
 * The demo's notice, stuck to the top of every `/demo` screen (spec §2.6b): the data is made up
 * and a reload wipes it, and "Crear mi cuenta" leads to sign-in. A complementary landmark named
 * "Demo", so assistive technology can find it and skip it.
 */
export function DemoBanner({ signInHref }: DemoBannerProps) {
  const t = useTranslations("demo");
  const { locale } = useLocale();
  return (
    <aside
      aria-label={t("label")}
      className="sticky top-0 z-[25] border-stroke border-b-2 bg-surface-sunken px-(--space-4) py-(--space-2) lg:px-(--space-6)"
    >
      <div className="mx-auto flex w-full max-w-[480px] flex-wrap items-center justify-between gap-x-(--space-3) gap-y-(--space-2) lg:max-w-[1040px]">
        <p className="m-0 flex min-w-0 flex-1 basis-[160px] items-start gap-(--space-2) text-[13px] leading-snug font-bold text-ink">
          <span aria-hidden="true">🧪</span>
          <span>{t("banner")}</span>
        </p>
        <PressLink to={signInHref ?? `/sign-in?lang=${locale}`} size="sm" className="flex-none">
          {t("create_account")}
        </PressLink>
      </div>
    </aside>
  );
}
