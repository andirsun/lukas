import { reactRouter } from "@react-router/dev/vite";
import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [tailwindcss(), reactRouter()],
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
