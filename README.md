<p align="center"><img src="docs/brand/lukas-banner.png" alt="Lukitas, the gold coin mascot, waving next to the Lukitas wordmark: Tus lukas, por fin claras." width="100%"></p>

# Lukitas

**Your budget, and you'll actually enjoy looking after it.** Log an expense in seconds and see where your money goes: a monthly budget on the web, an Android and iOS app with widgets (soon), and an MCP server so your AI assistant (Claude, ChatGPT…) can help you with your money (soon).

Lukitas is **free forever and open source** ([AGPL-3.0](LICENSE)): anyone can read the code and check what it does with your data.

## Why "Lukitas"?

In Colombia we call money **lukas** (spelled *lucas* in Chile, Argentina and Peru). One *luka* is a thousand pesos, and from there it means money in general: "¿cuántas lukas te costó?" (how much did it cost you?), "estoy sin lukas" (I'm broke), "me faltan unas lukas para fin de mes" (I'm a few bucks short until the end of the month). It's a warm, everyday word, which is exactly how we want managing your finances to feel.

**Lukitas is the affectionate diminutive: little lukas.** It is also the project's mascot, a gold coin that keeps you company in the app: it cheers when you log an expense, warns you when a category is getting close to its limit, and celebrates when you close the month within budget. The goal is for looking after your money to feel good, not like homework.

## What it does

- **What's left to spend this month**, big and always visible, in the app and on the widget.
- **Monthly budget per category**, with bars that fill up with what you've spent and change color as you approach the limit.
- **Daily transactions**, paid or pending, with automatic recurring ones (rent, subscriptions, salary…).
- **Analysis** by category and month-over-month trends.
- **Import your history from other apps:** Budge today (CSV); Buddy and others soon.
- **Connect your assistant:** an MCP server so you can ask your AI to log expenses, prepare reports, or adjust your budget.
- **No passwords:** sign in with a magic link or a code sent to your email, or with a passkey.

## Status

🚧 In development. Stage 1 (backend: API, auth, Budge import) is built; web, mobile (Android and iOS), MCP and celebrations (streaks, achievements) come next. The design is in [`docs/superpowers/specs/2026-10-20-lukas-design.md`](docs/superpowers/specs/2026-10-20-lukas-design.md).

## Architecture

A monorepo with:

- `apps/api`: TypeScript backend (Hono), Postgres and Better Auth
- `apps/web`: React + Vite
- `apps/mcp`: remote MCP server
- `apps/mobile`: Flutter (Android; iOS later), with a native Kotlin + Glance widget
- `packages/core`, `packages/db`, `packages/importers`: business rules, schema and migrations, importers

## Local development

Requirements: Node 22, pnpm 12 and Docker.

```bash
pnpm install
cp .env.example .env
docker compose up -d          # Postgres, Mailpit and the API on http://localhost:3000/api
pnpm --filter @lukas/api seed # creates dev@lukas.test with sample data
```

Sign in without a password: request a code, then open Mailpit at http://localhost:8025 to read it.

```bash
curl -X POST localhost:3000/api/auth/email-otp/send-verification-otp \
  -H 'content-type: application/json' -d '{"email":"dev@lukas.test","type":"sign-in"}'
curl -i -X POST localhost:3000/api/auth/sign-in/email-otp \
  -H 'content-type: application/json' -d '{"email":"dev@lukas.test","otp":"<code>"}'
# use the set-auth-token response header as a bearer token:
curl localhost:3000/api/v1/summary -H 'authorization: Bearer <token>'
```

The API is documented at http://localhost:3000/api/openapi.json. Its routes live under the path of `API_URL` (`/api` in `.env.example`, so the web app can proxy `/api` from its own origin).

To run the API outside Docker, start only the services with `docker compose up -d postgres mailpit` and run `pnpm --filter @lukas/api dev`. On the host, Postgres listens on port 5433 and Mailpit SMTP on 1026, so they do not clash with a local Postgres or mail bridge.

### Web app

With the stack up (`docker compose up -d`), start the web app:

```bash
pnpm --filter @lukas/web dev   # http://localhost:5173
```

The landing is at `/`, the app at `/sign-in` and `/app`, and a demo without an account at `/demo`. Vite proxies `/api` to the API on port 3000, so the browser talks to one origin (`API_URL` and `WEB_URL` in `.env` point at it). Sign in with any email and read the code in Mailpit at http://localhost:8025. The components have stories: `pnpm --filter @lukas/web storybook` (http://localhost:6006).

### Tests

```bash
pnpm lint && pnpm typecheck && pnpm test
```

`pnpm test` runs the unit tests, the API's integration tests and every Storybook story (rendered in Chromium, with its interactions and an accessibility check). The first time, install the browser: `pnpm --filter @lukas/web exec playwright install chromium`.

Integration tests start a throwaway Postgres in Docker (testcontainers). Without Docker, use the Postgres binaries on your PATH instead:

```bash
LUKAS_TEST_DB=local pnpm test
```

End-to-end tests drive the web app in Chromium at phone and desktop sizes, against the dev stack. They read the sample data's months (September and October 2026) against a fixed date, so start the API with its clock pinned to it, then run them (Playwright starts `pnpm dev` unless it is already running):

```bash
E2E_NOW=2026-10-21T15:00:00Z docker compose up -d --build
pnpm --filter @lukas/web e2e
```

A spec that reads a month pins its page the same way, with `pinClock(page)` from `apps/web/e2e/helpers.ts`. The landing is tested as it ships, built first: `pnpm --filter @lukas/web e2e:landing` (the full site), `e2e:landing-only` and `e2e:landing-only-app` (the landing-only release, without and with an app). CI runs all of these on every pull request.

## Deploying

- **The landing page** ships on its own as static files (Cloudflare): [`docs/deploy/landing.md`](docs/deploy/landing.md), with its config in [`deploy/landing/`](deploy/landing/).
- **A personal install** runs the whole app for one person on one machine, behind a Cloudflare tunnel, with an email allowlist and daily backups: [`docs/deploy/personal.md`](docs/deploy/personal.md), with the stack and scripts in [`deploy/personal/`](deploy/personal/README.md).
- **The API** on its own: [`docs/deploy/api.md`](docs/deploy/api.md).

## Self-hosting

For now Lukitas is offered as a hosted service, and there are no docs for running your own instance beyond the personal install above. If you're interested, open an issue and we'll take it into account.

## License

[AGPL-3.0](LICENSE). If you offer a modified Lukitas as a service, you must publish your changes.
