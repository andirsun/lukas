import { type Month, monthOf, todayIn } from "@lukas/core";
import type { SessionUser } from "../env.ts";

/** The current month in the user's time zone. */
export function currentMonth(user: SessionUser): Month {
  return monthOf(todayIn(user.timezone));
}
