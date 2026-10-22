import { useEffect, useLayoutEffect, useState } from "react";

/** Seconds left until `at`, ticking every second while there are any. */
export function useSecondsUntil(at: number): number {
  const [now, setNow] = useState(() => Date.now());
  const left = Math.max(0, Math.ceil((at - now) / 1000));
  useEffect(() => {
    if (left === 0) return;
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [left]);
  // A new deadline counts from now, not from the last tick (before paint: no stale number shows).
  useLayoutEffect(() => setNow(Date.now()), [at]);
  return left;
}
