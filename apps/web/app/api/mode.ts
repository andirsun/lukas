/** `live` talks to the real API; `demo` runs on an in-memory backend, signed in as a made-up user. */
export type ApiMode = "live" | "demo";

let activeMode: ApiMode = "live";

/** The mode route loaders see. React reads `useApiMode()` instead. */
export function getApiMode(): ApiMode {
  return activeMode;
}

/**
 * Set by whatever starts or leaves the demo, before the routes it guards load: loaders run
 * outside React (and before any component mounts), so `<ApiProvider mode>` alone is too late for
 * them. The session guards treat `demo` as signed in and onboarded.
 */
export function setApiMode(mode: ApiMode): void {
  activeMode = mode;
}
