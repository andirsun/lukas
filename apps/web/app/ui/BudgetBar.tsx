import { cx } from "./cx.ts";

export interface BudgetBarProps {
  /** Cents spent this month in the category. */
  spent: number;
  /** Cents budgeted, or `null` when the category has no budget. */
  budget: number | null;
  /** From the API (`MonthSummary.categories[].state`); never recomputed here. */
  state: "ok" | "near" | "over";
  size?: "md" | "sm";
  /** Names the meter; pair the bar with the same status in words (`Quedan 46,33 €`). */
  label: string;
}

/** Share of the budget spent as a CSS width, capped at full. */
function fillWidth(spent: number, budget: number): string {
  const ratio = budget > 0 ? Math.min(Math.max(spent, 0) / budget, 1) : spent > 0 ? 1 : 0;
  return `${Math.round(ratio * 1000) / 10}%`;
}

/**
 * A track that fills with what was spent (never with what is left), colored by `state`. It is a
 * `meter` named by `label`; over budget the value is clamped to the maximum so the meter stays
 * valid, and the label carries the overflow in words. Without a budget there is nothing to
 * measure: the track stays empty and is hidden from assistive technology.
 */
export function BudgetBar({ spent, budget, state, size = "md", label }: BudgetBarProps) {
  const className = cx(
    "lk-bar",
    size === "sm" && "lk-bar-sm",
    state === "near" && "is-near",
    state === "over" && "is-over",
  );
  const fillClass =
    "transition-[width] duration-(--count-up) ease-out motion-reduce:transition-none";

  if (budget === null) {
    return (
      <div className={className} aria-hidden="true">
        <span className={fillClass} style={{ width: "0%" }} />
      </div>
    );
  }

  const max = Math.max(budget, 0);
  return (
    <div
      role="meter"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={max}
      aria-valuenow={Math.min(Math.max(spent, 0), max)}
      className={className}
    >
      <span className={fillClass} style={{ width: fillWidth(spent, budget) }} />
    </div>
  );
}
