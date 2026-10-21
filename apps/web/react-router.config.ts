import type { Config } from "@react-router/dev/config";

export default {
  // The landing pages are static HTML; everything else is a client-side SPA.
  ssr: false,
  prerender: ["/", "/en"],
} satisfies Config;
