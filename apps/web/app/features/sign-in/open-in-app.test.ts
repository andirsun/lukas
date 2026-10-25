import { describe, expect, it } from "vitest";
import { appIntentUrl, isAndroidBrowser, opensInApp, webLinkUrl } from "./open-in-app.ts";

const CHROME_ANDROID =
  "Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36";
const CHROME_MAC =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";
const SAFARI_IOS =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1";

const ORIGIN = "https://app-lukas.andersonlaverde.com";
const QUERY = "?email=ana%40example.com&code=424242&lang=es&next=%2Fapp%2Finsights&from=app";

describe("opensInApp", () => {
  it("is true only for from=app on an Android browser", () => {
    expect(opensInApp(QUERY, CHROME_ANDROID)).toBe(true);
    expect(opensInApp("?from=app&code=1", CHROME_ANDROID)).toBe(true);
    // Off Android the link behaves as ever.
    expect(opensInApp(QUERY, CHROME_MAC)).toBe(false);
    expect(opensInApp(QUERY, SAFARI_IOS)).toBe(false);
    // Without the marker, or with another value, so does it on Android.
    expect(opensInApp("?email=a%40b.co&code=424242", CHROME_ANDROID)).toBe(false);
    expect(opensInApp("?from=web&code=424242", CHROME_ANDROID)).toBe(false);
    expect(opensInApp("?from=", CHROME_ANDROID)).toBe(false);
  });
});

describe("isAndroidBrowser", () => {
  it("reads the user agent", () => {
    expect(isAndroidBrowser(CHROME_ANDROID)).toBe(true);
    expect(isAndroidBrowser(CHROME_MAC)).toBe(false);
    expect(isAndroidBrowser(SAFARI_IOS)).toBe(false);
    expect(isAndroidBrowser("")).toBe(false);
  });
});

describe("appIntentUrl", () => {
  it("is the intent URL of this page: same path and query, https, the app's package, and back here without from=app", () => {
    expect(appIntentUrl(ORIGIN, QUERY)).toBe(
      "intent://app-lukas.andersonlaverde.com/auth/verify" +
        "?email=ana%40example.com&code=424242&lang=es&next=%2Fapp%2Finsights&from=app" +
        "#Intent;scheme=https;package=com.andersonlaverde.lukitas;" +
        "S.browser_fallback_url=" +
        encodeURIComponent(
          `${ORIGIN}/auth/verify?email=ana%40example.com&code=424242&lang=es&next=%2Fapp%2Finsights`,
        ) +
        ";end",
    );
  });

  it("keeps a port, and always asks for https", () => {
    expect(appIntentUrl("http://localhost:5173", "?code=1&from=app")).toBe(
      "intent://localhost:5173/auth/verify?code=1&from=app" +
        "#Intent;scheme=https;package=com.andersonlaverde.lukitas;" +
        `S.browser_fallback_url=${encodeURIComponent("http://localhost:5173/auth/verify?code=1")};end`,
    );
  });
});

describe("webLinkUrl", () => {
  it("is the page without from=app, and nothing else changed", () => {
    expect(webLinkUrl(ORIGIN, QUERY)).toBe(
      `${ORIGIN}/auth/verify?email=ana%40example.com&code=424242&lang=es&next=%2Fapp%2Finsights`,
    );
    expect(webLinkUrl(ORIGIN, "?from=app")).toBe(`${ORIGIN}/auth/verify`);
  });
});
