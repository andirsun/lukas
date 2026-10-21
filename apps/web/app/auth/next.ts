/** Where the app lands after sign-in when `next` is missing or unusable. */
export const DEFAULT_NEXT = "/app";

/** The page `next` stands for, resolved against a placeholder origin to see where it really goes. */
const PLACEHOLDER_ORIGIN = "http://lukas.invalid";

/**
 * The same-origin path (with query and hash) that `raw` names, or `fallback`.
 *
 * `next` comes from the address bar, so anything an attacker can type ends up here: absolute URLs,
 * protocol-relative `//host`, backslashes (browsers read `/\host` as `//host`), and tabs or
 * newlines (the URL parser drops them, turning `/\t/host` into `//host`). A value is accepted only
 * if it starts with a single `/` and, parsed, still points at our own origin.
 */
export function safeNext(raw: string | null | undefined, fallback: string = DEFAULT_NEXT): string {
  if (!raw || !raw.startsWith("/") || raw.startsWith("//") || raw.startsWith("/\\"))
    return fallback;
  let url: URL;
  try {
    url = new URL(raw, PLACEHOLDER_ORIGIN);
  } catch {
    return fallback;
  }
  if (url.origin !== PLACEHOLDER_ORIGIN) return fallback;
  return `${url.pathname}${url.search}${url.hash}`;
}

/** The sign-in page, set to send the visitor back to `next` afterwards. */
export function signInPath(next: string): string {
  return `/sign-in?next=${encodeURIComponent(safeNext(next))}`;
}
