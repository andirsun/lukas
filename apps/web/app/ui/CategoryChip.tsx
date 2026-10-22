import { cx } from "./cx.ts";

export interface CategoryChipProps {
  /** The category's emoji. */
  glyph: string;
  label: string;
  /** A short muted word under the name, e.g. "archivada". Part of the chip's name. */
  note?: string;
  selected: boolean;
  onSelect(): void;
}

/**
 * A category in the add sheet's picker (`lk-chips` lays them out four per row): a pressable glyph
 * tile with the name under it. The whole chip is one toggle button named by its label; the
 * selected one gets the `gold` outline and `ink` label.
 */
export function CategoryChip({ glyph, label, note, selected, onSelect }: CategoryChipProps) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      onClick={onSelect}
      className={cx("lk-chip lk-chip-button min-h-11 min-w-11", selected && "is-selected")}
    >
      <span className="lk-chip-tile" aria-hidden="true">
        {glyph}
      </span>
      <span className="max-w-full truncate">{label}</span>
      {note && <span className="max-w-full truncate text-[9px] text-ink-muted">{note}</span>}
    </button>
  );
}
