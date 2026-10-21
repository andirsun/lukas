import { describe, expect, it } from "vitest";
import { generateTokensCss, type TokensJson } from "./gen-tokens.ts";

const fixture: TokensJson = {
  color: {
    themes: [
      { id: "night", name: "Night" },
      { id: "day", name: "Day" },
    ],
    tokens: [
      { name: "bg", value: { night: "#15122b", day: "#f7f4ff" } },
      { name: "brand", value: { night: "#7c4dff", day: "#7b3df0" } },
    ],
  },
  type: {
    families: {
      display: '"Fredoka", "Baloo 2", ui-rounded, system-ui, sans-serif',
      text: '"Nunito", ui-rounded, system-ui, sans-serif',
    },
  },
  spacing: { tokens: [{ name: "space-4", value: "16px" }] },
  radius: { tokens: [{ name: "radius-xl", value: "24px" }] },
  shadow: {
    tokens: [{ name: "edge-sm", value: { night: "0 3px 0 #0f0c22", day: "0 3px 0 #d6ccf5" } }],
  },
  duration: { tokens: [{ name: "press", value: "80ms" }] },
};

/** Returns the declarations of every rule whose selector list is exactly `selector`. */
function declarations(css: string, selector: string): string[] {
  const withoutComments = css.replace(/\/\*[\s\S]*?\*\//g, "");
  const rules = [...withoutComments.matchAll(/([^{}]+)\{([^{}]*)\}/g)];
  return rules
    .filter(([, sel]) => sel?.replace(/\s+/g, " ").trim() === selector)
    .flatMap(([, , body]) =>
      (body ?? "")
        .split(";")
        .map((d) => d.trim())
        .filter(Boolean),
    );
}

describe("generateTokensCss", () => {
  const css = generateTokensCss(fixture);

  it("puts the first theme on :root and on its own data-theme selector", () => {
    const night = declarations(css, ':root, [data-theme="night"]');
    expect(night).toContain("--brand: #7c4dff");
    expect(night).toContain("--bg: #15122b");
    expect(night).toContain("--edge-sm: 0 3px 0 #0f0c22");
  });

  it("overrides colors and shadows under the other themes", () => {
    const day = declarations(css, '[data-theme="day"]');
    expect(day).toContain("--brand: #7b3df0");
    expect(day).toContain("--bg: #f7f4ff");
    expect(day).toContain("--edge-sm: 0 3px 0 #d6ccf5");
  });

  it("puts theme-independent tokens on :root with the design system's names", () => {
    const root = declarations(css, ":root");
    expect(root).toContain("--space-4: 16px");
    expect(root).toContain("--radius-xl: 24px");
    expect(root).toContain("--press: 80ms");
    expect(root).toContain(
      '--font-display: "Fredoka", "Baloo 2", ui-rounded, system-ui, sans-serif',
    );
    expect(root).toContain('--font-text: "Nunito", ui-rounded, system-ui, sans-serif');
  });

  it("fails loudly when a themed token misses a theme", () => {
    const broken: TokensJson = {
      ...fixture,
      color: { ...fixture.color, tokens: [{ name: "ink", value: { night: "#fff" } }] },
    };
    expect(() => generateTokensCss(broken)).toThrow(/ink.*day/);
  });
});
