/** Where the app lands after sign-in when `next` is missing or unusable. */
export const DEFAULT_NEXT = "/app";

/** The page `next` stands for, resolved against a placeholder origin to see where it really goes. */
const PLACEHOLDER_ORIGIN = "http://lukas.invalid";

/** A path that starts with exactly one `/`: not `//host`, not `/\host`. */
const SINGLE_SLASH_PATH = /^\/(?![/\\])/;

/** A slash or backslash written as %2F or %5C: there is no honest reason for one in `next`. */
const ENCODED_SLASH = /%(?:2f|5c)/i;

/**
 * The same-origin path (with query and hash) that `raw` names, or `fallback`.
 *
 * `next` comes from the address bar, so anything an attacker can type ends up here: absolute URLs,
 * protocol-relative `//host`, backslashes (browsers read `/\host` as `//host`), tabs or newlines
 * (the URL parser drops them), and dot-segments (`/.//host` and `/%2e%2e//host` normalize to
 * `//host`). So the raw value is screened, and so is what comes out of parsing it: the result must
 * still be on our origin and must start with a single `/`.
 */
export function safeNext(raw: string | null | undefined, fallback: string = DEFAULT_NEXT): string {
  if (!raw || !SINGLE_SLASH_PATH.test(raw) || raw.includes("\\")) return fallback;
  // In the path only: a query like `?q=%2F` is data, not a place to go.
  if (ENCODED_SLASH.test(raw.split(/[?#]/, 1)[0] ?? "")) return fallback;
  let url: URL;
  try {
    url = new URL(raw, PLACEHOLDER_ORIGIN);
  } catch {
    return fallback;
  }
  if (url.origin !== PLACEHOLDER_ORIGIN) return fallback;
  const result = `${url.pathname}${url.search}${url.hash}`;
  // A tab or newline in the raw value is dropped by the parser, so the result is checked again.
  if (!SINGLE_SLASH_PATH.test(result) || result.includes("\\")) return fallback;
  return result;
}

/** The sign-in page, set to send the visitor back to `next` afterwards. */
export function signInPath(next: string): string {
  return `/sign-in?next=${encodeURIComponent(safeNext(next))}`;
}
