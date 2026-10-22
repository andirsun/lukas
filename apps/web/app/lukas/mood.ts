import type { MonthSummary } from "@lukas/core";

export type LukasMood = "happy" | "worried" | "celebrating";

/**
 * Lukas mirrors the month: celebrating right after a celebration-worthy event (a save, a payment,
 * a month closed in green), worried while any category is near or over its limit, happy otherwise.
 * The celebrating flag wins, so a save still gets its moment in a tight month.
 */
export function moodFor(summary: MonthSummary, celebrating: boolean): LukasMood {
  if (celebrating) return "celebrating";
  return summary.categories.some((c) => c.state !== "ok") ? "worried" : "happy";
}
