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

/**
 * Inline script placed first in `<head>`: sets `data-theme` before the first paint so a stored
 * "day" preference never flashes the default night theme. Plain ES5, no imports; any failure
 * (blocked storage, no matchMedia) leaves the default night theme in place.
 */
export const THEME_BOOTSTRAP_SCRIPT = `(function(){try{var p=null;try{p=localStorage.getItem(${JSON.stringify(
  THEME_STORAGE_KEY,
)})}catch(e){}var t;if(p==="night"||p==="day"){t=p}else if(typeof matchMedia==="function"){t=matchMedia("(prefers-color-scheme: dark)").matches?"night":"day"}else{t="night"}document.documentElement.dataset.theme=t}catch(e){}})();`;
