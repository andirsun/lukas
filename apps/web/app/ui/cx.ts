/** Joins class names, skipping falsy entries: `cx("lk-btn", sm && "lk-btn-sm")`. */
export function cx(...names: (string | false | null | undefined)[]): string {
  return names.filter(Boolean).join(" ");
}
