import { readFileSync } from "node:fs";
import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

const { version } = JSON.parse(readFileSync(new URL("./package.json", import.meta.url), "utf8"));

export default defineConfig({
  // The version Settings' "Comentarios e ideas" puts in the email (features/settings/feedback.ts).
  define: { __APP_VERSION__: JSON.stringify(version) },
  plugins: [tailwindcss(), reactRouter()],
  // Keep Vite's manifest: the landing e2e reads it to hold the initial JavaScript of `/` to its
  // budget. react-router.config.ts moves it out of what ships, to build/vite-manifest.json.
  build: {
    manifest: true,
    rollupOptions: {
      output: {
        // The mascot component is shared by the landing and the app, so it is its own chunk, and a
        // chunk is named after its module. The landing's HTML links that chunk, and its e2e check
        // allows no `Lukas` (the old name) outside scripts, so the file is called `mascot`.
        chunkFileNames: (chunk) =>
          chunk.name === "Lukas" ? "assets/mascot-[hash].js" : "assets/[name]-[hash].js",
      },
    },
  },
  server: {
    // The API's public URL (API_URL in .env) is this origin + /api, so the port is fixed.
    port: 5173,
    strictPort: true,
    proxy: {
      // Same-origin API: Better Auth cookies stay first-party. The path is forwarded as is: the
      // API serves its routes under API_URL's path (/api). X-Forwarded-* carry the browser's host
      // and client IP to the API.
      "/api": { target: "http://localhost:3000", changeOrigin: false, xfwd: true },
      // RFC 8414: assistants look for the authorization server's metadata at the well-known path
      // followed by the issuer's path (/api/auth). The API serves it under /api, as Caddy rewrites.
      "/.well-known/oauth-authorization-server/api/auth": {
        target: "http://localhost:3000",
        changeOrigin: false,
        xfwd: true,
        rewrite: () => "/api/.well-known/oauth-authorization-server/auth",
      },
      // The MCP server (`pnpm --filter @lukas/mcp dev`) on this same origin, as Caddy serves it.
      "/mcp": { target: "http://localhost:3001", changeOrigin: false, xfwd: true },
      "/.well-known/oauth-protected-resource": {
        target: "http://localhost:3001",
        changeOrigin: false,
        xfwd: true,
      },
    },
  },
});
