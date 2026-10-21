import { createContext, type ReactNode, useContext, useMemo } from "react";
import { type ApiClient, createApiClient } from "./client.ts";
import type { ApiMode } from "./mode.ts";

interface ApiContextValue {
  client: ApiClient;
  mode: ApiMode;
}

const ApiContext = createContext<ApiContextValue | null>(null);

export interface ApiProviderProps {
  children: ReactNode;
  /** The `fetch` every request goes through. The demo swaps in an in-memory backend. */
  fetch?: typeof globalThis.fetch;
  mode?: ApiMode;
}

/**
 * Gives the query hooks their API client. By default requests go to the real API with the
 * browser's `fetch`; the demo passes its own `fetch` and `mode="demo"`. Components read the mode
 * with `useApiMode()`. Route loaders run outside React, so whatever starts the demo also calls
 * `setApiMode("demo")` (api/mode.ts); the session guards read it from there.
 */
export function ApiProvider({ children, fetch: fetchImpl, mode = "live" }: ApiProviderProps) {
  const client = useMemo(() => createApiClient(fetchImpl ? { fetch: fetchImpl } : {}), [fetchImpl]);
  const value = useMemo(() => ({ client, mode }), [client, mode]);

  return <ApiContext.Provider value={value}>{children}</ApiContext.Provider>;
}

function useApiContext(): ApiContextValue {
  const value = useContext(ApiContext);
  if (!value) throw new Error("useApi and useApiMode must be used inside <ApiProvider>");
  return value;
}

/** The API client for the current mode. */
export function useApi(): ApiClient {
  return useApiContext().client;
}

export function useApiMode(): ApiMode {
  return useApiContext().mode;
}
