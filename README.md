<p align="center"><img src="docs/brand/lukas-banner.png" alt="Lukas, the gold coin mascot, waving next to the Lukas wordmark: Tus lukas, por fin claras." width="100%"></p>

# Lukas

**Personal finance that feels like a game.** A monthly budget, an Android app with widgets to log expenses in seconds, a web dashboard with charts, and an MCP server so your AI assistant (Claude, ChatGPT…) can help you with your money.

## Why "Lukas"?

In Colombia we call money **lucas**. One *luca* is a thousand pesos, and from there it means money in general: "¿cuántas lukas te costó?" (how much did it cost you?), "estoy sin lukas" (I'm broke), "me faltan unas lukas para fin de mes" (I'm a few bucks short until the end of the month). It's a warm, everyday word, which is exactly how we want managing your finances to feel.

**Lukas is also the project's mascot.** It keeps you company in the app: it cheers when you log an expense, warns you when a category is getting close to its limit, and celebrates when you close the month within budget. The goal is to make being organized with your money fun, almost addictive.

## What it does

- **What's left to spend this month**, big and always visible, in the app and on the widget.
- **Monthly budget per category**, with bars that fill up with what you've spent and change color as you approach the limit.
- **Daily transactions**, paid or pending, with automatic recurring ones (rent, subscriptions, salary…).
- **Analysis** by category and month-over-month trends.
- **Import from Budge** (CSV).
- **Connect your assistant:** an MCP server so you can ask your AI to log expenses, prepare reports, or adjust your budget.
- **No passwords:** sign in with a magic link or a code sent to your email, or with a passkey.

## Status

🚧 In development. Stage 1 (backend: API, auth, Budge import) is built; web, mobile, MCP and gamification come next. The design is in [`docs/superpowers/specs/2026-10-20-lukas-design.md`](docs/superpowers/specs/2026-10-20-lukas-design.md).

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

### Tests

```bash
pnpm lint && pnpm typecheck && pnpm test
```

Integration tests start a throwaway Postgres in Docker (testcontainers). Without Docker, use the Postgres binaries on your PATH instead:

```bash
LUKAS_TEST_DB=local pnpm test
```

## Self-hosting

For now Lukas is offered as a hosted service, and there are no docs for running your own instance. If you're interested, open an issue and we'll take it into account.

## License

[AGPL-3.0](LICENSE). If you offer a modified Lukas as a service, you must publish your changes.
