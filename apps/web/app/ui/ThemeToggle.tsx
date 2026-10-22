import { useTranslations } from "use-intl";
import { useTheme } from "../theme/ThemeProvider.tsx";
import { cx } from "./cx.ts";
import { PressButton } from "./PressButton.tsx";

function Moon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M20.5 14.6A8.6 8.6 0 0 1 9.4 3.5a.7.7 0 0 0-.9-.9A9.6 9.6 0 1 0 21.4 15.5a.7.7 0 0 0-.9-.9Z" />
    </svg>
  );
}

function Sun() {
  return (
    <svg
      width="22"
      height="22"
      viewBox="0 0 24 24"
      fill="currentColor"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="4.5" stroke="none" />
      <path
        d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"
        fill="none"
      />
    </svg>
  );
}

/**
 * The day/night switch: a compact pressable icon button. It shows the theme that is active (a
 * moon at night, a sun by day) and its label says what a press does ("Switch to day mode"). It is
 * an action, not a toggle state, so it has no `aria-pressed`. A press stores an explicit choice
 * (`night` or `day`), which replaces `auto`. Needs a `ThemeProvider` above it.
 */
export function ThemeToggle({ className }: { className?: string }) {
  const t = useTranslations("theme");
  const { theme, setPref } = useTheme();
  const night = theme === "night";
  return (
    <PressButton
      variant="secondary"
      size="sm"
      className={cx("p-0", className)}
      aria-label={night ? t("switch_to_day") : t("switch_to_night")}
      onClick={() => setPref(night ? "day" : "night")}
    >
      {night ? <Moon /> : <Sun />}
    </PressButton>
  );
}
