import { type Ref, useId } from "react";
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
          enterKeyHint="done"
          onChange={(event) => onChange(event.target.value)}
          className="min-w-0 flex-1 border-0 bg-transparent p-0 font-text text-ink outline-none placeholder:text-ink-muted placeholder:italic"
        />
      </div>
      {suggestions.length > 0 && (
        <div role="group" aria-label={t("suggestions")} className="lk-shortcuts">
          {suggestions.map((s) => {
            const hit = isHit(s);
            return (
              <button
                key={`${s.name}-${s.categoryName}`}
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
