import createClient, { type Middleware } from "openapi-fetch";
import { signInPath } from "../auth/next.ts";
import { ApiProblem, problemFromResponse } from "./errors.ts";
import type { paths } from "./schema";

/** The API lives under /api on the web's own origin (Vite proxies it in dev), so cookies stay first-party. */
export const API_BASE_URL = "/api";

const SIGN_IN_PATH = "/sign-in";

export type ApiClient = ReturnType<typeof createClient<paths>>;

interface Where {
  pathname: string;
  search: string;
  hash: string;
}

/**
 * Where to send a visitor whose session is gone: sign-in, set to bring them back to the page
 * they were on. Null on the sign-in page itself, so a 401 there cannot redirect in a loop.
 */
export function unauthorizedRedirect(where: Where): string | null {
  const onSignIn = where.pathname === SIGN_IN_PATH || where.pathname.startsWith(`${SIGN_IN_PATH}/`);
  if (onSignIn) return null;
  return signInPath(`${where.pathname}${where.search}${where.hash}`);
}

function redirectToSignIn() {
  if (typeof window === "undefined") return;
  const target = unauthorizedRedirect(window.location);
  if (target) window.location.assign(target);
}

export interface ApiClientOptions {
  /** Where requests go. Defaults to the live `fetch`; the demo passes an in-memory backend. */
  fetch?: typeof globalThis.fetch;
  baseUrl?: string;
  /** Runs on a 401, before the call rejects. Defaults to sending the browser to sign-in. */
  onUnauthorized?: () => void;
}

/**
 * The typed API client. Any non-2xx response rejects with an `ApiProblem` (so callers and
 * TanStack Query see failures as errors, not as `{ error }` values), a lost connection rejects with
 * `network_error`, and a 401 also sends the browser to sign-in.
 */
export function createApiClient({
  fetch: fetchImpl,
  baseUrl = API_BASE_URL,
  onUnauthorized = redirectToSignIn,
}: ApiClientOptions = {}): ApiClient {
  const middleware: Middleware = {
    async onResponse({ response }) {
      if (response.ok) return;
      if (response.status === 401) onUnauthorized();
      throw await problemFromResponse(response);
    },
    onError({ error }) {
      // Only a failed `fetch` (a TypeError) is a connection problem; anything else is a bug in
      // whatever sits behind `fetch` (the demo backend, say), and stays visible as itself.
      if (error instanceof TypeError) return new ApiProblem({ status: 0, code: "network_error" });
      return error instanceof Error ? error : new Error(String(error));
    },
  };

  const client = createClient<paths>({
    baseUrl,
    credentials: "include",
    // Looked up at call time, so a test or the demo can replace `fetch` after the client exists.
    fetch: (request) => (fetchImpl ?? globalThis.fetch)(request),
  });
  client.use(middleware);
  return client;
}

/**
 * The live client, for code outside React. It is live-only: it ignores the demo's `fetch`, so a
 * screen must never use it (a demo screen would hit the real API and be sent to sign-in).
 * Screens use `useApi()`.
 */
export const api = createApiClient();
