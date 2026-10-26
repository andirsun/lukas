import type { Decorator, Preview } from "@storybook/react-vite";
import { MotionConfig } from "motion/react";
import { configure } from "storybook/test";
import { AppMessages } from "../app/i18n/AppMessages.tsx";
import { isLocale, type Locale } from "../app/i18n/format.ts";
import { IntlProvider } from "../app/i18n/IntlProvider.tsx";
import { ThemeProvider } from "../app/theme/ThemeProvider.tsx";
import { THEME_STORAGE_KEY, type Theme } from "../app/theme/theme-bootstrap.ts";
import "../app/styles/fonts.ts";
import "../app/styles/app.css";

/**
 * Every story renders in the app's IntlProvider with the toolbar's locale, under the toolbar's
 * theme (inside the app's ThemeProvider). Stories pin either with `globals: { theme: "day", locale: "en" }`, so the a11y checks
 * (contrast included) run in both themes. `parameters: { reducedMotion: true }` renders a story as
 * if the person asked for reduced motion (Motion's `MotionConfig reducedMotion="always"`).
 */
// `waitFor` and `findBy…` wait for a state, not for a time: allow 5 s (not 1) for it to come, so
// animations on a busy machine still pass while a missing state still fails.
configure({ asyncUtilTimeout: 5000 });

const withThemeAndLocale: Decorator = (Story, context) => {
  const theme: Theme = context.globals.theme === "day" ? "day" : "night";
  const locale: Locale = isLocale(context.globals.locale) ? context.globals.locale : "es";
  // Set during render (not in an effect) so the first paint and the a11y run see the theme.
  document.documentElement.dataset.theme = theme;
  // The app's ThemeProvider (which components such as ThemeToggle read) starts from the stored
  // preference, so the toolbar's theme is stored first; the key remounts it when the toolbar changes.
  try {
    localStorage.setItem(THEME_STORAGE_KEY, theme);
  } catch {
    // Blocked storage: the provider falls back to night.
  }
  const story = (
    <IntlProvider locale={locale}>
      <AppMessages>
        <ThemeProvider key={theme}>
          <div className="p-(--space-4)">
            <Story />
          </div>
        </ThemeProvider>
      </AppMessages>
    </IntlProvider>
  );
  return context.parameters.reducedMotion ? (
    <MotionConfig reducedMotion="always">{story}</MotionConfig>
  ) : (
    story
  );
};

const preview: Preview = {
  parameters: {
    // Accessibility violations fail the Storybook tests, not just show in the panel.
    a11y: { test: "error" },
    layout: "fullscreen",
  },
  globalTypes: {
    theme: {
      description: "Color theme",
      toolbar: {
        title: "Theme",
        icon: "mirror",
        items: [
          { value: "night", title: "Night" },
          { value: "day", title: "Day" },
        ],
        dynamicTitle: true,
      },
    },
    locale: {
      description: "Language",
      toolbar: {
        title: "Locale",
        icon: "globe",
        items: [
          { value: "es", title: "Español" },
          { value: "en", title: "English" },
          { value: "it", title: "Italiano" },
          { value: "pt", title: "Português" },
        ],
        dynamicTitle: true,
      },
    },
  },
  initialGlobals: { theme: "night", locale: "es" },
  decorators: [withThemeAndLocale],
};

export default preview;
