import { useEffect, useId, useRef, useState } from "react";
import { Link } from "react-router";
import { useTranslations } from "use-intl";
import { LOCALES } from "../../i18n/format.ts";
import { useLocale } from "../../i18n/IntlProvider.tsx";
import { PAGE_PATH, type SitePage } from "../../site/paths.ts";
import { PressButton } from "../../ui/PressButton.tsx";

/**
 * The header's language switch: a compact button with the active language's code ("ES") that
 * opens the same page in the other languages, so a visitor who does not read Spanish finds it
 * without scrolling to the footer (which keeps its own list, and is the way without JavaScript).
 * A disclosure like home's account menu: the button says whether it is open, Escape or a tap
 * outside closes it and gives focus back.
 */
export function LanguageMenu({ page }: { page: SitePage }) {
  const t = useTranslations("language");
  const { locale } = useLocale();
  const [open, setOpen] = useState(false);
  const menuId = useId();
  const button = useRef<HTMLButtonElement>(null);
  const panel = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onKey = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      setOpen(false);
      button.current?.focus();
    };
    const onPointer = (event: PointerEvent) => {
      const target = event.target as Node;
      if (!panel.current?.contains(target) && !button.current?.contains(target)) setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    document.addEventListener("pointerdown", onPointer);
    return () => {
      document.removeEventListener("keydown", onKey);
      document.removeEventListener("pointerdown", onPointer);
    };
  }, [open]);

  return (
    <div className="lk-landing-lang">
      <PressButton
        ref={button}
        variant="secondary"
        size="sm"
        className="lk-landing-lang-button"
        // Starts with what it shows, so "ES" also works for voice control.
        aria-label={`${locale.toUpperCase()}, ${t("label")}: ${t(locale)}`}
        aria-expanded={open}
        aria-controls={menuId}
        onClick={() => setOpen((current) => !current)}
      >
        {locale.toUpperCase()}
      </PressButton>
      <div ref={panel} id={menuId} hidden={!open} className="lk-menu lk-landing-lang-menu">
        <ul>
          {LOCALES.map((option) => (
            <li key={option}>
              <Link
                to={PAGE_PATH[page][option]}
                className="lk-landing-lang-option"
                lang={option}
                hrefLang={option}
                aria-current={option === locale ? "true" : undefined}
                onClick={() => setOpen(false)}
              >
                {t(option)}
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
