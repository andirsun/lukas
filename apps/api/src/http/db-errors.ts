/** True when a (possibly Drizzle-wrapped) error is a Postgres unique violation. */
export function isUniqueViolation(error: unknown): boolean {
  for (
    let e = error as { code?: string; cause?: unknown } | undefined;
    e;
    e = e.cause as typeof e
  ) {
    if (e.code === "23505") return true;
  }
  return false;
}
