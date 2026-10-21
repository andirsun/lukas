import { describe, expect, it } from "vitest";
import { categoryLook } from "./category-look.ts";

describe("categoryLook", () => {
  it("maps the importer's icon and color names", () => {
    expect(categoryLook({ icon: "cart", color: "orange" })).toEqual({
      glyph: "🛒",
      tint: "#ff9f1c",
    });
  });

  it("keeps an emoji and a hex color as they are", () => {
    expect(categoryLook({ icon: "🍽️", color: "#ff5c7a" })).toEqual({
      glyph: "🍽️",
      tint: "#ff5c7a",
    });
  });

  it("falls back to gray for a color it does not know", () => {
    expect(categoryLook({ icon: "tag", color: "chartreuse" }).tint).toBe("#8e87b8");
  });
});
