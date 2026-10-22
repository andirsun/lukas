import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import {
  DEFAULT_THEME_PREF,
  isThemePref,
  resolveTheme,
  THEME_STORAGE_KEY,
  type Theme,
  type ThemePref,
} from "./theme-bootstrap.ts";

interface ThemeContextValue {
  pref: ThemePref;
  /** The theme actually applied: `pref` with `auto` resolved from the OS. */
  theme: Theme;
  setPref: (pref: ThemePref) => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);
const DARK_QUERY = "(prefers-color-scheme: dark)";

/**
 * Keeps the `data-theme` attribute in sync with the preference. The inline bootstrap script has
 * already set it before paint; this provider takes over after mount (reading the stored
 * preference then, so prerendered markup and hydration agree) and reacts to OS changes. With
 * nothing stored the theme is night; only an explicit `auto` follows the OS.
 */
export function ThemeProvider({ children }: { children: ReactNode }) {
  const [pref, setPrefState] = useState<ThemePref>(DEFAULT_THEME_PREF);
  const [prefersDark, setPrefersDark] = useState(true);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    try {
      const stored = localStorage.getItem(THEME_STORAGE_KEY);
      if (isThemePref(stored)) setPrefState(stored);
    } catch {
      // Storage can be blocked; the default (night) is fine.
    }
    const query = typeof matchMedia === "function" ? matchMedia(DARK_QUERY) : null;
    if (query) {
      setPrefersDark(query.matches);
      const onChange = (event: MediaQueryListEvent) => setPrefersDark(event.matches);
      query.addEventListener("change", onChange);
      setReady(true);
      return () => query.removeEventListener("change", onChange);
    }
    setReady(true);
  }, []);

  const theme = resolveTheme(pref, prefersDark);

  useEffect(() => {
    // Skipped until the stored preference is known, so the bootstrap's choice is never overwritten.
    if (ready) document.documentElement.dataset.theme = theme;
  }, [ready, theme]);

  const setPref = useCallback((next: ThemePref) => {
    setPrefState(next);
    try {
      localStorage.setItem(THEME_STORAGE_KEY, next);
    } catch {
      // Not persisted, but the choice still applies for this session.
    }
  }, []);

  const value = useMemo(() => ({ pref, theme, setPref }), [pref, theme, setPref]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const value = useContext(ThemeContext);
  if (!value) throw new Error("useTheme must be used inside <ThemeProvider>");
  return value;
}
