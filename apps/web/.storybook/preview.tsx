import type { Decorator, Preview } from "@storybook/react-vite";
import { MotionConfig } from "motion/react";
import type { Locale } from "../app/i18n/format.ts";
import { IntlProvider } from "../app/i18n/IntlProvider.tsx";
import type { Theme } from "../app/theme/theme-bootstrap.ts";
import "../app/styles/fonts.ts";
import "../app/styles/app.css";

/**
 * Every story renders in the app's IntlProvider with the toolbar's locale, under the toolbar's
 * theme. Stories pin either with `globals: { theme: "day", locale: "en" }`, so the a11y checks
 * (contrast included) run in both themes. `parameters: { reducedMotion: true }` renders a story as
 * if the person asked for reduced motion (Motion's `MotionConfig reducedMotion="always"`).
 */
const withThemeAndLocale: Decorator = (Story, context) => {
  const theme: Theme = context.globals.theme === "day" ? "day" : "night";
  const locale: Locale = context.globals.locale === "en" ? "en" : "es";
  // Set during render (not in an effect) so the first paint and the a11y run see the theme.
  document.documentElement.dataset.theme = theme;
  const story = (
    <IntlProvider locale={locale}>
      <div className="p-(--space-4)">
        <Story />
      </div>
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
        ],
        dynamicTitle: true,
      },
    },
  },
  initialGlobals: { theme: "night", locale: "es" },
  decorators: [withThemeAndLocale],
};

export default preview;
