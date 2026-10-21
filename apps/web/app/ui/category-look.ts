/**
 * How a category looks: an emoji and a tint. Categories made in the app store the emoji as `icon`
 * and a hex color as `color`. The Budge importer (packages/importers, category-style.ts) stores
 * names instead (`cart`, `orange`); this maps those, so both kinds look alike.
 */
const IMPORTER_GLYPHS: Record<string, string> = {
  cart: "🛒",
  cutlery: "🍽️",
  star: "⭐",
  house: "🏠",
  car: "🚗",
  umbrella: "☂️",
  heart: "❤️",
  document: "🧾",
  salary: "💰",
  chart: "📈",
  plane: "✈️",
  box: "📦",
  tag: "🏷️",
};

/** Mid-tone tints: mixed into the sunken surface, they read in night and day. */
const IMPORTER_TINTS: Record<string, string> = {
  orange: "#ff9f1c",
  red: "#ff5c7a",
  purple: "#a66bff",
  indigo: "#6d6bff",
  blue: "#3fa7ff",
  pink: "#ff8fd8",
  amber: "#ffb547",
  yellow: "#ffe66d",
  green: "#2fd388",
  teal: "#2ec4b6",
  sky: "#5ac8fa",
  gray: "#8e87b8",
};

const FALLBACK_TINT = IMPORTER_TINTS.gray as string;

/** The tints a person can pick for a category, by name (the catalogs name them for screen readers). */
export const CATEGORY_TINTS = (
  ["orange", "red", "purple", "indigo", "blue", "pink", "amber", "green", "teal", "gray"] as const
).map((name) => ({ name, value: IMPORTER_TINTS[name] as string }));

/** Emoji a person can pick for a category: the suggestions' and a few common ones. */
export const CATEGORY_GLYPHS = [
  "🏷️",
  "🛒",
  "🍽️",
  "🏠",
  "🚗",
  "⭐",
  "☂️",
  "❤️",
  "💰",
  "🐶",
  "🎓",
  "✈️",
  "🎁",
  "👕",
  "💊",
  "📱",
  "🏋️",
  "🍺",
  "🧾",
  "📈",
] as const;

export interface CategoryLook {
  glyph: string;
  tint: string;
}

export function categoryLook({ icon, color }: { icon: string; color: string }): CategoryLook {
  return {
    glyph: IMPORTER_GLYPHS[icon] ?? icon,
    tint: IMPORTER_TINTS[color] ?? (/^#[0-9a-f]{3,8}$/i.test(color) ? color : FALLBACK_TINT),
  };
}
