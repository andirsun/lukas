import { QueryClientProvider } from "@tanstack/react-query";
import { createContext, type ReactNode, useContext, useState } from "react";
import type { ApiClient } from "./client.ts";
import { type ApiMode, type ApiScope, createApiScope } from "./scope.ts";

const ApiContext = createContext<ApiScope | null>(null);

export interface ApiProviderProps {
  children: ReactNode;
  /** The `fetch` every request goes through. The demo swaps in an in-memory backend. */
  fetch?: typeof globalThis.fetch;
  mode?: ApiMode;
  /** Where the API is mounted; "/api" unless a test or a story needs an absolute URL. */
  baseUrl?: string;
}

/**
 * Gives the screens an API client and the cache that goes with it (it hosts the
 * `QueryClientProvider`). By default requests go to the real API with the browser's `fetch`; the
 * demo passes its own `fetch` and `mode="demo"`.
 *
 * The mode and the cache belong together: a different `mode` or `fetch` starts a new, empty cache,
 * so demo data never shows up in the live app, nor one user's data in the next one's session. For
 * a user change inside the same mode (sign-out, sign-in), call `useClearSession()`.
 *
 * Screens always get the client from `useApi()`. Never import the `api` singleton from client.ts
 * in a screen: it is live-only and ignores the demo's `fetch`.
 */
export function ApiProvider({
  children,
  fetch: fetchImpl,
  mode = "live",
  baseUrl,
}: ApiProviderProps) {
  const make = () =>
    createApiScope({
      mode,
      ...(fetchImpl ? { fetch: fetchImpl } : {}),
      ...(baseUrl ? { baseUrl } : {}),
    });
  const [held, setHeld] = useState(() => ({ scope: make(), mode, fetchImpl }));
  let scope = held.scope;
  if (held.mode !== mode || held.fetchImpl !== fetchImpl) {
    // Adjusting state while rendering: the old scope is dropped before anything renders with it.
    scope = make();
    setHeld({ scope, mode, fetchImpl });
  }
  return (
    <ApiContext.Provider value={scope}>
      <QueryClientProvider client={scope.queryClient}>{children}</QueryClientProvider>
    </ApiContext.Provider>
  );
}

function useApiScope(): ApiScope {
  const value = useContext(ApiContext);
  if (!value) throw new Error("useApi, useApiMode and useClearSession need an <ApiProvider>");
  return value;
}

/** The API client for the current mode, bound to the provider's `fetch`. */
export function useApi(): ApiClient {
  return useApiScope().client;
}

export function useApiMode(): ApiMode {
  return useApiScope().mode;
}

/** Empties the cache; call it when someone signs in or out. */
export function useClearSession(): () => void {
  return useApiScope().clearSession;
}
