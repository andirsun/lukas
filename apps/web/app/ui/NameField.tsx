import { type Ref, useEffect, useId, useLayoutEffect, useRef, useState } from "react";
import { useTranslations } from "use-intl";
import { cx } from "./cx.ts";

export interface NameSuggestion {
  name: string;
  categoryName: string;
}

export interface NameFieldProps<S extends NameSuggestion = NameSuggestion> {
  value: string;
  /** The name that will be used when the field stays empty: the selected category's name. */
  placeholder: string;
  /** Recent names, already filtered for `value` (the API's `?q=`), each with its usual category. */
  suggestions: S[];
  onChange(value: string): void;
  /** A shortcut was tapped: the caller fills the name and selects its category. */
  onPick(suggestion: S): void;
  /** The text input, e.g. to focus it ("Ponerle nombre"). */
  inputRef?: Ref<HTMLInputElement>;
}

/** At most this many rows of shortcuts, so the categories under the field stay in view. */
const MAX_ROWS = 2;

/**
 * How many of the group's children fit in `maxRows` wrapped rows: `null` while measuring (all are
 * rendered), then the count. Measured again when the labels or the group's width change; both
 * passes run before paint, so nothing flickers.
 */
function useRowLimit(signature: string, maxRows: number) {
  const ref = useRef<HTMLDivElement>(null);
  const [limit, setLimit] = useState<number | null>(null);
  const [width, setWidth] = useState(0);

  useEffect(() => {
    const element = ref.current;
    if (!element || typeof ResizeObserver === "undefined") return;
    const observer = new ResizeObserver(([entry]) => {
      if (entry) setWidth(Math.round(entry.contentRect.width));
    });
    observer.observe(element);
    return () => observer.disconnect();
  }, []);

  // A new signature or width shows them all again, to be measured.
  useLayoutEffect(() => setLimit(null), [signature, width]);

  useLayoutEffect(() => {
    if (limit !== null || !ref.current) return;
    const tops = [...ref.current.children].map((child) => (child as HTMLElement).offsetTop);
    const rowTops = [...new Set(tops)].sort((a, b) => a - b);
    const firstHidden = rowTops[maxRows];
    setLimit(firstHidden === undefined ? tops.length : tops.findIndex((top) => top >= firstHidden));
  }, [limit, maxRows]);

  return { ref, limit };
}

/**
 * The transaction's optional name, with recent names as shortcuts under it. While typing, each
 * shortcut is labelled with its category; the one matching the current name is marked.
 */
export function NameField<S extends NameSuggestion>({
  value,
  placeholder,
  suggestions,
  onChange,
  onPick,
  inputRef,
}: NameFieldProps<S>) {
  const t = useTranslations("name_field");
  const inputId = useId();
  const query = value.trim().toLowerCase();
  const isHit = (s: S) => query !== "" && s.name.toLowerCase() === query;
  const typing = query !== "" && !suggestions.some(isHit);
  const rows = useRowLimit(
    `${typing}|${suggestions.map((s) => `${s.name}·${s.categoryName}`).join("|")}`,
    MAX_ROWS,
  );

  return (
    <div className="flex flex-col gap-(--space-1)">
      <label htmlFor={inputId} className="sr-only">
        {t("label")}
      </label>
      <div className="lk-input min-h-11">
        <span aria-hidden="true">✏️</span>
        <input
          ref={inputRef}
          id={inputId}
          type="text"
          value={value}
          placeholder={placeholder}
          autoComplete="off"
          maxLength={120}
          enterKeyHint="done"
          onChange={(event) => onChange(event.target.value)}
          className="min-w-0 flex-1 border-0 bg-transparent p-0 font-text text-ink outline-none placeholder:text-ink-muted placeholder:italic"
        />
      </div>
      {suggestions.length > 0 && (
        <div ref={rows.ref} role="group" aria-label={t("suggestions")} className="lk-shortcuts">
          {suggestions.map((s, index) => {
            const hit = isHit(s);
            return (
              <button
                key={`${s.name}-${s.categoryName}`}
                hidden={rows.limit !== null && index >= rows.limit}
                type="button"
                className="lk-shortcut-button"
                aria-pressed={hit}
                onClick={() => onPick(s)}
              >
                <span className={cx("lk-shortcut", hit && "is-hit")}>
                  {s.name}
                  {typing && " "}
                  {typing && <span className="text-ink-muted">· {s.categoryName}</span>}
                  {hit && <span aria-hidden="true"> ✓</span>}
                </span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
}
