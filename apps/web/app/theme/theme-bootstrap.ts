export type ThemePref = "auto" | "night" | "day";
export type Theme = "night" | "day";

export const THEME_STORAGE_KEY = "lukas.theme";
export const THEME_PREFS: readonly ThemePref[] = ["auto", "night", "day"];

export function isThemePref(value: unknown): value is ThemePref {
  return value === "auto" || value === "night" || value === "day";
}

export function resolveTheme(pref: ThemePref, prefersDark: boolean): Theme {
  if (pref === "auto") return prefersDark ? "night" : "day";
  return pref;
}

/** What applies when nothing valid is stored: the purple night theme, whatever the OS prefers. */
export const DEFAULT_THEME_PREF: ThemePref = "night";

/**
 * Inline script placed first in `<head>`: sets `data-theme` before the first paint so a stored
 * "day" preference never flashes the default night theme. Plain ES5, no imports. Only an explicit
 * stored "auto" follows the OS; a missing or invalid value, blocked storage or no matchMedia all
 * give night.
 */
export const THEME_BOOTSTRAP_SCRIPT = `(function(){try{var p=null;try{p=localStorage.getItem(${JSON.stringify(
  THEME_STORAGE_KEY,
)})}catch(e){}var t;if(p==="night"||p==="day"){t=p}else if(p==="auto"&&typeof matchMedia==="function"){t=matchMedia("(prefers-color-scheme: dark)").matches?"night":"day"}else{t="night"}document.documentElement.dataset.theme=t}catch(e){}})();`;
