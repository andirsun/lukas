import type { Month } from "@lukas/core";
import { useEffect, useId, useRef, useState } from "react";
import { useNavigate } from "react-router";
import { useTranslations } from "use-intl";
import { useClearSession } from "../../api/ApiProvider.tsx";
import { authClient } from "../../auth/auth-client.ts";
import { MonthPicker } from "../../ui/MonthPicker.tsx";
import { PressButton } from "../../ui/PressButton.tsx";
import { ThemeToggle } from "../../ui/ThemeToggle.tsx";

export interface HomeHeaderProps {
  month: Month;
  onMonth(month: Month): void;
  /** The current month in the person's time zone: the latest one to show. */
  max: Month;
}

/** Sections that live in the avatar menu and do not exist yet (Tasks 13 and 15). */
const SOON = ["recurring", "categories", "settings"] as const;

/**
 * Home's header: the wordmark, the month (previous months browsable), and the avatar menu with
 * the day/night switch, the sections still to come, and sign-out. The menu is a disclosure: its
 * button says whether it is open, Escape or a tap outside closes it and gives focus back.
 */
export function HomeHeader({ month, onMonth, max }: HomeHeaderProps) {
  const t = useTranslations();
  const [open, setOpen] = useState(false);
  const menuId = useId();
  const button = useRef<HTMLButtonElement>(null);
  const panel = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();
  const clearSession = useClearSession();

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

  const signOut = async () => {
    await authClient.signOut().catch(() => {});
    clearSession();
    navigate("/sign-in", { replace: true });
  };

  return (
    <header className="relative flex items-center justify-between gap-(--space-2)">
      <span className="lk-logo inline-flex min-h-11 items-center lg:invisible">
        {t("app.name")}
      </span>
      <MonthPicker month={month} onChange={onMonth} max={max} />
      <button
        ref={button}
        type="button"
        className="lk-avatar"
        aria-label={t("home.account")}
        aria-expanded={open}
        aria-controls={menuId}
        onClick={() => setOpen((current) => !current)}
      >
        <span aria-hidden="true">🙂</span>
      </button>
      <div
        ref={panel}
        id={menuId}
        hidden={!open}
        className="lk-menu absolute top-full right-0 z-20 mt-(--space-2) w-60"
      >
        <div className="flex items-center justify-between gap-(--space-2)">
          <span className="text-[14px] font-bold text-ink">{t("theme.label")}</span>
          <ThemeToggle />
        </div>
        <ul className="m-0 flex list-none flex-col gap-(--space-1) p-0">
          {SOON.map((key) => (
            <li
              key={key}
              className="flex min-h-11 items-center justify-between text-[14px] font-bold text-ink-muted"
            >
              {t(`nav.${key}`)}
              <span className="lk-soon">{t("nav.soon")}</span>
            </li>
          ))}
        </ul>
        <PressButton variant="secondary" size="sm" onClick={() => void signOut()}>
          {t("home.sign_out")}
        </PressButton>
      </div>
    </header>
  );
}
