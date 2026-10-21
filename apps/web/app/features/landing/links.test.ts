import { describe, expect, it } from "vitest";
import { appLinkProps, GITHUB_HREF } from "./links.ts";

describe("appLinkProps", () => {
  it("leads to sign-in in the visitor's language when the app exists", () => {
    expect(appLinkProps("es", false)).toEqual({ to: "/sign-in?lang=es" });
    expect(appLinkProps("en", false)).toEqual({ to: "/sign-in?lang=en" });
  });

  it("leads to the GitHub repo, in a new tab, in landing-only mode", () => {
    for (const locale of ["es", "en"] as const) {
      expect(appLinkProps(locale, true)).toEqual({
        to: GITHUB_HREF,
        target: "_blank",
        rel: "noopener",
      });
    }
  });
});
