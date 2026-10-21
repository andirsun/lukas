/**
 * Serves the built site (`build/client`) the way a static host does, for the e2e tests that check
 * the prerendered pages: `/en` → `en/index.html`, real files as they are, and every other path the
 * SPA fallback (`__spa-fallback.html`) or, when the build has a top-level `404.html` (the
 * landing-only release), that page with a 404 status, as Cloudflare Pages does. No dependencies, no
 * caching, GET and HEAD only.
 *
 *   tsx scripts/serve-build.ts [port]   (default 4180)
 */
import { existsSync, readFileSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("../build/client", import.meta.url));
const PORT = Number(process.argv[2] ?? process.env.PORT ?? 4180);

const TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json",
  ".data": "text/x-script",
  ".txt": "text/plain; charset=utf-8",
  ".xml": "application/xml; charset=utf-8",
  ".png": "image/png",
  ".webp": "image/webp",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};

function isFile(path: string): boolean {
  return existsSync(path) && statSync(path).isFile();
}

/** The file for a URL path, or null. Never leaves ROOT. */
function resolve(pathname: string): string | null {
  const candidate = normalize(join(ROOT, decodeURIComponent(pathname)));
  if (candidate !== ROOT && !candidate.startsWith(ROOT + sep)) return null;
  if (isFile(candidate)) return candidate;
  const index = join(candidate, "index.html");
  return isFile(index) ? index : null;
}

if (!existsSync(ROOT)) {
  console.error(`No build at ${ROOT}. Run \`pnpm build\` first.`);
  process.exit(1);
}

createServer((req, res) => {
  if (req.method !== "GET" && req.method !== "HEAD") {
    res.writeHead(405).end();
    return;
  }
  const { pathname } = new URL(req.url ?? "/", "http://localhost");
  let file: string | null;
  try {
    file = resolve(pathname);
  } catch {
    file = null;
  }
  const notFound = join(ROOT, "404.html");
  const missing = file === null && isFile(notFound);
  const path = file ?? (missing ? notFound : join(ROOT, "__spa-fallback.html"));
  const body = readFileSync(path);
  res.writeHead(missing ? 404 : 200, {
    "content-type": TYPES[extname(path)] ?? "application/octet-stream",
    "content-length": body.length,
    "cache-control": "no-store",
  });
  res.end(req.method === "HEAD" ? undefined : body);
}).listen(PORT, () => {
  console.log(`Serving ${ROOT} at http://localhost:${PORT}`);
});
