/**
 * The mobile parity harness (docs/mobile/parity.md) reads the app screen's data from the story's
 * own fake API, so the web story and the app's golden show the same movements, budgets and names.
 * A story harness hands its fake `fetch` to `exposeStoryFetch` as it builds it; the harness's
 * `scripts/parity-fixtures.ts` then calls it from the story's page, after the story has rendered
 * and played, and saves the answers as the app test's fixture: for every GET the story itself
 * made, and for the ones the app screen makes.
 */

declare global {
  interface Window {
    /** The fake API of the story on this page, if its harness has one. */
    __lukasStoryFetch?: typeof fetch;
    /** Each GET (path and query) the story's screens made through it. */
    __lukasStoryGets?: Set<string>;
  }
}

/**
 * Makes `fetch` the page's story API for the parity fixtures, and returns it, wrapped only to
 * note the GETs the story makes.
 */
export function exposeStoryFetch(fetch: typeof globalThis.fetch): typeof globalThis.fetch {
  if (typeof window === "undefined") return fetch;
  const gets = new Set<string>();
  window.__lukasStoryFetch = fetch;
  window.__lukasStoryGets = gets;
  return (input, init) => {
    const request = new Request(input, init);
    if (request.method === "GET") {
      const url = new URL(request.url);
      gets.add(url.pathname + url.search);
    }
    return fetch(request);
  };
}
