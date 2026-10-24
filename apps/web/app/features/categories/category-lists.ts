import type { CategoryDto, CategoryKind, CategorySummary } from "@lukas/core";

/**
 * What the Categorías tab lists for one kind: the rows of the month, in order, and the archived
 * ones folded at the end. An archived spending category that has spending in the month on screen
 * (the summary keeps it only then, so it has a line) is one of the month's rows, with its note, as
 * home's list had it: the rows still add up to what the month spent. It leaves the fold.
 */
export function categoryLists(
  categories: CategoryDto[],
  lines: ReadonlyMap<string, CategorySummary>,
  kind: CategoryKind,
) {
  const ofKind = categories
    .filter((c) => c.kind === kind)
    .sort((a, b) => a.sortOrder - b.sortOrder);
  const spentThisMonth = (c: CategoryDto) => kind === "expense" && c.archived && lines.has(c.id);
  return {
    rows: ofKind.filter((c) => !c.archived || spentThisMonth(c)),
    archived: ofKind.filter((c) => c.archived && !spentThisMonth(c)),
  };
}
