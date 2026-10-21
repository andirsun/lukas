# Lukas — Stage 2: Web (landing + app)

- **Date:** 2026-10-21
- **Status:** draft for review
- **Builds on:** `docs/superpowers/specs/2026-10-20-lukas-design.md` (overall design) and the Stage 1 API.
- **Visual references:** `docs/design/stage-2-mockups/` (chosen mockups) and `docs/brand/lukas-mascot-concept.webp` (mascot concept).

## 1. Goal

Ship the first product people can use: a public landing page and a web app that works great on a phone, so the author can stop using Budge before the Android app exists.

**Message:** the questions "¿En qué se me va la plata?" and "¿Cuánto me cuesta vivir?" stop being unanswered. Lukas makes budgeting easy and fun.

### Success criteria

1. The author signs up, imports the Budge history and uses the web app on the phone daily instead of Budge.
2. Logging an expense takes under 5 seconds from the home screen and ends in a celebration.
3. The landing page is indexable in Spanish and English and its text is visible before any 3D or JavaScript-heavy content loads.
4. Everything works in Spanish (default) and English, in night and day themes, on phone and desktop widths.

### Out of scope (this stage)

- PWA (installable app, service worker, offline writes).
- Connecting AI assistants (MCP) — shown as "soon" on the landing page.
- Android app — shown as "soon".
- AI-generated insights (rule-based messages only; AI comes later as an opt-in).
- Streaks, levels and achievements (Stage 5).
- The final mascot artwork and production 3D model (a code-built placeholder ships; see §5.3).

## 2. Product

### 2.1 Languages and URLs

- All routes are English. The UI ships in **Spanish (default)** and **English**.
- Landing: `/` (Spanish) and `/en` (English), both prerendered, each with its own `<title>`, meta description, Open Graph tags and `hreflang` alternates.
- App: language comes from the user's profile `locale` (Stage 1 `PATCH /v1/me`). At sign-up it is taken from the landing page the user came from, else from `navigator.language` (`es*` → `es`, otherwise `en`). Changing it in settings re-renders the UI immediately.
- Money and dates are formatted with `Intl` for the active locale (`562,92 €` / `€562.92`).

### 2.2 Routes

| Route | Screen | Access |
|---|---|---|
| `/`, `/en` | Landing page | Public, prerendered |
| `/sign-in` | Email → code or magic link; "Sign in with fingerprint" when a passkey exists | Public |
| `/auth/verify` | Magic-link target: submits `email` + `code` from the query and signs in | Public |
| `/welcome/*` | Onboarding: offer passkey → pick categories → set budgets → import Budge (optional) → done | Signed in, until onboarding is completed |
| `/app` | Home | Signed in |
| `/app/categories/:id` | Category detail: that month's transactions and its budget | Signed in |
| `/app/insights` | Donut by category, month-over-month trend, "How much does living cost me?" | Signed in |
| `/app/recurring` | Recurring transactions | Signed in (avatar menu) |
| `/app/categories` | Create, edit, archive categories | Signed in (avatar menu) |
| `/app/settings` | Time zone, language, theme (auto/night/day), sound, passkeys, import, export, delete account | Signed in (avatar menu) |

A signed-out visit to `/app/*` goes to `/sign-in` and returns to the original route after signing in. A signed-in user without `onboardingCompletedAt` is sent to `/welcome`.

### 2.3 Landing page

Reference: `docs/design/stage-2-mockups/landing.html`.

- **Hero** (revised 2026-10-21 by the founder): a tilted handwritten annotation **"¡Gratis, y siempre lo será!"**, the headline **"Tus lukas, por fin claras."** with "lukas" on a gold marker highlight (English: "Your money, finally clear."), the lead **"Lukas es tu presupuesto, y te va a dar gusto cuidarlo."** plus a short description, and one primary action: **Empieza ahora / Get started** → `/sign-in`. Under it: "Gratis para siempre · Código abierto · Sin contraseñas" (open source links to the GitHub repo). Lukas is never described as a game, the app is free forever and open source, the mobile app is Android and iOS, and imports come from other apps (Budge today, Buddy and others soon). Privacy copy only claims what is true today.
- **Lukas 3D** (§5.3) beside or above the hero: eyes and body follow the cursor (desktop) or touch / device tilt (phone, where allowed); the character travels with the scroll, changing pose per section; hovering or tapping makes it jump or spin.
- **"Úsalo como prefieras / Use it your way":** three cards — Web (active, "Start"), Android app ("soon"), With your AI — Claude / ChatGPT ("soon").
- Sections explaining the product (what you spend on, budgets that warn you, import from Budge), an FAQ, and a footer with language switch and the privacy policy.

### 2.4 Sign-in and onboarding

- `/sign-in`: email field → "send code". The page shows a 6-digit code input; the same email carries a magic link to `/auth/verify`. If the browser offers a passkey for this site, a "Sign in with fingerprint" button is shown first.
- After the first sign-in, `/welcome` runs once:
  1. **Passkey offer:** "¿Entrar con tu huella la próxima vez?" (skippable).
  2. **Categories:** suggested categories (Supermercado, Restaurante, Casa, Transporte, Ocio, Suscripciones, Vida, Salario…) as toggles with their icon and color; at least one expense category.
  3. **Budgets:** an amount per chosen expense category; the running total is shown as "what you can spend per month".
  4. **Import from Budge (optional):** upload the CSV → preview (rows, duplicates, rejected rows, new categories) → confirm. When an import happens before step 3, budgets are prefilled with `averageMonthlySpending`.
  5. **Done:** celebration with Lukas, then `/app`.
- Completing step 5 sets `onboardingCompletedAt`.

### 2.5 Home (`/app`)

Reference: `docs/design/stage-2-mockups/home.html` (options 1 and 2).

- Header: logo, month selector (current month by default; previous months browsable), avatar menu.
- **Lukas** with a message bubble (rule-based message, §4.4) and a mood derived from the month: `happy` (all categories ok), `worried` (any category near or over), `celebrating` (right after a save, or month closed within budget).
- **Hero card:** "Te quedan este mes" + `remaining` (big, animated count), a bar filled with what was spent, "Gastado X de Y".
- **Segmented control: Presupuestos ⇄ Movimientos** (tap or swipe).
  - **Budgets:** one row per expense category: icon, name, budget, a bar that fills with spending and changes color by state (`ok` green, `near` amber, `over` red), and the remaining amount in words ("Quedan 46,33 €" / "Te pasaste 14,12 €"). Tapping a row opens the category detail.
  - **Transactions:** grouped by day, newest first, today on top; upcoming pending transactions shown with a **PENDIENTE** badge. Tapping the badge marks the transaction as paid (with a small celebration). Tapping a row opens the edit sheet.
- **Bottom bar:** Home · **＋** (raised center button) · Insights. On desktop widths it becomes a left sidebar (Home, Insights, Recurring, Categories, Settings) and the home screen shows budgets and recent transactions side by side.

### 2.6 Add / edit transaction

Reference: `docs/design/stage-2-mockups/add-transaction.html`.

- Opens as a bottom sheet from ＋ (or from a transaction row, for editing).
- Expense / income toggle; **amount first** with a large numeric keypad.
- **Name field always visible**, optional: its placeholder shows the name that will be used (the category's name). Under it, **recent name shortcuts**; tapping one fills the name **and** selects its usual category. Typing filters the shortcuts, each labelled with its category.
- Category chips (most used first, "more" for the rest); date defaults to today in the user's time zone; optional note; paid/pending.
- **Save** → sheet closes → celebration (Lukas, confetti, sound, vibration) → toast with the rule-based message, **Undo** and **Name it** (when saved without a name).
- Edit mode adds delete (soft, with undo).

### 2.6b Try-before-signup demo (added 2026-10-21)

To lower the barrier of creating an account, `/demo` lets anyone use the full app with an invented user, "Valentina (demo)": 3 months of transactions, budgets (one category over, one near), recurring rent/Spotify/salary. Everything works — add/edit/delete transactions, create categories and budgets, mark pending as paid, insights — against an in-memory backend in the browser that applies the same `@lukas/core` rules and answers the same API shapes. Nothing is saved anywhere; reloading the page resets the demo. A sticky banner says it's a demo with invented data and offers "Crear mi cuenta". The landing hero adds a secondary call to action, "Pruébalo sin cuenta". Settings that don't apply (export, delete account, passkeys, import) are disabled with a note.

### 2.7 Other screens

- **Category detail:** the month's transactions in that category, its budget with an edit action (`PUT /v1/categories/:id/budget` from the selected month), rename / icon / color, archive.
- **Insights:** donut by category (expenses or income; paid/pending filter) for the selected month or range; month-over-month trend (income, expenses, budget); **"¿Cuánto me cuesta vivir?"**: average monthly spending over the last 6 complete months, per category, split into fixed (categories with active recurrences) and variable.
- **Recurring:** list with next date; create / edit / delete.
- **Categories:** list (with archived toggle), create, edit, archive.
- **Settings:** profile time zone and language, theme (auto / night / day), sound on/off, passkeys (add / remove), import from Budge, export (JSON / CSV), delete account (typed confirmation).

## 3. Design system

Reference: `docs/design/stage-2-mockups/theme-arcade-day-night.html`.

### 3.1 Tokens

CSS variables, two themes (`night`, `day`) plus `auto` (follows `prefers-color-scheme`), persisted per device:

| Token | Night | Day | Use |
|---|---|---|---|
| `--brand` | `#8b5cff` | `#7b3df0` | Primary actions |
| `--brand-edge` | `#3f22a3` | `#4a2bbf` | Pressable bottom edge |
| `--good` | `#7cffb2` | `#16c172` | Remaining, `ok` |
| `--near` | `#ffb547` | `#ff9f1c` | `near` |
| `--over` | `#ff5c7a` | `#f0386b` | `over` |
| `--gold` | `#ffe66d` | `#ffd23f` | Lukas, highlights |
| `--bg` | radial `#3a1f6e` → `#15122b` | radial `#e9ddff` → `#f7f4ff` | Page background |
| `--surface` / `--surface-edge` | `#241f48` / `#0f0c22` | `#ffffff` / `#d6ccf5` | Cards and their solid shadow |

- Type: **Fredoka** (figures, headings), **Nunito** (text), self-hosted.
- Radii 14–24 px; every pressable element has a solid bottom edge that collapses on press.
- All text/background pairs meet WCAG AA in both themes.

### 3.2 Components (`apps/web/src/ui`)

`PressButton` (primary / secondary / ghost), `PressCard`, `BudgetBar` (`ok` / `near` / `over`), `Money` (locale formatting, animated count-up for hero figures), `Sheet` (bottom sheet with drag-to-close), `Toast` (with actions), `SegmentedControl`, `PendingBadge`, `MonthPicker`, `Keypad`, `CategoryChip`, `Lukas` and `Lukas3D` (§5.3).

### 3.3 Feedback

One `feedback` module maps semantic events to animation, sound and vibration:

| Event | When |
|---|---|
| `tap` | Any pressable |
| `expenseSaved` / `incomeSaved` | Transaction created |
| `paid` | Pending marked as paid |
| `nearLimit` / `overBudget` | Save pushed a category to `near` / `over` |
| `undo` | Undo |

- Animation via Motion; short sounds (mutable in settings); vibration via the Vibration API where available (Android browsers; not available in iOS Safari).
- `prefers-reduced-motion`: animations are reduced to fades and `Lukas3D` is replaced by a static image.

## 4. Data and API

### 4.1 Talking to the API

- Same site: in development Vite proxies `/api/*` to the API; in production `/api/*` on the web origin is routed to the API. The web sets `API_URL` accordingly so Better Auth issues cookies for the web's site.
- Auth: Better Auth React client with the email-OTP and passkey plugins; session cookie (`httpOnly`).
- Typed client generated from `/openapi.json` (`openapi-typescript` + `openapi-fetch`) with a script; CI fails if the generated types are stale.
- Server state with TanStack Query. Creating, editing, deleting, restoring and marking paid are **optimistic**: the summary, bars and lists update immediately and roll back with an error toast if the request fails. `POST /v1/transactions` sends an `Idempotency-Key`.

### 4.2 Backend additions

1. **`GET /v1/transactions/suggestions?q=&limit=`** — recent distinct transaction names (case-insensitive, most recent first, default limit 8), each with the category it was most often used with. With `q`, names that start with or contain `q`. Excludes soft-deleted rows and archived categories.
2. **`GET /v1/reports/cost-of-living?months=6`** — for the last `months` complete months (1–24, default 6) in the user's time zone: per expense category, the average monthly spending and whether it is `fixed` (has an active recurrence) or `variable`; plus `total`, `fixed` and `variable` averages.
3. **Onboarding flag** — `user.onboarding_completed_at` (nullable timestamp); `GET /v1/me` returns `onboardingCompletedAt`; `PATCH /v1/me` accepts `{ onboardingCompleted: true }`.
4. **Rule-based messages** — a pure function in `packages/core`:
   `lukasMessage(input: { summary: MonthSummary; today: IsoDate; event?: { kind: "saved" | "paid"; categoryId: string; amount: number } }): { key: LukasMessageKey; params: Record<string, string | number> }`.
   Keys for v1: `first_of_day`, `on_track`, `near_limit`, `over_budget`, `income_received`, `pending_paid`, `month_last_day`, `month_closed_green`. The web owns the copy: several variants per key per language, chosen at random. The same function serves Android and MCP later.

### 4.3 Errors

- Every API `code` maps to a friendly message in both languages; unknown codes fall back to a generic message.
- 401 → `/sign-in?next=<current route>`.
- Network failure → toast "No hay conexión, inténtalo de nuevo" and the optimistic change is rolled back.

## 5. Architecture

### 5.1 Stack

- `apps/web`: React 19, **React Router 7** in framework mode with `ssr: false` and `prerender: ["/", "/en"]` — the landing pages are static HTML at build time; the app is a client-rendered SPA. Deployed as static files.
- TypeScript, Vite, Tailwind CSS (tokens from §3.1 as CSS variables), Motion, TanStack Query, Recharts, i18n with ICU messages (`es` default, `en`), React Three Fiber + drei for `Lukas3D`.

### 5.2 Layout

```
apps/web/
├── app/
│   ├── routes/          # landing (/ and /en), sign-in, auth/verify, welcome/*, app/*
│   ├── ui/              # design-system components (§3.2)
│   ├── features/        # home, add-transaction, insights, onboarding, settings…
│   ├── lukas/           # Lukas (2D) and Lukas3D
│   ├── feedback/        # semantic feedback events (§3.3)
│   ├── i18n/            # es.json, en.json, formatting helpers
│   └── api/             # generated types, client, query hooks
├── .storybook/
└── e2e/                 # Playwright
```

### 5.3 Lukas (mascot)

- Concept: `docs/brand/lukas-mascot-concept.webp` — a chubby 3D gold coin with a thick ridged edge, big eyes, rosy cheeks, dark purple arms and legs, pink sneakers.
- **`Lukas3D` (landing):** built procedurally in three.js for v1 (coin with edge and rim, eyes with pupils, cheeks, simple limbs) with the concept's colors. Behaviors: idle bob and blink; pupils and slight body rotation follow the pointer; on touch devices it follows the last touch and, where permitted, device orientation; scroll-driven choreography (moves alongside sections, changes pose per section, celebrates next to the final call to action); hover/tap → jump or spin. Loaded lazily after the hero text renders; replaced by a static image under `prefers-reduced-motion`, without WebGL, or on low-memory devices.
- **`Lukas` (app):** a lightweight 2D rendering of the same character with `mood` = `happy` | `worried` | `celebrating`.
- Both accept replaceable assets (a GLB model for `Lukas3D`; images or a Rive file for `Lukas`) so the final artwork drops in without code changes elsewhere.

## 6. Testing and quality

- **Vitest:** `lukasMessage` rules, formatting helpers, query-hook logic.
- **Storybook (with the Vitest addon):** a story per component in every state, in night and day themes and both languages; stories run as browser tests, including interactions (add-transaction sheet: type amount, pick a shortcut that fills name and category, save, undo; marking a pending transaction paid). Accessibility checked with the a11y addon.
- **Playwright (against the real API via Docker Compose):** sign-up with the code read from Mailpit → onboarding with the sample Budge CSV → add an expense and see "remaining" drop → switch month → switch language and theme. Each flow runs at phone and desktop viewports; axe checks on every page.
- **API:** integration and cross-user isolation tests for the suggestions and cost-of-living endpoints, and for the onboarding flag.
- **Performance:** landing text visible without JavaScript; initial JavaScript under 300 KB gzipped excluding the lazily loaded 3D bundle.
- **CI:** web lint, typecheck, Vitest, Storybook tests and Playwright (Docker on the runner) are added to the existing workflow.
