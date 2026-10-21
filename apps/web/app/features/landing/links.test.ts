import { describe, expect, it } from "vitest";
import { appLinkProps, GITHUB_HREF } from "./links.ts";

const APP = "https://app-lukas.andersonlaverde.com";

describe("appLinkProps", () => {
  it("leads to sign-in in the visitor's language when the app exists", () => {
    expect(appLinkProps("es", false)).toEqual({ to: "/sign-in?lang=es" });
    expect(appLinkProps("en", false)).toEqual({ to: "/sign-in?lang=en" });
  });

  it("leads to the GitHub repo, in a new tab, in landing-only mode without an app URL", () => {
    for (const locale of ["es", "en"] as const) {
      expect(appLinkProps(locale, true)).toEqual({
        to: GITHUB_HREF,
        target: "_blank",
        rel: "noopener",
      });
      expect(appLinkProps(locale, true, undefined)).toEqual({
        to: GITHUB_HREF,
        target: "_blank",
        rel: "noopener",
      });
    }
  });

  it("leads to the live app's sign-in, in the visitor's language, in landing-only mode with an app URL", () => {
    expect(appLinkProps("es", true, APP)).toEqual({ to: `${APP}/sign-in?lang=es` });
    expect(appLinkProps("en", true, APP)).toEqual({ to: `${APP}/sign-in?lang=en` });
  });

  it("ignores the app URL outside landing-only mode: the app's own sign-in route is used", () => {
    expect(appLinkProps("es", false, APP)).toEqual({ to: "/sign-in?lang=es" });
  });
});
