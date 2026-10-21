import { type KeyboardEvent, useRef } from "react";
import { cx } from "./cx.ts";

export interface SegmentedControlProps<T extends string> {
  value: T;
  options: { value: T; label: string }[];
  onChange(value: T): void;
  /** Names the tab list for assistive technology. */
  label: string;
}

/**
 * Switches between views (`lk-seg`), as ARIA tabs: the selected option sits raised on its edge,
 * only it is in the tab order, and the arrow keys (wrapping), Home and End move the selection.
 */
export function SegmentedControl<T extends string>({
  value,
  options,
  onChange,
  label,
}: SegmentedControlProps<T>) {
  const tabs = useRef(new Map<T, HTMLButtonElement>());

  const selectAt = (index: number) => {
    const option = options[(index + options.length) % options.length];
    if (!option) return;
    onChange(option.value);
    tabs.current.get(option.value)?.focus();
  };

  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    const current = options.findIndex((option) => option.value === value);
    const moves: Record<string, number> = {
      ArrowLeft: current - 1,
      ArrowRight: current + 1,
      Home: 0,
      End: options.length - 1,
    };
    const next = moves[event.key];
    if (next === undefined) return;
    event.preventDefault();
    selectAt(next);
  };

  return (
    <div role="tablist" aria-label={label} className="lk-seg" onKeyDown={onKeyDown}>
      {options.map((option) => {
        const selected = option.value === value;
        return (
          <button
            key={option.value}
            ref={(node) => {
              if (node) tabs.current.set(option.value, node);
              else tabs.current.delete(option.value);
            }}
            type="button"
            role="tab"
            aria-selected={selected}
            tabIndex={selected ? 0 : -1}
            className={cx(
              "min-h-11 transition-[translate,box-shadow,background-color,color] duration-(--press)",
              selected
                ? "active:translate-y-[3px] active:shadow-[0_1px_0_var(--surface-edge)]"
                : "active:translate-y-0.5",
            )}
            onClick={() => onChange(option.value)}
          >
            {option.label}
          </button>
        );
      })}
    </div>
  );
}
