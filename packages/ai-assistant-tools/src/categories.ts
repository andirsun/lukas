import type { CategoryDto } from "@lukas/core";
import { ToolError } from "./errors.ts";

/** A name as people mean it: lowercase, without accents, trimmed, single spaces ("comida rapida"). */
export function normalizeName(s: string): string {
  return s
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .trim()
    .replace(/\s+/g, " ");
}

function pick(matches: CategoryDto[], name: string): CategoryDto | null {
  if (matches.length === 1) return matches[0] as CategoryDto;
  if (matches.length === 0) return null;
  const names = matches.map((c) => c.name);
  throw new ToolError(
    "category_ambiguous",
    `"${name}" matches several categories: ${names.join(", ")}. Ask the person which one.`,
    { candidates: names },
  );
}

/**
 * The active category a name means, never a guess: an exact normalized match wins ("comida" is
 * Comida, not Comida rápida); otherwise the one category starting with it, then the one containing
 * it. Several at the same step → `category_ambiguous`; none → `category_not_found`. Both list the
 * names in `data.candidates`. Archived categories are never matched.
 */
export function resolveCategory(
  name: string,
  categories: CategoryDto[],
  kind?: "expense" | "income",
): CategoryDto {
  const usable = categories.filter((c) => !c.archived && (kind === undefined || c.kind === kind));
  const wanted = normalizeName(name);
  const keyed = usable.map((c) => ({ c, key: normalizeName(c.name) }));
  const found =
    wanted === ""
      ? null
      : (pick(
          keyed.filter((k) => k.key === wanted).map((k) => k.c),
          name,
        ) ??
        pick(
          keyed.filter((k) => k.key.startsWith(wanted)).map((k) => k.c),
          name,
        ) ??
        pick(
          keyed.filter((k) => k.key.includes(wanted)).map((k) => k.c),
          name,
        ));
  if (found) return found;
  const names = usable.map((c) => c.name);
  const which = kind ? `${kind} category` : "category";
  throw new ToolError(
    "category_not_found",
    `No ${which} matches "${name}". The person's categories: ${names.join(", ")}. Use one of them, or ask; never invent one.`,
    { candidates: names },
  );
}
