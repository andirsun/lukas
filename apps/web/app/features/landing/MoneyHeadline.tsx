import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { useTranslations } from "use-intl";
import { useReducedMotionPreference } from "../../ui/motion-tokens.ts";
import { agreement, MONEY_WORD_HOLD, MONEY_WORDS } from "./money-words.ts";

/**
 * The Spanish headline, with what money is called around the Spanish-speaking world taking turns
 * on the gold marker ("Tus lukas 🇨🇴" → "Tu lana 🇲🇽" → "Tu guita 🇦🇷"…), each with its country's flag, and
 * "Tu(s)" and "clar(a/o)(s)" agreeing with each word. Screen readers and search engines get the
 * message as it is (the prerendered "lukas"); the turning words are decorative. It starts turning
 * once hydrated, waits while the tab is hidden, and holds on "lukas" under reduced motion.
 */
export function MoneyHeadline() {
  const t = useTranslations("landing.hero");
  const reduceMotion = useReducedMotionPreference();
  const index = useTurns(MONEY_WORDS.length, MONEY_WORD_HOLD, !reduceMotion);
  const entry = MONEY_WORDS[index] ?? MONEY_WORDS[0];
  const { det, adj } = agreement(entry);
  return (
    <h1 id="hero-title" className="lk-landing-headline">
      <span className="sr-only">{t.rich("headline", { mark: (chunks) => chunks })}</span>
      <span aria-hidden="true">
        <span className="lk-swap-word">
          Tu
          <Swap text={det} />
        </span>{" "}
        <span className="lk-swap-word">
          <span className="lk-landing-marker">
            <Swap text={entry.word} />
            <span className="lk-landing-flag">
              <Swap text={entry.flag} />
            </span>
          </span>
          ,
        </span>{" "}
        por fin{" "}
        <span className="lk-swap-word">
          clar
          <Swap text={adj} />.
        </span>
      </span>
    </h1>
  );
}

/** Steps 0, 1, … count-1, 0 … every `hold` ms while `enabled` and the tab is visible; else 0. */
function useTurns(count: number, hold: number, enabled: boolean): number {
  const [index, setIndex] = useState(0);
  useEffect(() => {
    if (!enabled) {
      setIndex(0);
      return;
    }
    const timer = window.setInterval(() => {
      if (!document.hidden) setIndex((i) => (i + 1) % count);
    }, hold);
    return () => window.clearInterval(timer);
  }, [count, hold, enabled]);
  return index;
}

/** ms: a little longer than the roll (`--lk-swap-time` in landing.css). */
const SETTLE_FALLBACK = 600;

/**
 * A piece of text that, when it changes, rolls the old one up and out while the new one rises in,
 * and eases its width from the old text's to the new one's so the words around it slide along.
 */
function Swap({ text }: { text: string }) {
  const box = useRef<HTMLSpanElement>(null);
  const shown = useRef(text);
  const [leaving, setLeaving] = useState<string | null>(null);

  useLayoutEffect(() => {
    if (shown.current === text) return;
    setLeaving(shown.current);
    shown.current = text;
  }, [text]);

  // Both texts are in the DOM now: measure them, pin the old width, then ease to the new one.
  useLayoutEffect(() => {
    const el = box.current;
    if (leaving === null || !el) return;
    const [entering, left] = el.children as unknown as [HTMLElement, HTMLElement];
    el.style.width = `${left.offsetWidth}px`;
    el.getBoundingClientRect();
    el.style.width = `${entering.offsetWidth}px`;
    // In case the roll's `animationend` never comes (no frames painted, animations off).
    const fallback = window.setTimeout(settle, SETTLE_FALLBACK);
    return () => window.clearTimeout(fallback);
  }, [leaving]);

  // The roll and the width share one duration: once the old text is gone the width is settled,
  // and goes back to the text's own (so a late web font still fits).
  function settle() {
    setLeaving(null);
    if (box.current) box.current.style.width = "";
  }

  return (
    <span ref={box} className="lk-swap">
      <span key={text} className={leaving === null ? undefined : "lk-swap-in"}>
        {text}
      </span>
      {leaving !== null && (
        <span key={`out-${leaving}`} className="lk-swap-out" onAnimationEnd={settle}>
          {leaving}
        </span>
      )}
    </span>
  );
}
