import { type Month, monthOf, todayIn } from "@lukas/core";
import type { AppDeps } from "../deps.ts";
import type { SessionUser } from "../env.ts";

/** The API's clock: the pinned one when there is one (E2E_NOW), else the real one. */
export function nowOf(deps: Pick<AppDeps, "now">): Date {
  return deps.now?.() ?? new Date();
}

/** Today in the user's time zone, by the API's clock. */
export function userToday(deps: Pick<AppDeps, "now">, user: Pick<SessionUser, "timezone">) {
  return todayIn(user.timezone, nowOf(deps));
}

/** The current month in the user's time zone, by the API's clock. */
export function currentMonth(
  deps: Pick<AppDeps, "now">,
  user: Pick<SessionUser, "timezone">,
): Month {
  return monthOf(userToday(deps, user));
}
