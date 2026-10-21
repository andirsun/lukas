import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [tailwindcss(), reactRouter()],
  // Keep Vite's manifest (build/client/.vite/manifest.json): the landing e2e reads it to hold the
  // initial JavaScript of `/` to its budget, separately from the lazy 3D chunk.
  build: { manifest: true },
  server: {
    // The API's public URL (API_URL in .env) is this origin + /api, so the port is fixed.
    port: 5173,
    strictPort: true,
    proxy: {
      // Same-origin API: Better Auth cookies stay first-party. The path is forwarded as is: the
      // API serves its routes under API_URL's path (/api). X-Forwarded-* carry the browser's host
      // and client IP to the API.
      "/api": { target: "http://localhost:3000", changeOrigin: false, xfwd: true },
    },
  },
});
