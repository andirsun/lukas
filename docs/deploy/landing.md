# Deploying the landing page (Cloudflare Pages)

Until the app exists, Lukitas can ship as the landing page alone: the two prerendered pages (`/` in
Spanish, `/en` in English), a 404 page and the static files. Every call to action reads "Coming
soon · Follow on GitHub" and links to the repository; nothing leads to the app.

## Build

```sh
VITE_SITE_URL=https://lukitas.andersonlaverde.com pnpm --filter @lukas/web build:landing
```

- `VITE_SITE_URL` is the site's public origin (no path). Set it in the environment or in `apps/web/.env`: both are read the same way, for the generated files and for the app code. It is required: the script stops with a
  message when it is missing or is not an `http(s)` origin. The same origin goes into the canonical
  and `hreflang` links, the Open Graph tags, `sitemap.xml` and `robots.txt`, which are generated at
  build time.
- The script builds with `VITE_LANDING_ONLY=true`. The output is `apps/web/build/client`:
  `index.html`, `en/index.html`, `404.html`, `assets/`, `lukas/`, `og-*.png`, `robots.txt`,
  `sitemap.xml` and `_headers`.
- There is no `__spa-fallback.html`, and `404.html` is at the top level, so Cloudflare Pages serves
  it (with a 404 status) for any other path instead of treating the site as a single-page app.
- `public/_headers` sets long immutable caching for `/assets/*`, a short cache for the HTML and the
  basic security headers.

## Deploy

```sh
npx wrangler pages deploy apps/web/build/client --project-name lukitas-landing
```

The first run asks you to sign in to Cloudflare and offers to create the `lukitas-landing` project.
Every later run publishes a new deployment of it.

## Custom domain

In the Cloudflare dashboard: Workers & Pages, the `lukitas-landing` project, Custom domains, Set up a
custom domain, and enter `lukitas.andersonlaverde.com`. If the domain's DNS is on Cloudflare, it adds
the record for you; otherwise add the `CNAME` it shows. When the real domain is ready, add it the
same way and rebuild with `VITE_SITE_URL` set to it, so the canonical links and the sitemap point to
the new origin.

## Switching back once the app exists

Stop using `build:landing`: a plain `pnpm --filter @lukas/web build` (without `VITE_LANDING_ONLY`)
keeps the sign-in calls to action, the "Empezar" card and the SPA fallback, and `robots.txt` hides
the app's routes again. Keep passing `VITE_SITE_URL` so the generated files carry the right origin.
Without it the placeholder `https://lukas.app` is used.

## Checking a build

`pnpm --filter @lukas/web e2e:landing-only` builds the landing-only release with a test origin and
runs its end-to-end suite (links, copy, origin, 404 page, accessibility). `pnpm --filter @lukas/web
e2e:landing` does the same for the default build.
