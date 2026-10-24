# Stage 3c: everything the web does, the app does — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port every signed-in web feature the app lacks (categories, recurring payments, import, welcome, and Settings' time and money, passkeys, export and delete) into the Android app. Each one matches the web picture for picture.

**Architecture:** Each feature is ported from its web feature folder. The UI is built from `apps/mobile/lib/ui/` (3b). The model and its tests are ported one for one. A repository talks to the existing API routes. Pictures are proven with the 3b parity harness. Navigation follows the web's routes and the face menu.

**Tech Stack:** Flutter 3.47.7, riverpod, go_router, the generated dart-dio client, ARB es/en, and Android's Storage Access Framework and share sheet through a small platform channel. No new permissions.

**Spec:** `docs/superpowers/specs/2026-10-24-stage-3c-mobile-feature-parity-design.md`. It builds on the Stage 3 and 3b specs; read all three.

## Global Constraints

- **Parity:** the web is the reference. Each shared screen matches its web story at 412 × 915, night and day, with `compose --max 2` (under 2% of ink). The workflow is in `docs/mobile/parity.md`.
- **Port, don't invent:**
  - Each screen is ported from the web's `.tsx` and its CSS.
  - Each model and its tests (`*-model.ts`, `*.test.ts`) are ported one for one.
  - Every web rule carries over: validation, limits and copy.
- **Copy:** in ARB (es and en), reusing the web catalogue's wording.
- **No Google and no new permissions:** `check-no-google.sh` and `check-permissions.sh` pass unchanged. File access goes only through the Storage Access Framework and the share sheet.
- **Earlier behaviour stays:**
  - an idempotency key on every create;
  - month guards;
  - an offline cache of the current month only;
  - the widget snapshot and notices follow any change that affects them.
  - Stage 3 and 3b tests stay green, changing only in finders.
- **Commits:** explicit pathspec, no Co-Authored-By line, no push. Never touch the `lukitas-personal-*` containers or `deploy/personal/.env`. Destructive flows are tested only on throwaway dev-stack accounts.
- **Toolchain:** Flutter is at `~/development/flutter/bin` and must be on PATH. JDK 17 is set up per `docs/mobile/setup.md`.

## Review Focus

1. **Archiving a category that has a budget or a recurring payment:**
   - home's figures, the Categorías tab, the widget and the notices update;
   - the web's rule on what happens to its recurring payment applies.

   Tested in Task 2.
2. **Ending a recurring payment due today, after the 9:00 notice is scheduled:** no notice is posted for it. Tested in Task 3.
3. **An import of a large file (2000 rows) or a malformed file:** the web's errors and limits apply, there's no freeze, and a cancelled import changes nothing. Tested in Task 4.
4. **Changing the currency after the first movement:** refused with the web's message. Changing the time zone moves "today" everywhere: home, notices and the widget. Tested in Task 6.
5. **Deleting the account:**
   - The cache, widget snapshot, notice jobs, voice model and session are all cleared, and entry shows.
   - A failed delete keeps everything and says why.

   Tested in Task 7.

---

### Task 1: Navigation like the web

**Files:**
- Modify: `apps/mobile/lib/router.dart`, the face menu (`lib/home/…` HomeHeader port) and `lib/ui/app_shell.dart`.

**Interfaces:**
- **Produces routes** that mirror `apps/web/app/routes.ts`: `/categories`, `/categories/:id` (exists), `/recurring`, `/import`, `/settings` (exists) and `/welcome/:step?`. Each one starts as the web's loading or empty look until its task lands.

- [ ] **Step 1:** Failing tests. Every route is reachable the way the web reaches it: the face menu items, the home nudge cards and Settings' links. "Más en la web" remains only for the landing and roadmap.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run `flutter test` and `compose --max 2`. Commit `feat(mobile): every web page has its place in the app`.

### Task 2: Categories live in the Categorías tab (web first, then app)

The founder decided (2026-10-24) that categories are managed only from home's Categorías tab and the category detail, on the web and in the app. The separate categories page goes away.

**Files:**
- **Web:**
  - Move management into `features/home/Home.tsx`'s Categorías tab and `features/categories/CategoryDetail.tsx`. Reuse `CategoryForm.tsx` and `use-category-sheets.tsx`.
  - Remove `CategoriesPage.tsx` and the `/app/categories` route, along with its links. `/app/categories/:id` stays.
  - Update the stories and e2e tests.
- **App:** `apps/mobile/lib/budgets/` (the tab and detail), plus a `lib/categories/` form ported from `CategoryForm.tsx`.

**Interfaces:**
- **Consumes:** `GET/POST /v1/categories` and `PATCH /v1/categories/{id}`. Check the routes for archive and unarchive.

**What the tab and detail hold:**
- **Tab:** each category with its month's spend and budget bar, a Gastos | Ingresos switch (as in Análisis), a "Nueva categoría" button, and a folded "Archivadas" section at the end with unarchive.
- **Detail:** the month's movements and the budget, plus rename, icon and colour, and archive.

- [ ] **Step 1:** Web first. Write failing stories and e2e tests for the tab and detail, then implement them and remove the page. Run the web suites.
- [ ] **Step 2:** App. Write failing tests:
  - parity pairs against the new web stories;
  - create, rename, icon and colour, archive and unarchive from the tab and detail;
  - Review Focus 1.
- [ ] **Step 3:** Implement. Run the harness, `flutter test`, and an emulator test that creates a category. Commit `feat: categories are managed from the Categorías tab, on the web and in the app`.

### Task 3: Recurring payments

**Files:**
- Create: `apps/mobile/lib/recurring/`, porting `features/recurring/RecurringPage.tsx`, `RecurringForm.tsx`, `recurring-model.ts` and its test.

- [ ] **Step 1:** Failing tests:
  - the ported `recurring-model` tests;
  - parity pairs for `manage-recurring--*`;
  - create, edit and end;
  - Review Focus 2: the due notice and widget follow.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the harness, `flutter test`, and an emulator test that creates and ends a recurring payment. Commit `feat(mobile): recurring payments, as on the web`.

### Task 4: Import

**Files:**
- Create: `apps/mobile/lib/import/`, porting `features/onboarding/ImportPage.tsx`, `ImportStep.tsx`, `use-import-flow.ts` and `import-state.ts`.
- Create: `android/.../files/FilesChannel.kt`, which uses Storage Access Framework open and create, plus the share sheet. Task 7's export reuses it.

**Interfaces:**
- **Produces:** `pickFile({mimeTypes}) → bytes and name`, `saveFile(name, bytes, mime)` and `shareFile(name, bytes, mime)`.
- **Consumes:** `/v1/imports`, `/v1/imports/{id}` and `/v1/imports/{id}/confirm`.

- [ ] **Step 1:** Failing tests:
  - the ported import-state tests;
  - parity pairs for the import stories;
  - Review Focus 3.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the harness, `flutter test`, and an emulator import of a fixture CSV through the channel. Commit `feat(mobile): import a bank file, as on the web`.

### Task 5: Welcome

**Files:**
- Create: `apps/mobile/lib/welcome/`, porting `features/onboarding/Welcome.tsx`, `WelcomeStep`, `CurrencyStep`, `CategoriesStep`, `BudgetsStep`, `ImportStep` (reuse Task 4), `steps.ts`, `onboarding-draft.ts` and `onboarding.test.ts`.

- [ ] **Step 1:** Failing tests:
  - the ported onboarding tests;
  - parity pairs for `onboarding-welcome--*`;
  - a new email account sees the steps;
  - an account with `onboardingCompletedAt` never does;
  - guests keep their guest start, as on the web.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the harness, `flutter test`, and an emulator test that completes the welcome as a new email user. Commit `feat(mobile): the welcome, as on the web`.

### Task 6: Settings: time zone, currency and passkeys

**Files:**
- Modify: `apps/mobile/lib/settings/`, porting `TimeAndMoneySection.tsx`, `PasskeysSection.tsx` and `passkeys.ts`.

- [ ] **Step 1:** Failing tests:
  - parity pairs for the matching `manage-settings--*` stories;
  - list, add and delete passkeys;
  - Review Focus 4.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the harness and `flutter test`. Commit `feat(mobile): time, money and passkeys in settings, as on the web`.

### Task 7: Settings: export and delete account

**Files:**
- Modify: `apps/mobile/lib/settings/`, porting `use-export.ts` and `DeleteAccount.tsx`, and reusing Task 4's FilesChannel.

- [ ] **Step 1:** Failing tests:
  - parity pairs for the export and delete stories;
  - export JSON and CSV through share and save;
  - delete only unlocks once the email is typed;
  - Review Focus 5;
  - guests see what the web shows a guest.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the harness, `flutter test`, and emulator tests for export and for deleting a throwaway dev-stack account. Commit `feat(mobile): export and delete the account, as on the web`.

### Task 7b: Feedback and ideas (web and app)

The founder asked (2026-10-24) for a place in the app to send feedback or ask for a feature. For now this is an email to the founder.

**Files:**
- **Web:** a "Comentarios e ideas" section in Settings (`features/settings/`) with a button that opens a `mailto:` link, plus a story.
- **App:** the same section in `lib/settings/`. The button opens the email app through the device channel's `openUrl`; allow `mailto:` there, still refusing other schemes.

**Details:**
- **Address:** `FEEDBACK_EMAIL`, the address the founder gives. It is a constant in one place per app.
- **Subject:** "Lukitas: comentarios" or "Lukitas: feedback" by language.
- **Body:** only the app version and the language, and nothing the person didn't type: no email, no amounts, no token.
- **No email app on the phone:** a message shows the address and lets the person copy it.

- [ ] **Step 1:** Failing tests:
  - parity pair;
  - the button builds the exact `mailto:` with an encoded subject and body;
  - `openUrl` accepts `mailto` and still refuses `javascript:` and `intent:`;
  - the no-email-app fallback.
- [ ] **Step 2:** Implement on the web, then in the app.
- [ ] **Step 3:** Run the suites. Commit `feat: a place to send comments and ideas, on the web and in the app`.

### Task 8: Sweep, APK and final review

- [ ] **Step 1:** Regenerate every shot and fixture and run the whole harness. Every pair must be within the 2% limit.
- [ ] **Step 2:** Run every suite: flutter, Kotlin, the checks, emulator, api, web unit and web e2e.
- [ ] **Step 3:** Push to PR #5. The founder signs the APK, and the controller installs it for user 0.
- [ ] **Step 4:** Final whole-branch review on the most capable model, then one fix dispatch.
