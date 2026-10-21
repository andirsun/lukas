import { QueryClient } from "@tanstack/react-query";
import { ApiProblem } from "./errors.ts";

const MAX_RETRIES = 2;

/**
 * Retry a failed read only when trying again can help: a lost connection or a server error. A 4xx
 * (not signed in, not found, invalid) gets the same answer every time.
 */
export function shouldRetry(failureCount: number, error: Error): boolean {
  if (error instanceof ApiProblem && error.status >= 400 && error.status < 500) return false;
  return failureCount < MAX_RETRIES;
}

export function createQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      // Fresh for half a minute: moving between screens does not refetch what was just fetched.
      queries: { staleTime: 30_000, retry: shouldRetry },
      // A write is never retried by itself; the person sees the error and decides.
      mutations: { retry: false },
    },
  });
}
