> Brand renamed to **Lukitas** on 2026-10-21 (an unrelated app already uses "Lukas"); code identifiers keep `lukas`.

# Lukas — Overall Design and Stage 1 (Core & Accounts)

- **Date:** 2026-10-20
- **Status:** approved
- **Project license:** AGPL-3.0
- **Repository language:** everything in the repo (code, docs, commits, UI copy keys) is English. The product UI is localized; Spanish (`es`) is the first locale.

## 1. Context and goal

Lukas is a gamified personal finance app. "Lukas" is how Colombians call money, and **Lukas is also the project's mascot**, the star of the game-like feedback (celebrations, limit warnings, month close). It is built to replace Budge, which the author has used since 2023, with a much simpler and more fun UX.

**Goal of the first version:** reproduce what the author does today in Budge (record transactions, see the month balance, follow a monthly budget per category, analyze spending by category) with a clearer interface that feels like a game.

**Product model:** a service hosted by the author with public sign-up. The code is open source (AGPL-3.0) to welcome contributions. Self-hosting is not offered for now; the README mentions it as possible future work depending on interest.

### Success criteria

1. The author imports their Budge history (CSV) and sees their data since 2023 with no loss.
2. Opening the app or glancing at the widget shows, within one second, **how much is left to spend this month**.
3. Recording an expense from the widget or the app takes under 5 seconds and gives satisfying feedback (animation, haptics, sound).
4. An AI agent (Claude, ChatGPT) connected via MCP can read, create and edit transactions, request reports, and adjust budgets.

### Out of scope (v1)

- Multiple accounts and multiple currencies. The model already has `account` and `currency`, but the UI shows a single EUR account.
- Installment payments.
- Budget rollover between months.
- Google or Apple sign-in.
- iOS app. It will come later from the same Flutter code, plus a native WidgetKit widget.
- Documented self-hosting.

## 2. Product

### 2.1 What is reproduced from Budge

Based on the author's screenshots and export:

| Budge view | In Lukas |
|---|---|
| Month balance + month tabs + income/expenses | Home screen: **remaining budget** big, month balance as secondary figure |
| Daily list of transactions with paid/pending status | Daily list with status and day total |
| Total and per-category budget (%, remaining) | Budget with an unambiguous **spent vs. available** visualization (see 2.3) |
| Analysis: donut by category (expenses/income), paid/pending filter | Donut + category list + month-over-month trend (web) |
| "+" button | Big add button in the app and the widget |

### 2.2 Figure definitions

- **Remaining this month** (headline figure) = Σ effective budgets of the month's expense categories − Σ the month's expenses (paid **and** pending). Expense categories without a budget still count against it.
  - Reference case (October 2026): 2,800.00 € − 2,237.08 € = **562.92 €**.
- **Month balance** (secondary figure) = Σ month income − Σ month expenses.
- **Spent in a category** = −Σ the category's amounts in the month. A positive amount in an expense category (a refund) reduces spending.

### 2.3 Design language

Problem observed in Budge: the budget bar shows what is *left*, so "100 %" in blue means "nothing spent". It reads backwards.

Principles for Lukas:

- **One hero figure per screen.** Everything else is secondary.
- **Bars always fill with what was spent** and change color as they approach the limit (green → amber → red). When over budget, show "X € over" explicitly, never a negative percentage.
- **Big buttons with depth** (solid bottom shadow, Duolingo/Buddy style) that press down when tapped.
- **Multi-sensory feedback through semantic events:** every important action combines animation, haptics and a short sound, e.g. `expenseSaved`, `nearLimit`, `overBudget`, `streak`.
- **Undo is always available** instead of blocking confirmations. Deletes are soft.
- Advanced gamification (streaks, achievements) is Stage 5, but the game-like tone is present from Stage 2.

### 2.4 Onboarding

Shared by web and mobile:

1. Short animated screens about what Lukas does.
2. Create an account / sign in with email (magic link + code).
3. Offer to create a passkey ("Sign in with your fingerprint next time?").
4. Initial setup: pick suggested categories, set a budget per category and optionally import a Budge CSV. With an import, budgets are suggested from average spending.

### 2.5 "Connect your assistant"

Section in web and mobile:

- MCP server URL with a copy button. It is the same for everyone; OAuth identifies the user.
- Steps per client (Claude, ChatGPT, Claude Code and others). The exact steps are verified when building Stage 4, since those menus change.
- OAuth consent screen: "Claude wants to access your finances: read, create and edit transactions".
- List of connected assistants with a revoke button for each.
- Example requests.

## 3. Architecture

### 3.1 Monorepo

```
/
├── apps/
│   ├── api/          # TypeScript backend (Hono) + Better Auth
│   ├── web/          # React + Vite
│   ├── mcp/          # Remote MCP server (TypeScript)
│   └── mobile/       # Flutter (Android; iOS later)
│       └── android/…/widget/   # Native widget, Kotlin + Jetpack Glance
├── packages/
│   ├── core/         # Pure business rules + zod schemas
│   ├── db/           # Drizzle schema + migrations (Postgres)
│   └── importers/    # Importers (first: Budge CSV)
├── docker-compose.yml   # Postgres + Mailpit + api (+ mcp from Stage 4)
└── docs/
```

- **Tooling:** pnpm workspaces and Turborepo for TypeScript. Flutter uses its own toolchain inside `apps/mobile`.
- **Source of truth:** the API. MCP, web, mobile and widget talk to the API; **none of them accesses the database directly**.
- **Contract:** OpenAPI generated from the zod schemas in `core`. The Dart client (Flutter) and the web types are generated from it.
- **Server-side calculations:** the API returns figures already computed, so Flutter and the widget do not duplicate business rules.

### 3.2 Decisions and rationale

| Decision | Rationale |
|---|---|
| TypeScript for api/web/mcp/core | Most mature MCP SDK, shared code, contributor-friendly |
| Flutter for mobile | One codebase for Android and iOS (future); its own rendering engine suits a game-like UI (Rive, Lottie, `flutter_animate`) |
| Native widget (Kotlin + Glance) | No cross-platform framework draws home-screen widgets. The widget shares data with the app via `home_widget` and calls the API to record expenses |
| Native haptics via platform channel | Duolingo-style patterns: `VibrationEffect.Composition` on Android, Core Haptics on iOS. Quality depends on each phone's vibration motor |
| Better Auth | Open source, stores data in our own Postgres, no vendor lock-in or per-user cost; supports email OTP, passkeys and an OAuth server (required for remote MCP) |
| React (not Flutter Web) for web | Better for dashboards and charts, browser performance and contributions |

### 3.3 Stages

Each stage gets its own spec → plan → implementation.

1. **Core & accounts** (detailed in this document, §4–§10).
2. **Web v1:** onboarding, home, transactions, budget, analysis, import, "Connect your assistant".
3. **Mobile + widget:** guest mode first (see Guest mode below), onboarding, quick add, remaining figure, feedback module (haptics, sound, animation), Android widget **with a microphone button** that opens voice quick capture (founder decision, 2026-10-21; see Quick capture below).
4. **MCP:** remote server with OAuth; tools to read, create and edit transactions, generate reports and adjust budgets.
5. **Advanced gamification:** streaks, achievements, rewards.
6. **Automatic capture:** bank alerts and wallet payments become transactions without typing. It comes after Stage 4; its order relative to Stage 5 will be decided later. See Automatic capture below.

The public roadmap page (`/roadmap`) and the landing's "Lo que viene" section show these stages to visitors, with statuses and no dates (Stage 2 web spec §2.8).

#### Quick capture (founder request, 2026-10-21)

Log several transactions from one sentence, such as "gasté 15.000 en el almuerzo y 3.000 en Uber". The flow:

1. The sentence is parsed into an **editable preview**: one card per transaction with amount, category, name and date. Each card can be fixed or removed.
2. One **SAVE N** button stores the whole batch.
3. A single celebration and rule-based message follows, with the total. Undo reverts the whole batch.

It is inspired by the "smart assistant" of an unrelated app. Capture design is not covered by a separate spec yet; each phase gets its own spec → plan.

- **Phase 1, text and voice, no AI (with Stage 3; web too):** a deterministic parser that runs on the device.
  - Amounts: "15.000", "15 mil", "15k", "15 lukas", "4,3 palos" (millions).
  - Separators: "y" and commas.
  - Relative dates: "hoy", "ayer".
  - Categories come from the user's own history through the name → category suggestions that already exist in the API (`GET /v1/transactions/suggestions`).
  - Free, private (the text never leaves the device) and works offline.
  - Needs a batch-create endpoint, or a client loop over `POST /v1/transactions` with one idempotency key per item, plus a batch undo.
  - **Voice:** speech-to-text runs on the device, so it costs nothing. Android uses `SpeechRecognizer`, preferring the on-device recognizer (es-CO); the web uses the Web Speech API. The transcript goes through the same parser. Privacy copy names the platform's speech service when the device sends audio to it.
  - **Widget microphone (Stage 3 v1):**
    - The Android widget has a 🎤 button that opens the app already listening, with "¿En qué gastaste?". It shows the editable preview, and SAVE N stores the batch.
    - Target: under 1 s from tap to listening, with no splash screen and no navigation.
    - Also a Quick Settings tile with the same action.
    - Expense or income comes from the sentence ("gasté…" or "me pagaron…"). If the sentence doesn't say, it defaults to expense.
- **Phase 2, AI fallback (with Stage 4):**
  - For messy sentences ("pagué el almuerzo con Juan, yo puse la mitad").
  - **Requirements:**
    - Opt-in.
    - Honest privacy copy: the sentence is sent to an AI provider.
    - A cheap model with a per-user monthly quota and a project-wide spend cap. Over the cap the app keeps working with the parser alone, so "free forever" holds.
  - Users who connect their own assistant through MCP get the same capability at no cost to the project. The in-app version is for people who don't.

#### Guest mode (founder decision, 2026-10-21)

People can start without an email: no login wall after installing the app or on the web.

- **Built on anonymous accounts:** Better Auth's anonymous plugin creates a real server-side user with no email, and the device keeps the session. The API stays the single source of truth, with no local-only data path and no merge step.
- **Upgrading:** "Guarda tu progreso" links an email (code or magic link) or a passkey to the same user. Nothing is copied, and nothing is lost.
- **Works without an email:** categories, budgets, transactions, recurring payments, the widget and microphone quick capture (no AI), Budge import, and export.
- **Requires an email:**
  - **Sync to a second device:** web and phone, or a new phone. The other device needs a way to sign in.
  - **AI features:** every call costs money, and per-user quotas and abuse control need an identity.
  - **Connecting an assistant through MCP:** the OAuth flow needs a real, recoverable identity.
- **Honest nudges, no nagging:**
  - The nudge comes after about the 10th transaction or the 3rd day, and from settings any time.
  - It says plainly that without an email, losing the phone or deleting the app loses the data.
  - One dismissible reminder per week at most.
- **Cleanup:**
  - Anonymous users inactive for 60 days are deleted together with their data.
  - Beforehand, the app shows an in-app warning on the next open after 45 days ("Tus datos se borrarán en 15 días si no agregas tu correo").
  - Users with an email are never auto-deleted.
- **Abuse limits:** a per-IP rate limit on anonymous sign-up, plus the existing per-user limits.
- **The web demo stays separate:** `/demo` is invented data that resets on reload. Guest mode is your own data without an email.
- **Schedule:**
  - The backend (anonymous plugin, account linking, cleanup job, `isAnonymous` on `GET /v1/me`) can ship before Stage 3.
  - The client flows (mobile first run, web "Empieza ahora" without email, upgrade sheet, gating of sync/AI/MCP) land at the start of Stage 3, for both mobile and web.

#### Automatic capture (founder request, 2026-10-21; Stage 6)

Most people don't keep the habit of logging by hand, so the hard part is getting transactions in without typing. In Colombia, digital wallets are rarely used, while bank alerts from Bancolombia, Nequi, Davivienda and others are common.

Every source produces text. That text goes through the same pipeline as quick capture: per-bank templates first, then the phrase parser, then the optional AI fallback.

- **Review inbox.** Captured transactions are not saved blindly. They land as *to review*, with a nudge such as "Anoté −$370.000 en Transferencias, ¿bien?". One tap confirms it or changes the category. The merchant → category mapping is learned over time.
- **De-duplication.** The same purchase can arrive from two sources, for example Apple Pay and the bank's SMS. Two captures are the same purchase when they have the same amount within a short time window.
- **Open-source bank templates.** One parser per bank and message format, contributed by the community with invented fixtures. Real alerts are never committed. Bank formats change, so templates are versioned and tested.
- **Android: notification listener.** A `NotificationListenerService` that the user enables in system settings reads bank-app and Google Wallet notifications and parses them on the device.
  - Google Play treats notification access as sensitive: it must be core functionality, declared and disclosed. Verify against the current policy before release.
  - Reading SMS is **not** allowed on Google Play for apps that aren't the default SMS handler, and expense tracking isn't an exception. Don't derive SMS content another way either.
- **iPhone: Shortcuts.**
  - Apple Pay payments come from the Wallet *Transaction* automation, which provides amount, merchant and card.
  - Bank SMS and emails come from the Message and Email automations, filtered by sender.
  - All of them call an "Add transaction" App Intent. One shareable shortcut per bank.
  - iOS doesn't let apps read other apps' notifications.
- **Email forwarding (any phone):** a per-user inbound address. The user forwards bank alert emails to it and the server parses them. The email passes through the server, which the privacy copy must say.
- **Later, not free:** Colombia's open-finance regime and aggregators allow direct bank connections, but they charge per connection.

## 4. Data model (Stage 1)

### 4.1 Principles

- Money as an **integer in minor units** (cents) plus an ISO currency code. Never floating-point decimals.
- **Signed amount:** expenses negative, income positive.
- **Every domain table has `user_id`**. Isolation is enforced in the query layer and additionally by Postgres **Row-Level Security**.
- Transaction dates are `date`, with no time or time zone. The user has a `timezone` that defines "today" and "this month".
- Soft delete (`deleted_at`) on transactions, to support undo. Deleting the account removes everything permanently.
- All ids are UUID v7. `created_at` and `updated_at` on every domain table.

### 4.2 Tables

**Better Auth** (managed by the library): `user`, `session`, `verification`, `passkey` and the OAuth plugin tables. The user gets extra fields `timezone` (IANA, e.g. `Europe/Lisbon`) and `locale` (e.g. `es`).

**`accounts`**
| Field | Type | Notes |
|---|---|---|
| id, user_id | uuid | |
| name | text | "Main" |
| currency | char(3) | `EUR` |
| is_default | bool | Exactly one per user, created at sign-up |

**`categories`**
| Field | Type | Notes |
|---|---|---|
| id, user_id | uuid | |
| name | text | Unique per user among non-archived |
| kind | enum `expense` \| `income` | |
| icon | text | Key into the app's icon set |
| color | text | Token from the app's palette |
| sort_order | int | |
| archived_at | timestamptz? | Archived categories are hidden in the UI but keep their history |

**`category_budgets`**: base budget history.
| Field | Type | Notes |
|---|---|---|
| id, user_id, category_id | uuid | `expense` categories only |
| amount | bigint | Cents, ≥ 0 |
| effective_from | date | Always the 1st of a month. Unique per (category_id, effective_from) |

A category's effective budget in month M is the row with the greatest `effective_from` ≤ M. If none exists, the category has no budget that month.

**`transactions`**
| Field | Type | Notes |
|---|---|---|
| id, user_id, account_id, category_id | uuid | |
| name | text | e.g. "continente" |
| amount | bigint | Signed cents, ≠ 0 |
| currency | char(3) | Same as the account's |
| date | date | |
| status | enum `paid` \| `pending` | |
| note | text? | |
| recurrence_id | uuid? | |
| import_id | uuid? | |
| source | enum `app` \| `web` \| `widget` \| `mcp` \| `import` \| `recurrence` | |
| external_hash | text? | Imports only; unique per (user_id, external_hash) |
| deleted_at | timestamptz? | |

Indexes: (user_id, date), (user_id, category_id, date). Partial unique constraint (recurrence_id, date) where recurrence_id is not null.

**`recurrences`**
| Field | Type | Notes |
|---|---|---|
| id, user_id, account_id, category_id | uuid | |
| name, amount | text, bigint | Transaction template |
| frequency | enum `monthly` \| `yearly` | |
| day_of_month | int 1–31 | If the month is shorter, the last day is used |
| month_of_year | int 1–12? | `yearly` only |
| start_date | date | |
| end_date | date? | |

**`imports`**
| Field | Type | Notes |
|---|---|---|
| id, user_id | uuid | |
| source | enum `budge` | |
| file_hash | text | SHA-256 of the file; unique per user among confirmed imports |
| status | enum `preview` \| `confirmed` \| `reverted` | |
| stats | jsonb | Transactions, new categories, skipped duplicates, date range |
| payload | jsonb? | Parsed rows, kept only while in `preview`. Cleared on confirm |

**`idempotency_keys`**: (user_id, key, response, created_at). Purged after 24 h.

## 5. Business rules (`packages/core`)

Pure functions, no I/O, thoroughly tested:

- `monthSummary(month, budgets, transactions)` returns `{ budgetTotal, spent, remaining, income, balance, categories[] }`. Each category has `{ budget, spent, remaining, ratio, state }`, with `state` = `ok` \| `near` (≥ 80 %) \| `over` (> 100 %).
- `effectiveBudget(categoryBudgets, month)`.
- `occurrences(recurrence, month)` returns the dates a recurrence falls on within a month, including the clamp to the month's last day.
- zod schemas for every entity and API input, with rules such as: the amount sign must match the category kind, except refunds (positive in `expense`) and corrections (negative in `income`), which are allowed.

**Recurrence materialization:** when the API computes the summary or lists transactions for a month M ≤ current month + 1, it first inserts the missing occurrences of M as `pending` with `source = recurrence`, using `ON CONFLICT DO NOTHING` on (recurrence_id, date). An occurrence the user deleted (soft) is not regenerated, because the row still exists. No cron required.

## 6. Authentication and security

- **Passwordless sign-in:**
  - **Email:** one email carrying a **6-digit code and a magic link**. The link is `{WEB_URL}/auth/verify?email=…&code=…`; the page (and the Android app via App Links) submits that same code automatically, so there is a single one-time secret per email. The code is used manually when the email is opened on another device. Valid for 10 minutes, single use, at most 3 attempts.
  - **Passkeys (WebAuthn):** offered after the first sign-in. Multiple per user.
  - Sign-up and sign-in are the same flow: an unknown email creates the account.
- **Sessions:** `httpOnly` + `SameSite=Lax` cookie on the web; *bearer* token in secure storage on Flutter and the widget.
- **OAuth (server):** Better Auth acts as the authorization server for MCP clients, with dynamic client registration and PKCE, as the MCP spec requires. v1 scopes: `finance:read` and `finance:write`.
- **Rate limiting** on `/auth/*`, per IP and per email.
- **Email delivery:** Resend in production (behind a swappable `Mailer` interface), Mailpit locally.
- **GDPR:** full export (JSON + CSV), permanent account deletion, minimal privacy policy.

## 7. API (Stage 1)

REST under `/v1`, JSON, generated OpenAPI at `GET /openapi.json`. Every route requires a session except `/auth/*`, `/health` and `/openapi.json`.

| Method and path | Description |
|---|---|
| `GET /health` | Service status |
| `GET /v1/me` · `PATCH /v1/me` | Profile (timezone, locale) |
| `GET /v1/summary?month=YYYY-MM` | Month summary (§5); defaults to the current month in the user's timezone |
| `GET /v1/transactions?month=&category=&status=&cursor=` | Paginated list, date descending |
| `POST /v1/transactions` | Create. Accepts `Idempotency-Key` |
| `PATCH /v1/transactions/:id` · `DELETE /v1/transactions/:id` · `POST /v1/transactions/:id/restore` | Edit, soft delete, restore |
| `GET/POST /v1/categories` · `PATCH /v1/categories/:id` | Category management (archive = `PATCH archived: true`) |
| `PUT /v1/categories/:id/budget` | Body `{ amount, effectiveFrom: "YYYY-MM" }` |
| `GET/POST /v1/recurrences` · `PATCH/DELETE /v1/recurrences/:id` | Recurrences. Deleting one keeps the transactions already generated |
| `GET /v1/reports/by-category?from=&to=&kind=&status=` | Totals and percentages per category (feeds the donut) |
| `GET /v1/reports/trend?from=&to=` | Income, expenses and budget per month |
| `POST /v1/imports` (multipart, `source=budge`) | Parses the file and returns a preview with stats |
| `POST /v1/imports/:id/confirm` · `DELETE /v1/imports/:id` | Confirm, or revert (deletes that import's transactions) |
| `GET /v1/me/export` · `DELETE /v1/me` | Export data, delete account |

**Errors:** `application/problem+json` (RFC 9457) with a stable `code`, e.g. `validation_failed`, `not_found`, `import_duplicate_file`, `budget_category_not_expense`. `validation_failed` includes per-field errors.

## 8. Budge importer (`packages/importers/budge`)

**Observed format** (export "Format version 1"): blocks separated by `###`.

1. Metadata: `Format version,Period,User ID`.
2. Transactions: `Date` (DD-MM-YYYY), `Payment`, `Is paid`, `Amount` (dot decimal, signed), `Currency`, `Account`, `Category`, `Subcategory`, `Goal`, `Description`.
3. Accounts: `Account, Account Balance, Available Balance, Credit Limit, Currency, Is savings, Description`.

**Mapping:**

| Budge | Lukas |
|---|---|
| Date | `date` |
| Payment (trimmed) | `name` |
| Is paid | `status` (`true` → `paid`) |
| Amount | `amount` in cents, exact decimal parsing (no `float`) |
| Currency | `currency`. If it differs from the default account's currency, the row is rejected in v1 and reported in the preview |
| Account | Ignored in v1; everything goes to the default account |
| Category | Find or create a category by name (case-insensitive). `kind` = majority sign of its transactions; icon and color come from a dictionary of common names (supermercado → cart, restaurante → cutlery, casa, transporte, salário…) with a default fallback |
| Subcategory, Goal | Ignored (empty in observed data) |
| Description | `note` |
| — | `source = import`, `import_id`, `external_hash = sha256(date‖name‖amount‖category‖ordinal)` |

- **Duplicates:** rows whose `external_hash` already exists for the user are skipped and counted in the preview. Identical rows within one file (e.g. two identical coffees on the same day) are told apart by their ordinal among identical rows, so overlapping exports still deduplicate.
- **The accounts block and the `User ID`** are ignored and never stored.
- **Budgets:** Budge does not export them. The preview includes the average monthly spending per category to suggest budgets during onboarding.
- **Robustness:** missing blocks tolerated; `\r\n` line endings accepted; BOM ignored. If the format is not recognized, respond `import_unrecognized_format`.

## 9. Local development and CI

- `docker compose up` starts Postgres, Mailpit and `api`. The web runs with `pnpm dev`.
- Drizzle migrations are applied on `api` startup in development.
- A development seed creates a test user with the anonymized sample CSV data.
- **CI (GitHub Actions):** lint, typecheck, unit and integration tests (against a real Postgres) on every PR.
- Repository: README (what it is, how to run it, how to contribute), CONTRIBUTING, AGPL-3.0 license, Conventional Commits.

## 10. Testing (Stage 1)

- **`core` (Vitest):** `monthSummary` with the real October 2026 case (562.92 €), refunds, categories without budget, budget changes across months, `occurrences` on days 29–31 and leap years, sign validation.
- **`importers/budge`:** anonymized fixture with the same structure as the real export (blocks, quotes, commas in names, `Is paid=false`, positive rows in expense categories). Exact amount parsing, deduplication and invalid formats. **The author's real CSV never enters the repo.**
- **`api` (integration, real Postgres):** CRUD flows, summary, recurrence materialization (idempotent), `POST /transactions` idempotency, import preview → confirm → revert, and **cross-user isolation** (A cannot read or modify B's data, even with valid ids of B).
- **Auth:** invalid or expired code, single use, rate limiting.

## 11. Beyond this stage

Stages 2–5 will be specified separately. This document only fixes what they need from Stage 1: `GET /v1/summary` as the single call for the home screen and widget, OAuth ready for MCP, and imports usable from onboarding.
