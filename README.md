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

🚧 In development. The design is in [`docs/superpowers/specs/2026-10-20-lukas-design.md`](docs/superpowers/specs/2026-10-20-lukas-design.md).

## Architecture

A monorepo with:

- `apps/api`: TypeScript backend (Hono), Postgres and Better Auth
- `apps/web`: React + Vite
- `apps/mcp`: remote MCP server
- `apps/mobile`: Flutter (Android; iOS later), with a native Kotlin + Glance widget
- `packages/core`, `packages/db`, `packages/importers`: business rules, schema and migrations, importers

## Self-hosting

For now Lukas is offered as a hosted service, and there are no docs for running your own instance. If you're interested, open an issue and we'll take it into account.

## License

[AGPL-3.0](LICENSE). If you offer a modified Lukas as a service, you must publish your changes.
