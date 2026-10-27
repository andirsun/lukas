/**
 * The public roadmap: the single source for the roadmap page (`/roadmap`, `/en/roadmap`, `/it/roadmap`, `/pt/roadmap`) and the
 * landing's "what's next" section. Add, move or remove an item here (and its copy in every message
 * catalog under `roadmap.items`) and both places follow. No dates anywhere: only a status.
 */

/** Left to right on a desktop, top to bottom on a phone. */
export const ROADMAP_STATUSES = ["done", "building", "next", "later"] as const;

export type RoadmapStatus = (typeof ROADMAP_STATUSES)[number];

export interface RoadmapItem {
  /** Unique and stable: the catalog keys and the landing's selection use it. */
  id: string;
  status: RoadmapStatus;
  /** An emoji, drawn in the card's icon box. Decorative. */
  glyph: string;
  /** Catalog key of the title. */
  title: string;
  /** Catalog key of the one-line description. */
  body: string;
}

function item(id: string, status: RoadmapStatus, glyph: string): RoadmapItem {
  return {
    id,
    status,
    glyph,
    title: `roadmap.items.${id}.title`,
    body: `roadmap.items.${id}.body`,
  };
}

/** In the order they appear inside their column. Source: the overall spec's §3.3 (Stages). */
export const ROADMAP_ITEMS: readonly RoadmapItem[] = [
  item("web_app", "done", "🌐"),
  item("demo", "done", "🧪"),
  item("android_app", "building", "📲"),
  item("android_widget", "building", "🎤"),
  item("import_budge", "building", "📥"),
  item("iphone_app", "next", "📱"),
  item("connect_ai", "next", "✨"),
  item("e2e_encryption", "next", "🔒"),
  item("bank_alerts", "later", "🏦"),
  item("import_others", "later", "📂"),
];

/** The three items the landing shows in "what's next", in order. */
export const LANDING_ROADMAP_IDS = ["android_app", "android_widget", "iphone_app"] as const;

export interface RoadmapColumn {
  status: RoadmapStatus;
  items: RoadmapItem[];
}

/** The columns to render: one per status that has items, in status order. */
export function roadmapColumns(items: readonly RoadmapItem[] = ROADMAP_ITEMS): RoadmapColumn[] {
  return ROADMAP_STATUSES.map((status) => ({
    status,
    items: items.filter((entry) => entry.status === status),
  })).filter((column) => column.items.length > 0);
}

export function roadmapItem(id: string): RoadmapItem {
  const found = ROADMAP_ITEMS.find((entry) => entry.id === id);
  if (!found) throw new Error(`Unknown roadmap item: ${id}`);
  return found;
}
