# Lukitas — Stage 3b: the app looks exactly like the web, with budgets and insights

- **Date:** 2026-10-23
- **Status:** draft for review
- **Builds on:** `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md` (Stage 3). This spec amends it; where they differ, this one wins.
- **Why:** the founder saw the first APK and asked for the app to look exactly like the web. Stage 3 only shared the design tokens (colours, radii, sizes). It did not share fonts, components or screen layouts, and no review compared the app with the web picture by picture.

## 1. Goal

The app looks like the web app at phone width: same fonts, same components, same screens, same motion. It also gains the two parts of the web's home that Stage 3 left out: **Presupuestos** and **Análisis**, both working inside the app.

### Founder decisions (2026-10-23)

1. **The reference is the web.** Every screen the app shares with the web must match the web's Storybook story at 412 × 915, in night and in day.
2. **Presupuestos and Análisis work in the app** (not links to the web). This widens Stage 3's scope A.
3. **The 🎤 goes next to the ＋** in the bottom bar, in the same style. It is the only addition to the web's layout.

### Success criteria

1. For each screen and component in §3, a side-by-side picture (web story | app) shows no visible difference except those listed in §5.
2. Presupuestos: the person sees each category's budget bar for the month, opens a category, sees its movements and sets or changes its budget, as on the web.
3. Análisis: the same charts and figures as the web's Insights for the chosen month.
4. Everything from Stage 3 keeps working: its tests stay green, and the widget, voice, notices and guest mode are unchanged in behaviour.

## 2. Foundations

- **Fonts:** Fredoka (display: titles, amounts, buttons) and Nunito (text), the same weights the web uses (`apps/web/app/styles/tokens.css` `--font-display`, `--font-text`; `apps/web/app/styles/fonts.ts`). Both are SIL OFL 1.1; their licences go in About. They are bundled, never fetched.
- **Text styles:** taken from the web's CSS for each component (size, weight, letter spacing, line height, uppercase where the web uses it), not only from `tokens.json`. The generated Dart tokens gain what the web's CSS adds on top of `tokens.json`; the web stays the source.
- **Surfaces:** the web's background gradient, edges and pressed "3D" shadows (`shadow-edge-*`), borders and radii, as CSS defines them.
- **Lukitas:** the same sprite sheets, sizes and placement as the web.
- **Motion:** the web's motion tokens, as Stage 3 already does.

## 3. What gets matched

### 3.1 Components (ported one by one from `apps/web/app/ui`)

`PressButton`, `PressLink`, `Sheet`, `Keypad`, `AmountField`, `NameField`, `SwipeRow`, `TransactionRow`, `CategoryRow`, `CategoryChip`, `BudgetBar`, `Money`, `PendingBadge`, `LukasBubble`, `MonthPicker`, `SegmentedControl`, `BottomBar` (plus the 🎤), `Toast`, `ConfirmSheet`, `PageHeader`.

### 3.2 Screens

| Screen | Web reference (Storybook) | Notes |
|---|---|---|
| Home: header, hero, tabs, movements | `home-home--*`, `demo-screens--home-in-pesos` | Header with the "Lukitas" wordmark, month arrows ‹ ›, the face button. Moving between months is new in the app. |
| Home: Presupuestos tab | `home-home--budgets`, `ui-categoryrow--*`, `ui-budgetbar--*` | New, working. |
| Category detail and budget sheet | `manage-categories--*` (detail and BudgetSheet stories) | New, working: the category's movements for the month, set or change its budget. |
| Análisis | `insights-insights--*` | New, working: donut by category, trend, cost of living, from `/v1/reports/*`. |
| Add sheet | `home-home--*` sheet stories, `ui-keypad--*`, `ui-sheet--*` | |
| Entry (sign-in, code, verify) | `sign-in-signin--*`, `sign-in-verify--*`, `sign-in-codeinput--*` | The guest button keeps Stage 3's place and copy, in the web's button style. |
| Passkey offer | `sign-in-passkeyoffer--*` | |
| Settings | `manage-settings--*` | Plus the app-only rows from Stage 3 (voice model, notices, widget, server), in the web's row style. |
| Celebration and toasts | `feedback-celebration--*`, `ui-toast--*` | |

### 3.3 App-only screens

Quick capture, "Guarda tu progreso" and the model download have no web story. They are built from the components in §3.1 and follow the web's sheet and settings language. The founder reviews them by picture.

### 3.4 Still on the web

Category management (create, rename, archive), recurring payments, import, onboarding and the landing stay on the web, reached from Settings' "Más en la web". The widget keeps Android's look (Glance can't use the app's fonts), using the same colours.

## 4. How parity is checked

- **A parity harness** (`apps/mobile/tool/parity/`):
  - takes each listed web story at 412 × 915 with Playwright, in night and day;
  - renders the matching Flutter screen as a golden at the same logical size, from the same fixture data (the web's story fixtures exported as JSON, so both read identical movements, budgets and names);
  - writes one side-by-side image per pair, plus a pixel-difference overlay, into a review folder.
- **Each task's review** looks at those pictures first, then the code.
- **The goldens become the app's regression tests.** The web screenshots are regenerated only when the web changes.

## 5. Allowed differences

- The system status and navigation bars.
- The 🎤 next to the ＋.
- Text antialiasing between Chrome and Flutter's renderer (a one-pixel wobble, not a different size or weight).
- The demo banner, which is web-only.

## 6. Risks

- **Size:** this is about as much UI work as Stage 3's app tasks. Budgets and insights are new data flows in the app.
- **Fixture drift:** if the web's fixtures and the app's diverge, the pictures differ for the wrong reason. Hence one shared JSON export.
- **Charts:** the web draws its charts with its own SVG geometry (`chart-geometry.ts`). The app ports that geometry rather than using a chart library, so the shapes match.
