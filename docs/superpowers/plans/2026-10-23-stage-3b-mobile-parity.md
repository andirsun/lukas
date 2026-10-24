# Stage 3b: the app looks exactly like the web — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Android app match the web at phone width, picture for picture, and make Presupuestos and Análisis work in the app.

**Architecture:**
- A parity harness pairs each web Storybook story (taken with Playwright) with a Flutter golden built from the same JSON fixtures, and writes side-by-side and difference images.
- The web's UI components are ported one by one into `apps/mobile/lib/ui/`, and the screens are rebuilt from them.
- Budgets and insights get repositories over the existing API routes. Behaviour from Stage 3 stays as it is: its tests remain green.

**Tech Stack:**
- **App:** Flutter 3.47.7 (riverpod, go_router), with bundled Fredoka and Nunito fonts.
- **Harness:** Playwright (already in `apps/web`) and Storybook 10.

**Spec:** `docs/superpowers/specs/2026-10-23-stage-3b-mobile-parity-design.md`. It amends `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md`, so read both.

## Global Constraints

- **The web is the reference.** A shared screen or component must match its web story at 412 × 915, in night and in day. Exceptions (spec §5): the system bars, the 🎤 next to the ＋, a one-pixel antialiasing wobble, and the web-only demo banner.
- **Port from the web's code**, never from memory or screenshots: CSS values, sizes, weights, spacing and motion come from `apps/web/app/ui/*`, `apps/web/app/styles/*` and the feature components.
- **Fonts:** Fredoka (display) and Nunito (text), in the weights the web loads (`apps/web/app/styles/fonts.ts`). They are bundled from the `@fontsource` packages' files or upstream OFL releases, never fetched at runtime. Their OFL licences go in About, and `check-licenses.sh` stays green.
- **No Google Play Services.** `scripts/check-no-google.sh` passes. Free licences only.
- **Copy:** user copy goes in the ARB files (es and en), reusing the web's catalogue wording.
- **Stage 3's tests stay green.** Behaviour tests may change only where the layout moved, never where the behaviour did. Goldens are regenerated deliberately and reviewed as pictures.
- **Commits:** path-specific `git add`, no Co-Authored-By line, no push. Never touch the `lukitas-personal-*` containers or `deploy/personal/.env`.
- **Toolchain:** Flutter is at `~/development/flutter/bin` and must be on PATH for every command chain. JDK 17 is set up per `docs/mobile/setup.md`.

## Review Focus

1. **Long text and big amounts:** a 40-character category name, "$1.500.000.000" and a long movement name truncate or wrap exactly as the web does, with no overflow stripes. Tested in Tasks 3, 4 and 5.
2. **The phone's font size at 130%:** no overflow or clipped buttons on home, the add sheet and settings. Tested in Tasks 5, 8 and 10.
3. **A month with no data, and moving months while offline:** the empty state matches the web's `home-home--empty-month`. Moving to another month offline says so and never shows another month's cache. Tested in Task 5.
4. **Day theme on every screen:** every parity pair exists in day as well as night. Covered by Task 2's harness and each screen task.
5. **A budget save or insights load that fails:** the web's error toast or ScreenError appears, the last figures stay, and nothing is lost. Tested in Tasks 6 and 7.

---

### Task 1: Foundations: fonts, text styles, surfaces

**Files:**
- Create: `apps/mobile/assets/fonts/` (Fredoka and Nunito at the web's weights), `apps/mobile/lib/theme/text_styles.dart`, `apps/mobile/lib/theme/surfaces.dart`
- Modify: `apps/mobile/pubspec.yaml` (fonts), `apps/mobile/scripts/gen-tokens.dart` and `lib/theme/tokens.g.dart` (CSS-only values the web adds on top of tokens.json, generated from the web's CSS where it is machine-readable), `lib/theme/*` theme setup, `lib/settings/licenses.dart` and the licence assets (OFL)
- Test: `apps/mobile/test/theme/text_styles_test.dart`, `test/settings/licenses_test.dart`

**Interfaces:**
- **Produces:**
  - `LkText` text styles named after the web's classes or uses: `display`, `amountXl`, `title`, `body`, `label`, `caption` and `eyebrow` (uppercase with letter spacing). Each holds a font family, weight, size, height and letter spacing taken from the web.
  - `LkSurface`: background gradient, `edgeShadow(size)` for the web's `shadow-edge-*`, and border and radius helpers.

- [ ] **Step 1: Failing tests.**
  - `the display and text families are Fredoka and Nunito`.
  - Each `LkText` style has the exact size and weight its web source declares. Name the CSS file and line in a comment next to each expectation.
  - `About lists Fredoka and Nunito under the SIL Open Font License 1.1`.
- [ ] **Step 2:** Implement. Load the fonts in golden tests through a shared `loadAppFonts()` in `test/support/fonts.dart`, so goldens never use Ahem.
- [ ] **Step 3:** Run `flutter test` and `flutter analyze`. Expected: PASS. Stage 3's goldens change only in font: regenerate them and look at the pictures.
- [ ] **Step 4:** Commit `feat(mobile): the web's fonts, text styles and surfaces`.

### Task 2: The parity harness

**Files:**
- Create: `apps/web/scripts/parity-fixtures.ts`, `apps/web/scripts/parity-shots.ts`, `apps/mobile/test/parity/` (fixtures, web shots, app goldens), `apps/mobile/test/support/parity.dart`, `apps/mobile/tool/parity/compose.dart`, `docs/mobile/parity.md`
- Modify: `apps/web/package.json` (scripts `parity:fixtures` and `parity:shots`)

**Interfaces:**
- **Produces:**
  - `parity.json`, a list of pairs `{id, storyId, theme: "night"|"day", appTest}`, in `apps/mobile/test/parity/`. Later tasks append to it.
  - `parityGolden(WidgetTester t, String id, Widget screen, {required String theme})` in `test/support/parity.dart`. It renders at logical 412 × 915 with device pixel ratio 2, real fonts and the fixture's fake clock, and matches `test/parity/app/<id>-<theme>.png`.
  - `ParityFixtures.load(String storyId)`, which returns the JSON API responses that story's fake fetch serves.
  - `dart run tool/parity/compose.dart`, which writes `build/parity/<id>-<theme>.png`: web on the left, app on the right, a pixel-difference overlay under them, and the percentage of differing pixels.

- [ ] **Step 1:** Write `parity-fixtures.ts`. For each story listed in `parity.json`:
  - build the story's fake fetch with the same options as the story, from `features/home/story-harness.tsx` and the other harnesses;
  - pin the clock with `demo/fake-clock.ts` at the story's date;
  - call the endpoints the app screen needs;
  - write the responses to `test/parity/fixtures/<storyId>.json`.
- [ ] **Step 2:** Write `parity-shots.ts`. It builds static Storybook, opens each story's iframe at 412 × 915 with deviceScaleFactor 2, sets the theme the way the stories' theme toggle does, waits for fonts and animations to settle, and saves `test/parity/web/<id>-<theme>.png`.
- [ ] **Step 3:** First pair, written as a failing test: `money parity` against `ui-money--*`, in night and day. Port `Money` (Task 3 completes the rest of the components) and make it pass.
- [ ] **Step 4:** Run:

  ```sh
  pnpm --filter @lukas/web parity:fixtures
  pnpm --filter @lukas/web parity:shots
  flutter test test/parity
  dart run tool/parity/compose.dart
  ```

  Expected: the Money pair shows no visible difference. Under 1% of pixels differ, and those differ only in antialiasing.
- [ ] **Step 5:** Document the loop in `docs/mobile/parity.md`. Commit `test(mobile): a parity harness that pairs each web story with the app's golden`.

### Task 3: Components, batch 1 (small parts)

**Files:**
- Create: `apps/mobile/lib/ui/` with `press_button.dart`, `press_link.dart`, `money.dart` (from Task 2), `pending_badge.dart`, `category_chip.dart`, `segmented_control.dart`, `month_picker.dart`, `budget_bar.dart`, `lukas_bubble.dart`, `page_header.dart`
- Test: `apps/mobile/test/ui/*_test.dart` with parity goldens against `ui-pressbutton--*`, `ui-presslink--*`, `ui-pendingbadge--*`, `ui-categorychip--*`, `ui-segmentedcontrol--*`, `ui-monthpicker--*`, `ui-budgetbar--*` and `lukas-lukasbubble--*`

**Interfaces:**
- **Produces:** one widget per web component, with the web component's props as named parameters. For example, `PressButton({required Widget child, VoidCallback? onPressed, PressTone tone, PressSize size})`. Each Dart file's header comment names its web source file.

- [ ] **Step 1:** Add the pairs to `parity.json` and run the harness. The goldens fail because the widgets are missing.
- [ ] **Step 2:** Implement each widget from its `.tsx` and CSS, including the press motion (the web's pressed offset and timing) and the disabled state.
- [ ] **Step 3:** Behaviour tests:
  - press and disabled;
  - `MonthPicker` ‹ and › raise `onChange` with the previous and next month;
  - `SegmentedControl` selects.
- [ ] **Step 4:** Review Focus 1: `BudgetBar` and `Money` with "$1.500.000.000", and `CategoryChip` with a 40-character name, render as the web's stories do.
- [ ] **Step 5:** Run the harness and `flutter test`. Every pair passes, in night and day. Commit `feat(mobile): the web's small components`.

### Task 4: Components, batch 2 (rows, sheet, keypad, bars)

**Files:**
- Create in `apps/mobile/lib/ui/`: `sheet.dart`, `confirm_sheet.dart`, `keypad.dart`, `amount_field.dart`, `name_field.dart`, `swipe_row.dart`, `transaction_row.dart`, `category_row.dart`, `toast.dart`, `bottom_bar.dart`
- Modify: move Stage 3's `lib/home/swipe_row.dart`, `transaction_row.dart` and `swipe_rules.dart` into `lib/ui/`, keeping their behaviour tests.
- Test: parity goldens against `ui-sheet--*`, `ui-keypad--*`, `ui-namefield--*`, `ui-swiperow--*`, `ui-transactionrow--*`, `ui-categoryrow--*`, `ui-toast--*` and `ui-bottombar--*`, plus behaviour tests.

**Interfaces:**
- **Produces:**
  - `BottomBar({required String current, required VoidCallback onAdd, required VoidCallback onMic, required ValueChanged<String> onNavigate})`. Its items are Inicio, ＋ and Análisis as on the web, plus 🎤 next to the ＋ (spec decision 3), styled as a smaller sibling of the ＋.
  - `LkSheet.show(...)`, which replaces the Material bottom sheet for every sheet in the app.

- [ ] **Step 1:** Add the pairs and watch them fail. The 🎤 pair is checked against `ui-bottombar--*` with the 🎤 masked out; the founder reviews the 🎤 by picture.
- [ ] **Step 2:** Implement from the `.tsx` and CSS. Port the sheet's drag, the web's backdrop and the keypad's press feel. Stage 3's gesture rules (`swipe_rules.dart`) stay the source for swipe behaviour.
- [ ] **Step 3:** Run all of Stage 3's tests for swipe, the add sheet and toasts. They stay green, with only import and finder changes.
- [ ] **Step 4:** Run the harness and `flutter test`. Commit `feat(mobile): the web's rows, sheet, keypad and bottom bar`.

### Task 5: Home, matching the web, with months

**Files:**
- Modify: `apps/mobile/lib/home/home_screen.dart`, `home_widgets.dart` (rebuilt from `lib/ui/`), `home_controller.dart` and `home_repository.dart` (a `month` parameter), and `lukas_line.dart` (port `features/home/home-model.ts`'s Lukitas lines if they differ)
- Test: parity goldens against `demo-screens--home-in-pesos`, `home-home--transactions`, `home-home--empty-month` and `home-home--day-theme`, plus behaviour tests.

**Interfaces:**
- **Consumes:** `lib/ui/*` from Tasks 3 and 4.
- **Produces:**
  - `HomeController.showMonth(String yyyyMm)`.
  - The `/` route takes an optional `?month=`.
  - The widget and notices keep reading the current month only.

- [ ] **Step 1:** Write the failing parity pairs and these behaviour tests:
  - `‹ moves to the previous month and loads its summary and movements`;
  - `the current month shows no ›`, or whatever the web shows at the current month. Copy `HomeHeader.tsx`;
  - `the header shows the Lukitas wordmark and the face button`.
  - **Review Focus 3:**
    - `a month with no movements shows the web's empty state`;
    - `moving months offline shows the offline note and never another month's figures`, because the cache holds only the current month.
  - **Review Focus 2:** `at text scale 1.3 home has no overflow`.
- [ ] **Step 2:** Implement. The movement list, swipe, Deshacer, latest-request-wins, cache and snapshot logic from Stage 3 stay. Only the layout and the month parameter change. The 🎤 in the bottom bar opens capture, and ＋ opens the add sheet.
- [ ] **Step 3:** Run the harness and the full `flutter test`. Commit `feat(mobile): home matches the web and moves between months`.

### Task 6: Presupuestos, category detail and budget sheet

**Files:**
- Create: `apps/mobile/lib/budgets/` (repository, controller, `budgets_tab.dart`, `category_detail_screen.dart`, `budget_sheet.dart`)
- Modify: `home_screen.dart` (the Movimientos | Presupuestos tabs), `router.dart` (`/categories/:id?month=`)
- Test: parity goldens against `home-home--budgets` and the `manage-categories--*` detail and BudgetSheet stories, plus behaviour tests against fakes and an emulator integration test against the dev stack.

**Interfaces:**
- **Consumes:**
  - `GET /v1/summary?month=`, for per-category spent and budget. Check the DTO and use what the web uses.
  - `GET /v1/categories`.
  - `PUT /v1/categories/{id}/budget`. Check the method and body in apps/api/src/routes.
  - `GET /v1/transactions?category=&month=`.
- **Produces:** `BudgetsRepository.setBudget(String categoryId, int? cents)`, where null clears the budget, as the web allows.

- [ ] **Step 1:** Write failing tests:
  - `the Presupuestos tab lists each category with its bar, like the web`;
  - `tapping a category opens its detail with that month's movements`;
  - `setting a budget saves it and the bar and Te quedan update`;
  - `clearing a budget works`;
  - **Review Focus 5:** `a failed budget save shows the web's error toast and keeps the old budget`.
- [ ] **Step 2:** Implement by porting `features/categories/CategoryDetail.tsx`, `BudgetSheet.tsx` and the budgets part of `features/home/Home.tsx`. Category create, rename and archive stay on the web: show the web's own link or button style pointing to "Más en la web".
- [ ] **Step 3:** Run the harness, `flutter test` and the integration test. Commit `feat(mobile): budgets in the app, as on the web`.

### Task 7: Análisis

**Files:**
- Create: `apps/mobile/lib/insights/` (repository, controller, `insights_screen.dart`, `chart_geometry.dart` ported from `features/insights/chart-geometry.ts`, `category_donut.dart`, `trend_chart.dart`, `cost_of_living.dart`, and the `insights_model.dart` port of `insights-model.ts`)
- Modify: `router.dart` (`/insights?month=`), and the bottom bar's Análisis item.
- Test: `chart_geometry_test.dart` (port `insights-model.test.ts` and the geometry cases), parity goldens against `insights-insights--*`, and behaviour tests.

**Interfaces:**
- **Consumes:** `GET /v1/reports/by-category`, `/v1/reports/trend` and `/v1/reports/cost-of-living`, with the same query parameters the web sends.

- [ ] **Step 1:** Write failing tests:
  - port the web's model and geometry tests one for one, so the same inputs produce the same arcs, points and labels;
  - add the parity pairs.
- [ ] **Step 2:** Implement with `CustomPainter` from the ported geometry. Use no chart library.
- [ ] **Step 3:** Review Focus 5: `a failed report load shows the web's ScreenError with Reintentar`.
- [ ] **Step 4:** Run the harness and `flutter test`. Commit `feat(mobile): Análisis, as on the web`.

### Task 8: The add sheet, matching the web

**Files:**
- Modify: `apps/mobile/lib/add/add_sheet.dart`. Split it while rebuilding it from `lib/ui/` (sheet, keypad, amount field, name field, category chips).
- Test: parity goldens against the `home-home--*` sheet stories, including `home-home--sheet-day-theme`, `home-home--more-options` and `home-home--edit-sheet-day-theme`. Stage 3's add-sheet tests stay.

- [ ] **Step 1:** Add the pairs and watch them fail. Review Focus 2: `at text scale 1.3 every key and Guardar are visible at 360×640`.
- [ ] **Step 2:** Implement. Idempotency, edit mode, the `_nameTouched` rule and the suggestions logic stay as they are.
- [ ] **Step 3:** Run the harness and `flutter test`. Commit `feat(mobile): the add sheet matches the web`.

### Task 9: Entry, verify, passkey offer and "Guarda tu progreso"

**Files:**
- Modify: `apps/mobile/lib/entry/*` and `lib/progress/*`
- Test: parity goldens against `sign-in-signin--*`, `sign-in-verify--*`, `sign-in-codeinput--*` and `sign-in-passkeyoffer--*`. "Guarda tu progreso" is reviewed by picture, built from the same parts as the passkey offer and Settings.

- [ ] **Step 1:** Add the pairs and watch them fail. The guest button ("Probar sin correo") keeps Stage 3's place and copy, in the web's secondary button style.
- [ ] **Step 2:** Implement. The session, claim and passkey logic stay as they are.
- [ ] **Step 3:** Run the harness and `flutter test`. Commit `feat(mobile): entry screens match the web`.

### Task 10: Settings, celebration and toasts

**Files:**
- Modify: `apps/mobile/lib/settings/*` and `lib/feedback/*` (the celebration view)
- Test: parity goldens against `manage-settings--*`, `feedback-celebration--*` and `ui-toast--*`. The app-only rows (voice model, notices, widget, server, vibration) use the web's row style.

- [ ] **Step 1:** Add the pairs and watch them fail. Review Focus 2: `at text scale 1.3 settings has no overflow`.
- [ ] **Step 2:** Implement. The settings logic stays.
- [ ] **Step 3:** Run the harness and `flutter test`. Commit `feat(mobile): settings and celebrations match the web`.

### Task 11: Capture and the model download, in the web's language

**Files:**
- Modify: `apps/mobile/lib/capture/*` (split `capture_sheet.dart`: preview cards into `lib/capture/preview/`, built from `lib/ui/`)
- Test: Stage 3's capture tests stay green. Add new night and day goldens of listening, preview with two cards, an unread fragment and the download offer, for the founder to review by picture. There is no web story for these.

- [ ] **Step 1:** Add the goldens and watch them fail.
- [ ] **Step 2:** Implement with `LkSheet`, `PressButton`, `TransactionRow`-style cards and `LukasBubble` for "¿En qué gastaste?".
- [ ] **Step 3:** Run `flutter test`. Commit `feat(mobile): capture in the web's language`.

### Task 12: Full sweep and an APK for the founder

- [ ] **Step 1:** Regenerate every web shot and fixture, then run the whole harness. Expected: every pair is within spec §5. Put the composed images in `build/parity/` and an index page for review.
- [ ] **Step 2:** Run everything:
  - `flutter test`, the Kotlin tests and the three check scripts;
  - the emulator integration suite against the dev stack;
  - the API and web suites, since the web scripts changed.
- [ ] **Step 3:** Push to PR #5. Auto-fix is on and the founder approved pushes for this PR. Then:
  - build a dev APK with `release.sh` in the founder's terminal, because they type the password;
  - install it with adb;
  - the founder reviews the app next to the web on the phone.
- [ ] **Step 4:** Do the final whole-branch review on the most capable model, then the Stage 3 Task 18 phone checklist.
