# Stage 3: Android app, widget and quick capture: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A free-software Android app for the founder and invited friends:
- a home-screen widget with ＋ and 🎤;
- sentences turned into movements on the device;
- "Te quedan" at a glance;
- guest accounts that keep their data when they add an email.

**Architecture:**
- **Server:** small additions to the Hono and Better Auth API (guests, the in-place email claim, batch save, cleanup, asset links).
- **Shared parser cases:** a JSON file in `packages/core`.
- **The app:** a Flutter app in `apps/mobile` that talks only to the API through a client generated from OpenAPI.
- **Native parts:** small Kotlin pieces for the Jetpack Glance widget, the Quick Settings tile, haptics and passkeys.
- **Speech engine and parsing strategy:** decided by a measured spike before anything is built on them.

**Tech Stack:**
- **Server:** API on Hono 4, Better Auth 1.7 (`anonymous` and existing plugins), Drizzle with Postgres RLS, Vitest.
- **App:** Flutter (stable, pinned in `apps/mobile/.flutter-version`) with Dart 3.
  - **Libraries:** `riverpod` 2, `go_router`, `dio` with an `openapi-generator` dart-dio client, `flutter_secure_storage`, `home_widget`, `workmanager`, `audioplayers`, `intl` with ARB catalogs.
  - **Speech:** Vosk or whisper.cpp bindings, per the spike.
  - **Optional local model:** llama.cpp bindings, per the spike.
- **Native Android:** Kotlin with Jetpack Glance 1.1, AndroidX `credentials` (no Play Services artifact) and AndroidX WorkManager.
- **CI:** GitHub Actions with `reactivecircus/android-emulator-runner`.

**Spec:** `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md`. It builds on `docs/superpowers/specs/2026-10-20-lukas-design.md` and the Stage 2 web spec.

## Global Constraints

- **No Google.** No Google Play Services, Firebase or other proprietary dependency in any build. CI fails on `com.google.android.gms`, `com.google.firebase`, `play-services` and `com.google.mlkit` in the resolved dependencies.
- **Free licences only.** Every dependency and every model is free-licensed (Apache-2.0, MIT, BSD, LGPL, GPL or AGPL), and the licence is listed in About. Gemini Nano and Gemma are excluded.
- **Package and minimum version.** Android package `com.andersonlaverde.lukitas`, `minSdk 26`, built for arm64-v8a and armeabi-v7a.
- **Default server.** `https://app-lukas.andersonlaverde.com`, changeable in Settings. API calls go to `<server>/api`.
- **Money.** Amounts are integer cents (×100 for every currency, COP included), never floats. Formatting matches the web's: COP es → "$50.000", COP lukas hint "(50 lukas)", EUR es → "562,92 €".
- **Idempotency.** Every create sends an `Idempotency-Key` that stays stable across retries of the same input.
- **Copy and code.** UI copy ships in `es` (default) and `en` from ARB catalogs with a parity test. Code, comments and commits are in English.
- **Tokens.** Colours, radii, spacing and durations come from tokens generated from `docs/design/system/project/tokens.json`. Night is the default theme.
- **No tracking.** No analytics, trackers or automatic crash reporting.
- **Notices.** Only the two local notices in spec §7.2. No server push.
- **Signing.** The release signing key never enters the repo or CI.
- **Commits.** Never add Claude as co-author. Commit by explicit path (`git commit -m … -- <paths>`).
- **Protected data.** Never run `docker compose down -v`. Never touch the `lukitas-personal-*` containers or volume, and never read `deploy/personal/.env`.

## Review Focus

1. **Batch save retried after a timeout** (the first request committed, its response was lost): exactly N movements exist, not 2N. Tested in Task 5 (API) and Task 12 (app).
2. **"Lukas" and "palos" in a non-COP account**: "15 lukas" in a EUR account is not ×1.000. It's read as a plain 15, or left unread, never 15.000 €. Tested in Task 8's cases.
3. **"ayer" right after midnight in the user's time zone**: the date follows the profile time zone, not the phone's UTC offset. Tested in Task 8's cases (a fixed `today` plus time zone).
4. **Signing out with a widget on screen**: the widget switches to "Abre Lukitas para empezar" and never keeps showing the previous person's figure. Tested in Task 15.
5. **Microphone permission denied, or no speech engine available**: the capture screen falls back to typing with one clear sentence, never a dead button. Tested in Task 12.

---

## File Structure

```
apps/api/src/
  auth.ts                       + anonymous plugin, GUEST_SIGNUP, guest defaults
  config.ts                     + GUEST_SIGNUP, ANDROID_CERT_SHA256 (list)
  routes/me.ts                  + isAnonymous; claim-email send/verify
  routes/transactions.ts        + POST /v1/transactions/batch, /batch-delete
  services/guest-cleanup.ts     daily job (advisory lock)
apps/api/test/                  guests.test.ts, claim-email.test.ts, batch.test.ts, guest-cleanup.test.ts
packages/core/quick-capture/
  cases.json                    shared parser cases
  cases.schema.json             their shape
deploy/personal/                Caddyfile (+ /.well-known/assetlinks.json), .env.example, README
apps/mobile/                    Flutter app
  .flutter-version
  pubspec.yaml
  lib/
    main.dart, app.dart, router.dart
    api/                        generated client (lib/api/gen) + session.dart
    theme/                      tokens.g.dart (generated) + theme.dart
    l10n/                       app_es.arb, app_en.arb
    money/                      format.dart (formatMoney, lukasHint)
    capture/                    parser/ (rules), engine/ (speech per spike), model/ (optional), preview/
    home/, add/, entry/, progress/, settings/, feedback/, notices/
  android/app/src/main/kotlin/com/andersonlaverde/lukitas/
    widget/                     Glance widgets, refresh worker
    tile/                       Quick Settings tile
    haptics/                    platform channel
    passkeys/                   Credential Manager channel
  fastlane/metadata/android/{es-ES,en-US}/
  scripts/                      gen-tokens.dart, gen-api.sh, check-no-google.sh, release.sh
  test/, integration_test/
.github/workflows/ci.yml        + mobile job (path-filtered)
docs/superpowers/reports/       2026-…-stage-3-voice-spike.md
```

---

### Task 0: Toolchain on the founder's Mac

**Files:**
- Create `apps/mobile/.flutter-version` (the pinned stable version, e.g. `3.x.y`).
- Create `docs/mobile/setup.md`.

- [ ] **Step 1:** Install the pinned Flutter SDK and the Android command-line tools (sdkmanager: `platform-tools`, `platforms;android-36`, `build-tools`, `ndk`, `emulator`, one arm64 system image) under the user's home. Don't install Android Studio. Record the exact versions in `docs/mobile/setup.md`.
- [ ] **Step 2:** Run `flutter doctor -v`. Expected: Flutter and the Android toolchain are ✓; Android Studio, Chrome and Xcode may be missing.
- [ ] **Step 3:** With the founder's phone connected (USB debugging on), run `adb devices`. Expected: one device listed.
- [ ] **Step 4:** Commit `docs: mobile toolchain setup`.

### Task 1: Voice and model spike (spec §3)

**Files:**
- Throwaway app outside the repo: `~/lukitas-spike/`.
- Create `docs/superpowers/reports/<date>-stage-3-voice-spike.md`.

**Inputs:**
- **The founder records each sentence once** on their phone, in a quiet room unless marked (noise):
  1. "gasté quince mil en el almuerzo"
  2. "gasté 15 mil en almuerzo y 3 lukas en uber"
  3. "pagué el arriendo, un millón ochocientos mil"
  4. "ayer compré pan y leche por ocho mil quinientos"
  5. "me pagaron cuatro coma tres palos"
  6. "rappi veintidós mil novecientos"
  7. "medio palo en el éxito"
  8. "antier gasté doce mil en taxi y cuarenta mil en mercado"
  9. "nueve euros con cincuenta en café"
  10. "spent twelve dollars on lunch and three on coffee"
  11. "got paid two thousand"
  12. "una luca de chicle"
  13. "gimnasio ciento veinte mil el lunes"
  14. "gasté 45.500 en farmacia"
  15. "doscientos mil de gasolina y ochenta mil de peajes"
  16. (noise) "almuerzo dieciocho mil"
  17. (noise) "uber siete mil quinientos y café cinco mil"
  18. "pagué el internet noventa y nueve mil novecientos"
  19. "me llegó la prima, dos millones"
  20. "spotify dieciséis mil novecientos"
- **Expected drafts** for each sentence are written into the report before measuring (amount in cents for COP or EUR or USD, kind, date offset, name).

**Steps:**
- [ ] **Step 1:** Build the throwaway Flutter app with:
  - Vosk es and en small models;
  - whisper.cpp with the smallest multilingual model that works;
  - the rules-parser prototype (Task 8's rules, minimal);
  - llama.cpp with grammar-constrained JSON for one ~0.5B model and one ~1.5B model.

  Confirm each model licence is Apache-2.0 or MIT before downloading it, and write the licence into the report.
- [ ] **Step 2:** Run every speech × parser combination on the 20 recordings, on the founder's phone and in airplane mode. Measure:
  - amounts, kinds, dates and names right per movement;
  - the speech engine's word errors;
  - milliseconds from end of speech to drafts;
  - download size and peak memory.
- [ ] **Step 3:** Apply the spec §3 decision rules:
  - **Speech:** an engine qualifies only if the amounts are right in at least 18 of 20 sentences **and** the median latency is ≤ 1000 ms. Pick Vosk if it qualifies, else Whisper if it qualifies, else the system recognizer.
  - **Parsing:** rules only, or a hybrid, or the larger model only if the smaller one fails and the founder accepts its size and latency.

  Write the decision as **Engine:** and **Parsing:** lines. Delete the throwaway app.
- [ ] **Step 4:** Commit the report: `docs: Stage 3 voice and model spike results`.
- [ ] **Step 5 (controller):** Ledger the decision as a Ruling. Tasks 8 and 12 read it.

### Task 2: Guest sign-up on the API (spec §4.1)

**Files:**
- Modify `apps/api/src/auth.ts`, `apps/api/src/config.ts` and `apps/api/src/routes/me.ts`, plus a Drizzle migration if the plugin adds `user.isAnonymous`.
- Test: `apps/api/test/guests.test.ts`.

**Interfaces:**
- Produces `POST /api/auth/sign-in/anonymous` (Better Auth). It returns the session and a bearer token in `set-auth-token`.
- Produces `GET /v1/me` gaining `isAnonymous: boolean`.
- Produces config `GUEST_SIGNUP` (boolean env, default `true`).

- [ ] **Step 1: Write the failing tests.**
  - `a guest signs up without an email, even with an allowlist set`: 200, `GET /v1/me` → `isAnonymous: true`, the account exists, its transactions are empty.
  - `guest sign-up is refused when GUEST_SIGNUP is false`: 403 problem `guest_signup_disabled`.
  - `a guest's account currency follows the device`:
    - `x-lukas-timezone: America/Bogota` → `COP`;
    - `Europe/Lisbon` → `EUR`;
    - `America/New_York` → `USD`.

    `x-lukas-locale` sets the locale.
  - `RLS: a guest never sees another guest's rows`.
- [ ] **Step 2:** Run `npx vitest run --project api test/guests.test.ts`. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Add `anonymous({ emailDomainName: "guest.lukitas.invalid" })`.
  - A before-hook refuses `/sign-in/anonymous` when `GUEST_SIGNUP` is off.
  - The allowlist hook ignores that path.
  - A user-create database hook sets the timezone, locale and default-account currency from the headers, reusing the web's region and currency rule. Move it into `@lukas/core` as `defaultCurrencyFor(timezone: string, region?: string): "COP"|"EUR"|"USD"` if it isn't there yet.
  - `isAnonymous` in the profile DTO.
- [ ] **Step 4:** Run it again. Expected: PASS. Then run the whole API suite (`npx vitest run --project api`).
- [ ] **Step 5:** Commit `feat(api): guest accounts without an email`.

### Task 3: The in-place email claim (spec §4.2)

**Files:**
- Modify `apps/api/src/routes/me.ts` and `apps/api/src/auth.ts` (reuse the OTP store and mailer).
- Test: `apps/api/test/claim-email.test.ts`.

**Interfaces:**
- Produces `POST /v1/me/claim-email/send {email}` → 204, or a problem: `sign_in_not_allowed` (403), `email_taken` (409), `not_a_guest` (409) or `too_many_requests` (429).
- Produces `POST /v1/me/claim-email/verify {email, code}` → 200 profile with `isAnonymous: false`, or `invalid_or_expired_code` (400).

- [ ] **Step 1: Write the failing tests.**
  - `claiming an allowlisted email keeps the same user id and every transaction`: create a guest with 3 transactions → send → read the code from the test mailer → verify. The same `id`, 3 transactions, `isAnonymous: false`, and an email sign-in afterwards reaches the same user.
  - `a non-allowlisted email gets sign_in_not_allowed and no mail is sent`.
  - `an email that belongs to another user gets email_taken, no mail, the guest unchanged`.
  - `two guests claiming the same email: exactly one wins, the other gets email_taken`. Run both verifies concurrently.
  - `a non-guest session gets not_a_guest`.
  - `a wrong code 3 times invalidates it`: the same limits as sign-in.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Hashed, single-use codes with the same TTL and attempt limits as sign-in, stored like the emailOTP codes.
  - The same per-email throttle.
  - The email uses the sign-in template with copy "Tu código para guardar tu progreso" (es) / "Your code to save your progress" (en).
  - Verify runs one transaction: `UPDATE user SET email, emailVerified=true, isAnonymous=false WHERE id = me AND isAnonymous`. A unique-violation maps to `email_taken`.
- [ ] **Step 4:** Run the tests. Expected: PASS. Then run the full API suite.
- [ ] **Step 5:** Commit `feat(api): guests save their progress by claiming an email in place`.

### Task 4: Guest cleanup and Android asset links (spec §4.4, §4.5)

**Files:**
- Create `apps/api/src/services/guest-cleanup.ts` and wire it in the server start.
- Modify `deploy/personal/Caddyfile`, `deploy/personal/docker-compose.yml`, `deploy/personal/.env.example` and `deploy/personal/README.md`.
- Tests: `apps/api/test/guest-cleanup.test.ts`, plus a smoke check in `deploy/personal/smoke.sh`.

**Interfaces:**
- Produces `cleanupInactiveGuests(db: Db, now: Date): Promise<number>`, which deletes anonymous users whose latest `session.updatedAt` is older than 60 days.
- Produces `scheduleGuestCleanup(deps)`, which runs once a day under a Postgres advisory lock (`pg_try_advisory_lock(0x6c756b61)`).
- Produces `/.well-known/assetlinks.json` built from env `ANDROID_CERT_SHA256` (comma-separated) for package `com.andersonlaverde.lukitas`, with relations `delegate_permission/common.handle_all_urls` and `delegate_permission/common.get_login_creds`.

**Steps:**
- [ ] **Step 1: Write the failing cleanup tests.**
  - `deletes a guest inactive for 61 days with its data`.
  - `keeps a guest active 59 days ago`.
  - `never deletes a user with an email, however old`.
  - `two runs at once delete once` (advisory lock).
- [ ] **Step 2:** Implement. Run the tests: PASS.
- [ ] **Step 3:** Caddy serves `assetlinks.json` from a template filled at container start. A missing env serves `[]`, never a 404.
- [ ] **Step 4:** `smoke.sh` checks `GET /.well-known/assetlinks.json` → 200 and `application/json`.
- [ ] **Step 5:** README and `.env.example` get one paragraph each on `ANDROID_CERT_SHA256` (the fingerprint printed by `release.sh`, Task 17) and on `GUEST_SIGNUP` (default on; set `false` to stop guest sign-up).
- [ ] **Step 6:** Commit `feat: clean up inactive guests and publish Android asset links`.

### Task 5: Batch save and batch undo (spec §5.5)

**Files:**
- Modify `apps/api/src/routes/transactions.ts` and `packages/core/src/schemas.ts`.
- Test: `apps/api/test/batch.test.ts`.

**Interfaces:**
- Produces `createTransactionsBatchSchema = z.object({ items: z.array(createTransactionSchema).min(1).max(20) })`.
- Produces `POST /v1/transactions/batch`, with an `Idempotency-Key` that is required. It returns `201 { items: TransactionDto[] }`.
- Produces `POST /v1/transactions/batch-delete { ids: uuid[] (1–20) }` → 204, a soft delete.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `saves 2 items in one call; the month summary counts both`.
  - `all or nothing: an unknown category in item 2 saves neither` (422).
  - `replaying the same Idempotency-Key returns the same items and creates nothing`: this is Review Focus 1.
  - `21 items are refused` (422).
  - `batch-delete soft-deletes exactly those ids; another user's ids are untouched`.
  - `batch takes the default-account lock like a single create`: a concurrency test in the style of the existing ones.
- [ ] **Step 2:** Implement with one `withUser` transaction: `defaultAccount({lock: true})`, then the same validation and insert path as single create.
- [ ] **Step 3:** Run the tests: PASS. Run the full API suite.
- [ ] **Step 4:** Regenerate the web types (`pnpm --filter @lukas/web api:types --file`) so CI's staleness check passes.
- [ ] **Step 5:** Commit `feat(api): save and undo several movements at once`.

### Task 6: Shared quick-capture cases (spec §5.3)

**Files:**
- Create `packages/core/quick-capture/cases.json`, `packages/core/quick-capture/cases.schema.json` and `packages/core/quick-capture/README.md`.
- Test: `packages/core/src/quick-capture-cases.test.ts`, which validates the file against the schema.

**Interfaces:**
- Produces each case as `{ id, input, locale: "es"|"en", currency: "COP"|"EUR"|"USD", today: "YYYY-MM-DD", timeZone, categories: [{id,name,kind}], usual: [{name, categoryId}], expected: { drafts: [{amount, kind, name, categoryId|null, date}], unread: string[] } }`.

**Steps:**
- [ ] **Step 1:** Write at least 60 cases, most of them Colombian. They must include:
  - the 20 spike sentences;
  - every amount form in spec §5.2 (digits, words, k, mil, lukas, palos, medio palo, EUR decimals, the "con" form);
  - a split only where a new amount starts ("pan y leche 8 mil" is one draft);
  - income verbs, and the default expense;
  - hoy, ayer, antier, a weekday, and the default;
  - category by usual name, by category name ignoring accents, and none;
  - unread fragments;
  - Review Focus 2: "15 lukas" in EUR is never 15.000;
  - Review Focus 3: "ayer" with `today` 2026-10-01 and timeZone `America/Bogota` → `2026-09-30`.
- [ ] **Step 2:** The schema test passes (`npx vitest run --project unit packages/core`).
- [ ] **Step 3:** Commit `feat(core): shared quick-capture parser cases`.

### Task 7: Flutter scaffold, generated code and CI (spec §6.3, §8)

**Files:**
- Create the Flutter project `apps/mobile`: package `com.andersonlaverde.lukitas`, `minSdk 26`, ABI filters arm64-v8a and armeabi-v7a.
- Create `lib/api/gen` (generated), `lib/theme/tokens.g.dart` (generated) and the `l10n` ARB files.
- Create `scripts/gen-tokens.dart`, `scripts/gen-api.sh` and `scripts/check-no-google.sh`.
- Modify `.github/workflows/ci.yml`: a `mobile` job that runs when `apps/mobile/**`, `apps/api/src/**` or `packages/core/**` change, and is otherwise skipped (which counts as passing).

**Interfaces:**
- Produces `ApiClient forServer(Uri server, {String? token})`.
- Produces `LukitasTokens` as Dart constants from `tokens.json`: colours for night and day, radii, spacing and durations.
- Produces `AppLocalizations` for es and en.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `tokens.g.dart is up to date`: CI regenerates and diffs it.
  - `ARB parity: es and en have the same keys and placeholders`.
  - `no Google dependency`: `scripts/check-no-google.sh` greps `./gradlew :app:dependencies` and `flutter pub deps` for the banned groups and exits 1 with their names.
  - `a smoke widget test renders the app shell in night theme`.
- [ ] **Step 2:** Implement the generators.
  - `gen-api.sh` runs `openapi-generator-cli generate -g dart-dio` on the API's OpenAPI document, built with `--file` like the web's.
  - The `mobile` CI job runs, in order:
    1. `flutter analyze`;
    2. `flutter test`;
    3. the token and API staleness diffs;
    4. `check-no-google.sh`;
    5. `flutter build apk --debug`.
- [ ] **Step 3:** Run all four tests locally: PASS.
- [ ] **Step 4:** Commit `feat(mobile): Flutter app scaffold with generated tokens and API client`.

### Task 8: The Dart sentence parser (spec §5.1–5.4)

**Files:**
- Create `apps/mobile/lib/capture/parser/` (`parse.dart`, `amounts.dart`, `dates.dart`, `split.dart`, `match.dart`), plus `lib/capture/model/` only if the spike chose a hybrid.
- Test: `apps/mobile/test/capture/parser_cases_test.dart`, which runs every case in `packages/core/quick-capture/cases.json`.

**Interfaces:**
- Produces `ParseResult parseSentence(String text, ParseContext ctx)`.
  - `ParseContext { String locale; String currency; String today; String timeZone; List<Category> categories; List<Usual> usual; }`
  - `ParseResult { List<Draft> drafts; List<String> unread; }`
  - `Draft { int amount; Kind kind; String name; String? categoryId; String date; }`
- Produces, if hybrid: `abstract class FallbackModel { Future<List<Draft>> read(String fragment, ParseContext ctx); }`, used only on `unread`, behind the setting `useLocalModel`.

**Steps:**
- [ ] **Step 1:** Run the case test with an empty parser. Expected: FAIL on every case.
- [ ] **Step 2:** Implement the rules from spec §5.2. Number words cover es and en from 0 to 999.999.999, including "un millón ochocientos mil", "noventa y nueve mil novecientos" and "ciento veinte mil". "Lukas" and "palos" apply only when the currency is `COP`.
- [ ] **Step 3:** Run the case test: all cases PASS. Add unit tests for any helper with logic of its own.
- [ ] **Step 4 (hybrid only):**
  - Run the llama.cpp adapter with a GBNF grammar for the `Draft[]` JSON.
  - Validate its output: amount > 0, and `categoryId` is a known id or null.
  - Tests: invalid model output becomes `unread`; it is never saved and never throws.
- [ ] **Step 5:** Commit `feat(mobile): read movements from a sentence on the device`.

### Task 9: Entry and session (spec §6.1.1, §4.3)

**Files:**
- Create `apps/mobile/lib/entry/` (first run, email code, magic-link handling) and `lib/api/session.dart`.
- Create `android/.../passkeys/PasskeyChannel.kt`.
- Modify the manifest: App Links for `app-lukas.andersonlaverde.com/auth/verify`.

**Interfaces:**
- Produces `SessionStore`: `read()`, `write(token)` and `clear()` in `flutter_secure_storage`, which is backed by the Android Keystore.
- Produces the sign-in flows `startGuest()`, `sendCode(email)`, `verifyCode(email, code)`, `signInWithPasskey()` and `registerPasskey()`.
- Produces `passkeysSupported()`: true only on Android 14+ with a provider available through `androidx.credentials` (no `credentials-play-services-auth`).

**Steps:**
- [ ] **Step 1: Write the failing widget and integration tests.**
  - `first run shows three choices; "Entrar con huella" is hidden when passkeysSupported is false`.
  - `Probar sin correo creates a guest and lands on home`. This is an integration test against the dev stack.
  - `the email code signs in`, reading the code from Mailpit, like the web e2e.
  - `opening the magic link in the app signs in`: the integration test opens the App Link intent.
  - `a not-allowlisted email shows "Lukitas todavía no está abierto al público…"`.
- [ ] **Step 2:** Implement. Requests send `x-lukas-timezone` and `x-lukas-locale` from the device.
- [ ] **Step 3:** Run the tests: PASS. `check-no-google.sh` passes.
- [ ] **Step 4:** Commit `feat(mobile): sign in as a guest, with an email code, a magic link or a passkey`.

### Task 10: Home (spec §6.1.2)

**Files:**
- Create `apps/mobile/lib/home/` and `lib/money/format.dart`.

**Interfaces:**
- Produces `formatMoney(int cents, String currency, String locale)` and `lukasHint(int cents, String locale)`, which mirror the web's outputs.
- Produces the home state: the summary and a paged list with `nextCursor`.
- Produces `writeWidgetSnapshot(Summary)`, which Task 15 consumes.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `formatMoney matches the web`: "$50.000" (COP es), "562,92 €" (EUR es), "COP 50,000" (COP en); `lukasHint(5000000, "es")` → "(50 lukas)" and `lukasHint(430000000, "es")` → "(4,3 palos)".
  - `home shows Te quedan with budgets and Gastado este mes without` (widget tests with fakes).
  - `swipe left deletes and Deshacer within 8 s restores the same row`.
  - `swipe right on a pending row marks it paid`.
  - `a list longer than one page shows Ver más movimientos and loads the rest`.
  - `the event line names the movement and returns to the month's line after 10 s` (fake clock).
- [ ] **Step 2:** Implement. Gestures follow the web's Task 12c rules (axis lock, thresholds, one row open at a time). Motion durations come from the tokens.
- [ ] **Step 3:** Run the tests: PASS. Add golden images for home in night and day.
- [ ] **Step 4:** Commit `feat(mobile): home with Te quedan and the movements list`.

### Task 11: Add sheet (spec §6.1.3)

**Files:**
- Create `apps/mobile/lib/add/`.

**Interfaces:**
- Produces `openAddSheet(context, {Kind kind = expense})`, which Task 15's deep link reuses.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `typing 6,08 in es and 6.08 in en both store 608`; in COP the keypad has no decimal key.
  - `suggestions show at most two rows, the most used first`.
  - `a failed save keeps the input and Reintentar resends with the same Idempotency-Key`: after a fake timeout, one row exists.
  - `dragging down from the keypad area closes the sheet and enters no digit`.
  - `at 360×640 every key and Guardar are visible`.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the tests: PASS.
- [ ] **Step 4:** Commit `feat(mobile): the add sheet`.

### Task 12: Capture: listen, preview, save the batch (spec §6.1.4)

**Files:**
- Create `apps/mobile/lib/capture/engine/` (the engine Task 1 chose, behind `SpeechEngine`), `lib/capture/preview/` and `lib/capture/models_download.dart` (only if a model must be downloaded).

**Interfaces:**
- Produces `abstract class SpeechEngine { Future<bool> available(); Stream<String> listen({required String locale}); Future<void> stop(); }`.
- Produces `openCapture(context, {bool listen = true})`, which Task 15's deep link reuses.
- Produces `saveBatch(List<Draft>) → ids`, `undoBatch(ids)`.
- Produces model downloads from this repo's GitHub release assets, with a SHA-256 checked against a constant before use.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `a fixed transcript "gasté 15 mil en almuerzo y 3 lukas en uber" shows two cards and GUARDAR 2`.
  - `GUARDAR is disabled until every card has a category`; a card without one shows "Elige categoría".
  - `an unread fragment shows "No entendí: «…»" and can be completed by hand`.
  - `saving shows one celebration with the total and one Deshacer that removes both`.
  - `the batch save retried after a lost response leaves exactly 2 rows`: this is Review Focus 1, against the dev stack.
  - `microphone permission denied shows the typing field with one sentence on why`: this is Review Focus 5.
  - `no engine available behaves the same`.
- [ ] **Step 2:** Implement the engine the spike chose. A model download is opt-in, shows its size and is resumable. The engine copy names where the audio goes if it's the system recognizer.
- [ ] **Step 3:** Run the tests: PASS. `check-no-google.sh` passes.
- [ ] **Step 4:** Commit `feat(mobile): say or type a sentence and save its movements at once`.

### Task 13: Feel: Lukitas, haptics, sounds (spec §6.2)

**Files:**
- Create `apps/mobile/lib/feedback/` and `android/.../haptics/HapticsChannel.kt`.
- Assets: copy the sprite sheets from `apps/web/public/lukas/` and the sounds from the web.

**Interfaces:**
- Produces `feedback(FeedbackEvent event)` with events `saved`, `paid`, `deleted`, `undo`, `thresholdCrossed` and `pageChanged`. It drives the animation, the sound (muted by the setting) and the haptic.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `each event maps to its haptic pattern and sound`, with a fake channel.
  - `mute stops sounds, not haptics`.
  - `under "remove animations" Lukitas shows a still frame`.
- [ ] **Step 2:** Implement. Haptics use `VibrationEffect.Composition` on API 30+, with a waveform fallback below.
- [ ] **Step 3:** Run the tests: PASS.
- [ ] **Step 4:** Commit `feat(mobile): Lukitas, sounds and haptics`.

### Task 14: Save your progress, and settings (spec §6.1.5–6)

**Files:**
- Create `apps/mobile/lib/progress/` and `lib/settings/`.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `a guest sees Guarda tu progreso; claiming an allowlisted email keeps every movement` (integration test against the dev stack).
  - `email_taken says to sign in with that email and the guest stays`.
  - `changing the server URL signs out and points every call there`; an invalid URL is refused.
  - `About lists every dependency's licence and the model's`.
  - `sign out clears the session and the widget snapshot`: this is Review Focus 4, together with Task 15.
- [ ] **Step 2:** Implement. The honest copy for guests:
  - es: "Sin correo, si pierdes el teléfono o borras la app, pierdes tus datos."
  - en: "Without an email, losing the phone or deleting the app loses your data."
- [ ] **Step 3:** Run the tests: PASS.
- [ ] **Step 4:** Commit `feat(mobile): save your progress and settings`.

### Task 15: Widget and Quick Settings tile (spec §7.1)

**Files:**
- Create `android/.../widget/` (`LukitasSmallWidget.kt`, `LukitasMediumWidget.kt`, `RefreshWorker.kt`), `android/.../tile/CaptureTileService.kt` and the deep links `lukitas://add` and `lukitas://capture`.

**Interfaces:**
- Consumes `writeWidgetSnapshot` (Task 10), `openAddSheet` (Task 11) and `openCapture` (Task 12).
- Produces the snapshot keys `remaining`, `spent`, `budgetTotal`, `currency`, `locale`, `month`, `mood`, `updatedAt`, `signedIn` and `hideAmount`.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - Glance rendering tests per state: signed in with budgets, without budgets ("Gastado este mes"), signed out ("Abre Lukitas para empezar"), offline (with "hace un rato"), and amount hidden (••••).
  - `after sign out the widget never shows the previous figure`: this is Review Focus 4.
  - Emulator tests: `＋ opens the add sheet` and `🎤 opens capture listening`.
  - `RefreshWorker updates the snapshot from GET /v1/summary and is scheduled about every 3 h`.
- [ ] **Step 2:** Implement. The refresh reads the session token through the same Keystore-backed storage, so there's no second copy.
- [ ] **Step 3:** Run the tests: PASS. On the founder's phone, measure the time from tapping 🎤 to listening, warm and cold, and record it in the task report.
- [ ] **Step 4:** Commit `feat(mobile): home-screen widget and quick settings tile`.

### Task 16: Local notices (spec §7.2)

**Files:**
- Create `apps/mobile/lib/notices/`, using WorkManager and the platform notification APIs.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `at 9:00 one notice groups today's pending recurring payments: "Hoy vencen Arriendo y Spotify"`.
  - `no pending today means no notice`.
  - `the switch in settings stops it`.
  - `a guest not opening the app for 45 days gets "Tus datos se borrarán en 15 días si no agregas tu correo"`.
  - `the notification permission is asked only before the first notice, with one sentence on why`.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the tests: PASS.
- [ ] **Step 4:** Commit `feat(mobile): two local notices, nothing more`.

### Task 17: F-Droid readiness, release and emulator CI (spec §8)

**Files:**
- Create `apps/mobile/fastlane/metadata/android/{es-ES,en-US}/` (title, short and full description, changelogs and screenshots) and `apps/mobile/scripts/release.sh`.
- Modify `apps/mobile/android/app/build.gradle`: `versionName` from the tag `mobile-vX.Y.Z` and a monotonic `versionCode`.
- Modify CI: the emulator integration tests in the `mobile` job, against compose.

**Steps:**
- [ ] **Step 1:** `release.sh` reads the keystore path and password from the founder's environment, never from the repo.
  - It builds `flutter build apk --release --split-per-abi`, verifies the signatures with `apksigner` and prints the SHA-256 fingerprint for `ANDROID_CERT_SHA256`.
  - It writes to `apps/mobile/dist/`, which is git-ignored.
- [ ] **Step 2:** CI runs the integration tests on the emulator with the dev stack and `E2E_NOW` pinned. Expected: green.
- [ ] **Step 3:** Run the reproducibility check: two clean release builds of the same commit, unsigned, give identical APKs (`diffoscope` or `sha256sum`). Record the result; differences become a ledger note for the F-Droid submission later.
- [ ] **Step 4:** Commit `chore(mobile): F-Droid metadata, release script and emulator CI`.

### Task 18: First APK for the founder

- [ ] **Step 1:** Set `ANDROID_CERT_SHA256` in the personal install's `.env`. The founder does this, since the controller never reads that file. Redeploy, then run `smoke.sh`.
- [ ] **Step 2:** The founder runs `release.sh` and installs the APK on their phone.
- [ ] **Step 3:** Go through the checklist on the phone:
  - guest entry;
  - email entry;
  - a passkey with their provider;
  - ＋ from the widget in under 5 s;
  - 🎤 with two movements in under 10 s;
  - undo;
  - claiming an email;
  - widget refresh;
  - hiding the amount.

  Fix what fails before handing the APK to friends.
- [ ] **Step 4:** The final whole-branch review on the most capable model, then finishing-a-development-branch (a PR into `main`; the required checks pass).
