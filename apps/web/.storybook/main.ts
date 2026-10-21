import type { StorybookConfig } from "@storybook/react-vite";
import type { PluginOption } from "vite";

/** React Router's Vite plugin builds the app itself; Storybook renders components without it. */
function withoutReactRouter(plugins: PluginOption[] = []): PluginOption[] {
  return plugins.map((plugin) => {
    if (Array.isArray(plugin)) return withoutReactRouter(plugin);
    const name = plugin && typeof plugin === "object" && "name" in plugin ? plugin.name : "";
    return name.startsWith("react-router") ? false : plugin;
  });
}

const config: StorybookConfig = {
  stories: ["../app/**/*.stories.@(ts|tsx)"],
  addons: ["@storybook/addon-vitest", "@storybook/addon-a11y"],
  framework: "@storybook/react-vite",
  // Same static files as the app (e.g. the Lukas sprite sheets under /lukas).
  staticDirs: ["../public"],
  core: { disableTelemetry: true },
  viteFinal: (config) => ({ ...config, plugins: withoutReactRouter(config.plugins) }),
};

export default config;
