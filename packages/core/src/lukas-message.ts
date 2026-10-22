import { type IsoDate, lastDay, monthOf } from "./dates.ts";
import type { CategorySummary, MonthSummary } from "./summary.ts";

export type LukasMessageKey =
  | "first_of_day"
  | "on_track"
  | "near_limit"
  | "over_budget"
  | "income_received"
  | "pending_paid"
  | "month_last_day"
  | "month_closed_green";

export interface LukasMessageInput {
  /** The month summary AFTER the event (if any) was applied. */
  summary: MonthSummary;
  today: IsoDate;
  /** Transactions recorded today, including the event's. */
  todayCount: number;
  /**
   * The save or payment Lukas is reacting to. `name` is the movement's own name: the lines about
   * it say which one it was (empty or missing: the client says its category's name instead).
   */
  event?: { kind: "saved" | "paid"; categoryId: string; amount: number; name?: string };
}

export interface LukasMessage {
  key: LukasMessageKey;
  params: Record<string, string | number>;
}

const MS_PER_DAY = 86_400_000;

function utcDay(date: IsoDate): number {
  const [year, month, day] = date.split("-").map(Number) as [number, number, number];
  return Date.UTC(year, month - 1, day) / MS_PER_DAY;
}

/** Days from `today` to the last day of `month`, both included. Never negative. */
function daysLeft(today: IsoDate, month: string): number {
  return Math.max(0, utcDay(lastDay(month)) - utcDay(today) + 1);
}

function overBudget(category: CategorySummary): LukasMessage {
  return {
    key: "over_budget",
    params: { categoryId: category.categoryId, over: -(category.remaining ?? 0) },
  };
}

function nearLimit(category: CategorySummary): LukasMessage {
  return {
    key: "near_limit",
    params: { categoryId: category.categoryId, remaining: category.remaining ?? 0 },
  };
}

/**
 * Picks the message Lukas shows. Returns only a key and its parameters; the copy belongs to the
 * client. Rules are evaluated top to bottom and the first match wins.
 */
export function lukasMessage(input: LukasMessageInput): LukasMessage {
  const { summary, today, todayCount, event } = input;
  const eventCategory = event
    ? summary.categories.find((c) => c.categoryId === event.categoryId)
    : undefined;

  // Which movement it was: its name, and its category for when it has none.
  const movement = event
    ? { name: event.name?.trim() ?? "", categoryId: event.categoryId }
    : undefined;

  // A pending income marked paid was received, not paid.
  if (event?.kind === "paid" && event.amount < 0) {
    return { key: "pending_paid", params: { amount: -event.amount, ...movement } };
  }
  if (event && event.amount > 0 && (event.kind === "paid" || !eventCategory)) {
    return { key: "income_received", params: { amount: event.amount, ...movement } };
  }
  if (eventCategory?.state === "over") return overBudget(eventCategory);
  if (eventCategory?.state === "near") return nearLimit(eventCategory);
  if (event && todayCount === 1) return { key: "first_of_day", params: { ...movement } };

  if (summary.month < monthOf(today) && summary.remaining >= 0) {
    return { key: "month_closed_green", params: { remaining: summary.remaining } };
  }
  if (today === lastDay(summary.month)) {
    return { key: "month_last_day", params: { remaining: summary.remaining } };
  }

  if (!event) {
    const over = summary.categories
      .filter((c) => c.state === "over")
      .reduce<CategorySummary | undefined>(
        (worst, c) => (!worst || (c.remaining ?? 0) < (worst.remaining ?? 0) ? c : worst),
        undefined,
      );
    if (over) return overBudget(over);

    const near = summary.categories
      .filter((c) => c.state === "near")
      .reduce<CategorySummary | undefined>(
        (least, c) => (!least || (c.remaining ?? 0) < (least.remaining ?? 0) ? c : least),
        undefined,
      );
    if (near) return nearLimit(near);
  }

  return {
    key: "on_track",
    params: { remaining: summary.remaining, daysLeft: daysLeft(today, summary.month) },
  };
}
