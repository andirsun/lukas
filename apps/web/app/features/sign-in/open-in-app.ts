/**
 * The magic link of a sign-in started in the Android app carries `from=app`. Some mail apps open
 * links in their own browser, which never asks Android for the app (its verified App Link), so
 * the page offers an `intent://` link that does. It is the same address, so the app signs in with
 * the very code the link carries, and nothing is spent on the web unless the person chooses it.
 */

/** The Android app's package (apps/mobile/android/app/build.gradle.kts, applicationId). */
export const APP_PACKAGE = "com.andersonlaverde.lukitas";

/** The page the magic link opens. */
const VERIFY_PATH = "/auth/verify";

/** Whether the browser runs on Android: the only place an `intent://` link opens an app. */
export function isAndroidBrowser(userAgent: string): boolean {
  return /\bAndroid\b/i.test(userAgent);
}

/** Whether this visit should offer the app first: `from=app` in an Android browser. */
export function opensInApp(search: string, userAgent: string): boolean {
  return new URLSearchParams(search).get("from") === "app" && isAndroidBrowser(userAgent);
}

/** This page with the same query but `from=app`, to land on when the app does not open. */
export function webLinkUrl(origin: string, search: string): string {
  const query = new URLSearchParams(search);
  query.delete("from");
  const rest = query.toString();
  return `${origin}${VERIFY_PATH}${rest ? `?${rest}` : ""}`;
}

/**
 * `intent://<host>/auth/verify?<the same query>#Intent;scheme=https;package=…;S.browser_fallback_url=…;end`:
 * Chrome (and the Custom Tabs of mail apps) start the app for the https address, and go to
 * [webLinkUrl] when the app is not installed.
 */
export function appIntentUrl(origin: string, search: string): string {
  const { host } = new URL(origin);
  return (
    `intent://${host}${VERIFY_PATH}${search}` +
    `#Intent;scheme=https;package=${APP_PACKAGE};` +
    `S.browser_fallback_url=${encodeURIComponent(webLinkUrl(origin, search))};end`
  );
}
