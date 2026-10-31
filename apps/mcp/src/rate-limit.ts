/**
 * A per-assistant request budget over a rolling minute, in memory (one MCP process). It keeps a
 * looping assistant from flooding the API; the API's own limits still apply behind it.
 */
export function rateLimiter(perMinute: number, now: () => number = Date.now) {
  const windows = new Map<string, number[]>();
  return {
    /** Counts one request for `key`; false when it is over the budget (and it is not counted). */
    take(key: string): boolean {
      const since = now() - 60_000;
      const recent = (windows.get(key) ?? []).filter((at) => at > since);
      if (recent.length >= perMinute) {
        windows.set(key, recent);
        return false;
      }
      recent.push(now());
      windows.set(key, recent);
      // Forget idle assistants, so the map does not grow without bound.
      if (windows.size > 10_000) {
        for (const [k, times] of windows) if (!times.some((at) => at > since)) windows.delete(k);
      }
      return true;
    },
  };
}
