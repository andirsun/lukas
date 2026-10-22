import { describe, expect, it } from "vitest";
import { CATEGORY_TINTS, categoryLook } from "./category-look.ts";

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

describe("CATEGORY_TINTS", () => {
  it("offers every tint the importer can give a category", () => {
    const offered = new Set(CATEGORY_TINTS.map((t) => t.value));
    for (const color of [
      "orange",
      "red",
      "purple",
      "indigo",
      "blue",
      "pink",
      "amber",
      "yellow",
      "green",
      "teal",
      "sky",
      "gray",
    ]) {
      expect(offered.has(categoryLook({ icon: "tag", color }).tint), color).toBe(true);
    }
  });
});
