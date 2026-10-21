import { animate, useReducedMotion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { formatMoney } from "../i18n/format.ts";
import { useLocale } from "../i18n/IntlProvider.tsx";
import { cx } from "./cx.ts";
import { durationToken } from "./motion-tokens.ts";

export interface MoneyProps {
  /** Integer minor units; negatives render with the real minus sign (U+2212). */
  cents: number;
  /** ISO 4217 code, e.g. `EUR`. */
  currency: string;
  /** Count from the previous value to the new one over `--count-up` whenever `cents` changes. */
  animate?: boolean;
  className?: string;
}

/**
 * An amount in the active locale (`562,92 €` / `€562.92`) with tabular figures. With `animate`,
 * changes count up over `--count-up`; the counting figure is hidden from assistive technology,
 * which reads the final amount right away. Under reduced motion the value just changes.
 */
export function Money({ cents, currency, animate: countUp = false, className }: MoneyProps) {
  const { locale } = useLocale();
  const reduceMotion = useReducedMotion() ?? false;
  const counting = countUp && !reduceMotion;
  const [shown, setShown] = useState(cents);
  const shownRef = useRef(cents);

  useEffect(() => {
    const from = shownRef.current;
    if (!counting || from === cents) {
      shownRef.current = cents;
      setShown(cents);
      return;
    }
    const controls = animate(from, cents, {
      duration: durationToken("--count-up"),
      ease: "easeOut",
      onUpdate: (value) => {
        shownRef.current = Math.round(value);
        setShown(shownRef.current);
      },
    });
    return () => controls.stop();
  }, [cents, counting]);

  const final = formatMoney(cents, currency, locale);
  if (!countUp) return <span className={cx("lk-num", className)}>{final}</span>;
  return (
    <span className={cx("lk-num", className)}>
      <span aria-hidden="true">{formatMoney(counting ? shown : cents, currency, locale)}</span>
      <span className="sr-only">{final}</span>
    </span>
  );
}
