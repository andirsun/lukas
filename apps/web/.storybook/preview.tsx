import type { Preview } from "@storybook/react-vite";
import "../app/styles/fonts.ts";
import "../app/styles/app.css";

const preview: Preview = {
  parameters: {
    // Accessibility violations fail the Storybook tests, not just show in the panel.
    a11y: { test: "error" },
    layout: "fullscreen",
  },
};

export default preview;
