# Lukitas — Stage 3: Android app, widget and quick capture

- **Date:** 2026-10-22
- **Status:** draft for review
- **Builds on:**
  - `docs/superpowers/specs/2026-10-20-lukas-design.md` (overall design, §3.3 Stages, Quick capture, Guest mode);
  - `docs/superpowers/specs/2026-10-21-stage-2-web-design.md` (web app, API contract, feedback, tokens);
  - the personal install in `deploy/personal`.
- **Brainstorm record:** `.superpowers/brainstorm/2026-10-22-stage-3-notes.md` (local, not committed).

## 1. Goal

An Android app that records money faster than the web: a home-screen widget with ＋ and a microphone, a sentence turned into movements, and "Te quedan" at a glance. Friends can try it as guests before giving an email. It is free software from the first line, so it can be listed on F-Droid.

### Who it is for (first version)

- The founder and a few invited friends.
- **Distribution:** the founder hands out a signed APK by hand. Play internal testing remains possible later.
- **Server:** the founder's personal install (`app-lukas.andersonlaverde.com`) with its sign-in allowlist.
- **Not in this version:**
  - no public Play listing;
  - no cloud server;
  - no F-Droid submission. The app is built to be ready for one (§8).

### Success criteria

1. **Fast capture.** From the widget's ＋, an expense is saved in under 5 seconds. From the widget's 🎤:
   - a spoken sentence with two expenses becomes two saved movements in under 10 seconds;
   - listening starts within 1 s from a warm start, and about 2 s from a cold one.
2. **Guests.**
   - A friend opens the app and taps "Probar sin correo". They use it with their own data without giving an email.
   - Later they add an allowlisted email and keep every movement: same account, nothing copied.
3. **The widget** shows the current "Te quedan" (or "Gastado") and is never more than 3 hours stale while the phone has a connection.
4. **No Google.** The APK contains no Google Play Services, Firebase or other proprietary dependency, and CI fails if one appears.
5. **Languages and themes.** Everything works in Spanish (default) and English, in night (default) and day themes.

### Founder decisions behind this spec (2026-10-22)

- **Scope "A":** quick capture first. Categories, insights, recurring, import, export and account deletion stay on the web for now.
- **Guest mode is in**, and the server stays open to anonymous sign-up for now, with no IP limits. The email allowlist governs who can add an email.
- **No Google Play Services in any build,** including a future Play build.
- **F-Droid is the eventual target:** free dependencies and free model licences only.
- **Voice:** a free on-device model if at all possible. The system recognizer is the last resort.
- **Notifications:** as few as possible, and only essential ones.
- **The voice and model spike runs first.** If Vosk is good enough, ship with it.

### Out of scope (this stage)

- **Screens:** web-parity screens in the app (categories, insights, recurring, import, export, delete account). The app links to the web for them.
- **Push:** server-originated push. UnifiedPush is the path when it's needed, §7.
- **Offline writes:** an offline write queue. Failed saves keep the input and offer a retry with the same idempotency key.
- **Widget actions:** recording from the widget without opening the app.
- **Platforms:** iOS (later, from the same Flutter code, with a WidgetKit widget).
- **Web:** guest mode and quick capture on the web. The parser's shared test cases make the web version cheap later.
- **Cloud AI:** AI assist in the cloud (overall spec, Quick capture phase 2).

## 2. Parts and order

| # | Part | Ships |
|---|------|-------|
| 1 | Voice and model spike | A measured decision: speech engine and parser strategy. The spike's code is thrown away |
| 2 | Guest mode on the server | Anonymous accounts, in-place email claim, cleanup, Android asset links |
| 3 | Sentence parser | Rules plus shared test cases, with an optional small on-device model per the spike |
| 4 | Flutter app | `apps/mobile` with entry, home, add, capture, save progress and settings |
| 5 | Widget | A Kotlin and Jetpack Glance widget in two sizes, plus a Quick Settings tile |
| 6 | Local notices, F-Droid readiness, tooling | Two local notices, the no-Google check, fastlane metadata, release script, CI |

Each part is testable on its own. The plan follows this order.

## 3. Part 1: voice and model spike

**Question.** Which free, on-device speech-to-text and which parsing strategy turn a Colombian Spanish sentence into the right movements, fast enough, at an acceptable size?

**Candidates.**
- **Speech:**
  - **Vosk**, Spanish and English small models of about 40–50 MB each, one model per language.
  - **whisper.cpp**, the smallest multilingual model that works.
- **Parsing:**
  - **The rules parser** (§5).
  - **Two small open models** run with llama.cpp and grammar-constrained JSON output:
    - one of about 0.5B parameters (Qwen2.5-0.5B-Instruct or Qwen3-0.6B, or SmolLM2);
    - one of about 1.5B (Qwen2.5-1.5B or Qwen3-1.7B).

    Each one's licence must be confirmed as Apache-2.0 or MIT before use. Gemini Nano and Gemma are excluded: they depend on Google and aren't free licences.

**Method.**
- A throwaway Flutter app on the founder's phone, kept outside `apps/mobile`.
- The founder records about 20 Colombian Spanish sentences, a few English ones and a few with background noise:
  - amounts in words and digits, "lukas" and "palos";
  - two movements in one sentence;
  - "ayer";
  - store names.
- Every speech × parser combination runs on the same recordings.

**Measures.**
- correct amounts, kinds, dates and names per movement;
- the speech engine's word errors;
- latency from end of speech to preview;
- download size, peak memory, and that it works offline.

**Decision rules.**
- **Speech:**
  - Vosk if it gets the amounts right in at least 9 of 10 sentences, and the preview appears within 1 s of the end of speech.
  - Otherwise Whisper, if it meets the same bar.
  - Otherwise the platform `SpeechRecognizer`, with honest copy that the audio may go to the phone's speech service.
- **Parsing:**
  - rules only, if they reach the same bar;
  - else a hybrid: rules first, the small model only for what the rules leave unparsed, downloaded only when the person turns it on;
  - the bigger model only if the small one fails the bar and its size and latency are acceptable to the founder.
- **Fallback:** typing the sentence is always available.

**Output.** A report (`docs/superpowers/reports/…-stage-3-voice-spike.md`) with the numbers and the decision. It sets the engine and the strategy for parts 3 and 4.

## 4. Part 2: guest mode on the server

### 4.1 Anonymous accounts

- Better Auth's `anonymous` plugin creates a real user with no email. The device keeps the bearer session (the `bearer` plugin is already on).
- **Open on this install:**
  - anonymous sign-up skips `SIGN_IN_ALLOWLIST`;
  - no IP limits beyond the existing global auth rate limit (founder decision);
  - an env flag `GUEST_SIGNUP` (default on) allows turning it off.
- **New guests:**
  - the default account currency follows the web's rule: CO or America/Bogota → COP, Europe → EUR, else USD;
  - the time zone and locale come from the device.
- `GET /v1/me` gains `isAnonymous: boolean`.

### 4.2 Saving progress: an in-place email claim

Better Auth's built-in link creates a new user and deletes the anonymous one, with an `onLinkAccount` hook to copy data. That is fragile and contradicts "nothing copied". Instead, the guest's own user receives the email.

**The flow:**
1. `POST /v1/me/claim-email/send` with `{ email }`.
   - Only for an anonymous session.
   - If the email isn't on the allowlist, it answers `sign_in_not_allowed` with the existing copy and sends nothing.
   - If the email belongs to another user, it answers `email_taken`, sends nothing, and the app says to sign in with that email. The guest account stays as it is.
   - Otherwise it sends a code by the existing mail path, with the same email throttle as sign-in.
2. `POST /v1/me/claim-email/verify` with `{ email, code }`.
   - On a valid code, in one transaction: set `email` and `emailVerified`, clear `isAnonymous`.
   - The user id, sessions and every row stay.
   - A wrong or expired code gets the same messages as sign-in.

**Rules:**
- Codes are hashed and single-use.
- Attempts are limited like sign-in codes.
- The claim and a concurrent claim of the same email by another guest are race-safe: a unique email constraint, and the second gets `email_taken`.

### 4.3 Passkeys for guests

A guest may register a passkey on their anonymous user (the existing passkey routes). The app explains that without an email, losing the passkey or the phone loses the account. Sync to another device, AI and MCP need an email.

### 4.4 Cleanup

- A daily job in the API process takes a Postgres advisory lock so only one instance runs it.
- It deletes anonymous users with no session activity for 60 days, with all their data (the existing cascade).
- Users with an email are never auto-deleted.
- The 45-day warning is a local notice on the phone (§7).
- "Activity" is the latest session `updatedAt`.

### 4.5 Android App Links and passkeys

- The personal install serves `/.well-known/assetlinks.json` from Caddy. It lists the package `com.andersonlaverde.lukitas` and the SHA-256 of every signing certificate: the founder's release key now, F-Droid's later.
- The `release.sh` script (§8) prints the fingerprint.
- **Two uses:**
  - passkeys for the app on `rpID app-lukas.andersonlaverde.com`;
  - magic links (`/auth/verify?…`) open the app when it's installed.

### 4.6 The web

The web is unchanged: sign-in stays email-only through the allowlist. A guest cannot sign in on the web; the app says so when relevant.

### 4.7 Tests

- **Sign-up:** a guest sign-up gives an empty account with `isAnonymous: true`.
- **Claim:**
  - claiming an allowlisted email keeps the same id and the same transactions;
  - a non-allowlisted email gets `sign_in_not_allowed` with no mail sent;
  - a taken email gets `email_taken` and no merge;
  - two concurrent claims leave one winner.
- **Cleanup:** it deletes only anonymous users inactive for 60 days.
- **Isolation:** RLS holds between guests.
- **Asset links:** `assetlinks.json` is served with the configured fingerprints.

## 5. Part 3: sentence parser

### 5.1 Input and output

- **Input:**
  - the sentence (a transcript or typed text);
  - the locale (`es` or `en`) and the account currency;
  - today in the user's time zone;
  - the user's categories;
  - the name → usual-category pairs (`GET /v1/transactions/suggestions`).
- **Output:** a list of drafts, each `{ amount (cents, ×100 as everywhere), kind: expense|income, name, categoryId|null, date }`, plus a list of fragments that couldn't be read. Those are never dropped silently.

### 5.2 What the rules read

- **Amounts, in digits and in words** (on-device speech often writes numbers as words):
  - es:
    - "15.000", "15 mil", "quince mil", "15k";
    - "15 lukas" / "una luca" (×1.000) and "4,3 palos" / "medio palo" (×1.000.000), in COP only;
    - "9,50", "nueve con cincuenta" (EUR, USD).
  - en: "15,000", "fifteen thousand", "12.50", "twelve fifty".
- **Several movements:** "y", "and", commas, "también" and "also" split only where a new amount starts. So "pan y leche 8 mil" is one movement.
- **Kind:**
  - Income: "me pagaron", "recibí", "me llegó", "ingreso", "got paid", "received".
  - Expense: "gasté", "pagué", "compré", "spent", "paid".
  - The default is expense.
- **Date:** "hoy"/"today", "ayer"/"yesterday", "antier"/"anteayer", and "el lunes"/"on Monday" (the most recent past one). The default is today.
- **Name:** what remains after the verb, the amount, the date and the function words ("en", "de", "para", "on", "for").
- **Category**, tried in this order:
  1. the usual category of that name;
  2. a category whose name matches, ignoring accents;
  3. none, so the person picks it in the preview.

### 5.3 Shared test cases

- **The file:** `packages/core/quick-capture/cases.json`, with input, locale, currency, today and expected output. It starts with about 60 cases, most of them Colombian.
- **Who uses it:** the Dart parser in the app runs every case. A future TypeScript parser on the web runs the same file.

### 5.4 Optional small model (per the spike)

- **Hybrid:** if the spike picks a hybrid, the model only sees the fragments the rules couldn't read.
- **Output:** constrained by a grammar to the draft JSON, then validated (amount > 0, a known category or none). It never saves without the preview.
- **Download:** opt-in in settings, from this repo's GitHub releases, with a SHA-256 check before use.

### 5.5 Saving a batch

- **New endpoint `POST /v1/transactions/batch`:**
  - takes 1–20 transactions and one `Idempotency-Key`;
  - all or nothing, in one database transaction, with the same validation and lock pattern as single create;
  - returns the created ids.
- **Undo:** `POST /v1/transactions/batch-delete` with those ids soft-deletes them, so one undo reverts the whole batch.
- **The app:** one celebration with the total, and one undo.
- **Tests:** API tests for all-or-nothing, idempotent replay, a 21-item batch refused, and RLS.

## 6. Part 4: the Flutter app (`apps/mobile`)

### 6.1 Screens

1. **First run.**
   - Lukitas waves.
   - "Probar sin correo" (guest), "Entrar con mi correo" (code or magic link) and "Entrar con huella".
   - The passkey button shows only when the phone supports third-party passkeys (Android 14+ with a provider).
2. **Home.**
   - The month, Lukitas' line, and "Te quedan" or "Gastado" in large type.
   - The movements list with the web's gestures (Stage 2 Task 12c):
     - swipe left deletes, with an 8 s undo;
     - swipe right edits, or marks a pending row paid;
     - a sticky Movimientos tab.
   - Event lines name the movement and expire after 10 s (Task 12d).
3. **Add sheet.**
   - The full keypad, amount, name with two rows of suggestions, and categories.
   - It closes when dragged down from anywhere.
   - On a failed save it keeps the input and offers "Reintentar" with the same idempotency key.
4. **Capture.**
   - 🎤 listens with "¿En qué gastaste?". The person can also type.
   - The preview shows one editable, removable card per draft, plus the unread fragments.
   - "GUARDAR N" saves the batch (§5.5).
5. **Guarda tu progreso** (guests only): the email claim (§4.2) and adding a passkey, with the honest explanation.
6. **Settings.**
   - Language, theme, sound, vibration and the two local notices.
   - Hide the amount in the widget.
   - The server URL, defaulting to `https://app-lukas.andersonlaverde.com` and changeable.
   - About, with licences, including model licences.
   - Sign out, and "Más en la web".

### 6.2 Feel

- **Lukitas:** the existing sprite sheets (wave, celebrate, worried).
- **Haptics:** native Android haptics (`VibrationEffect.Composition` on Android 11+, simple patterns below) through a small Kotlin platform channel.
- **Sounds:** the web's sounds, with a mute switch.
- **Motion:** spring timings matching the web's motion tokens. Everything respects the system's "remove animations".
- **Colours and sizes:** generated from `docs/design/system/project/tokens.json`, the web's source, so both stay in step. Night is the default.

### 6.3 Inside

- **API client:** generated from the API's OpenAPI document, like the web's types. CI fails when it's stale.
- **Session:** a bearer token in Android Keystore-backed storage (`flutter_secure_storage`, which needs no Google).
- **Offline:** the last loaded summary and list stay visible while offline. There are no offline writes.
- **Platform:** Android 8 (API 26) or newer, built for arm64-v8a and armeabi-v7a.
- **Dependencies:** only free ones. The no-Google check is in §8.
- **Languages:** Spanish and English catalogs (ARB) with a parity test.

### 6.4 Tests

- **Unit:** formatting (e.g. "$50.000 (50 lukas)"), the parser running every shared case, and state logic.
- **Widget tests with golden images:** key screens in night and day.
- **Integration tests on an Android emulator against the dev stack:**
  - guest entry;
  - add an expense;
  - capture a sentence, with audio replaced by a fixed transcript;
  - batch save and undo;
  - claim an email;
  - the widget's deep links.

## 7. Part 5: the widget, plus the local notices

### 7.1 Widget

- **Technology:** Kotlin and Jetpack Glance (AndroidX, free, no Google Play Services). It shares data with the app through `home_widget`.
- **Small (2×1):** "Te quedan" and ＋.
- **Medium (4×2):** Lukitas' face for the month's state, "Te quedan" with its progress bar, the month, ＋ and 🎤.
- **Buttons:**
  - ＋ opens the app on the add sheet with the keypad ready;
  - 🎤 opens the app listening.
  - Target: listening within 1 s from a warm start, about 2 s cold; measured on the founder's phone.
- **Quick Settings tile:** a mic tile does the same as 🎤.
- **Freshness:**
  - every app load or save updates the widget;
  - a WorkManager job (AndroidX) refreshes it about every 3 hours and at day and month change, using the stored session;
  - offline, it shows the last figure with a subtle "hace un rato".
- **Privacy:** a setting replaces the amount with "••••".
- **States:**
  - signed out: "Abre Lukitas para empezar";
  - guest: the same as signed in;
  - no budgets: "Gastado este mes".
- **Theme:** follows the app's theme.
- **Tests:** Glance rendering tests for each state, plus emulator tests for the deep links. A short manual checklist on the founder's phone covers sizes, refresh, offline and the hidden amount.

### 7.2 Local notices (only two)

Both are scheduled on the device with WorkManager or AlarmManager. There's no server push and no Google.

1. **"Hoy vence…"**
   - At 9:00 local time, one notice groups the recurring payments still pending today, e.g. "Hoy vencen Arriendo y Spotify".
   - Tapping it opens home with them in view.
   - On by default, with a switch in settings.
2. **The guest warning.** If the app isn't opened for 45 days on a guest account: "Tus datos se borrarán en 15 días si no agregas tu correo".

There are no other notices: no summaries, no "¿ya anotaste hoy?", no promotions. The notification permission (Android 13+) is asked only the first time there's something to announce, with one sentence on why. Server-originated push, if ever needed, uses UnifiedPush (ntfy or another distributor), never FCM.

## 8. Part 6: F-Droid readiness, tooling and release

- **No Google, checked in CI.** CI runs on every PR that touches `apps/mobile`. It fails if the resolved Gradle or pub dependencies include `com.google.android.gms`, `com.google.firebase`, `play-services` or any other proprietary artifact. Passkeys use AndroidX `credentials` without its Play Services artifact.
- **Fastlane metadata in the repo** (`apps/mobile/fastlane/metadata/android/{es-ES,en-US}`): title, short and full descriptions, screenshots, and a changelog per `versionCode`.
- **Reproducible builds:**
  - pinned Flutter, Gradle wrapper, Android Gradle Plugin and NDK versions;
  - no dynamic dependency versions;
  - `versionName` from tags such as `mobile-v1.0.0`, and a monotonic `versionCode`;
  - no secrets in the build.
- **No trackers.** No analytics or automatic crash reporting (F-Droid's "Tracking" anti-feature), as on the web.
- **Licences.** The app is AGPL-3.0 like the repo. Model and data licences are listed in About.
- **Tooling on the founder's Mac:** a pinned Flutter SDK and the Android command-line tools. Android Studio isn't required.
- **CI** (GitHub Actions, on PRs that touch `apps/mobile` or the API contract; skipped jobs count as passing for the required checks):
  - analyze, unit and widget tests;
  - build a debug APK;
  - the no-Google check;
  - integration tests on an emulator (`reactivecircus/android-emulator-runner`, free) against the compose dev stack.
- **Release** (`apps/mobile/scripts/release.sh`):
  - builds a signed release APK with the founder's key, which lives only on the Mac, never in the repo or in CI;
  - prints the certificate's SHA-256 for `assetlinks.json`;
  - writes the APK to a git-ignored `dist/`.

  Automated signed releases are a later decision.

## 9. Decisions for the founder at spec review

- **Android package name:** `com.andersonlaverde.lukitas` (founder, 2026-10-22: no project domain and no store listing yet).
  - Changing it later makes Android treat the result as a new app. Friends install the new one and sign in again; their data is on the server, so nothing is lost.
  - **Guests:** they must add an email first. A guest's only key is the session on that phone. A passkey still works, because it belongs to the domain, not the package.
  - **Lost locally:** settings, the hidden-amount choice and a downloaded voice model, which downloads again.
  - **Widget:** it has to be placed again.
  - **Asset links:** `assetlinks.json` lists both packages during the switch.
- **The `GUEST_SIGNUP` flag** defaults to on for the personal install.

## 10. Risks

| Risk | Mitigation |
|------|------------|
| Free on-device speech is too inaccurate for Colombian Spanish | The spike decides with numbers. Fallbacks: Whisper, then the system recognizer with honest copy. Typing always works |
| A small model is slow or large on mid-range phones | Opt-in download, hybrid use only for what the rules can't read, measured in the spike |
| Third-party passkeys without Play Services vary by phone and Android version | Email code always works. The passkey button only shows when supported |
| Open anonymous sign-up on the founder's Mac is abused | The `GUEST_SIGNUP` flag turns it off, the existing global rate limit applies, and 60-day cleanup runs. IP limits can be added later if needed |
| A cold start makes the widget mic slower than 1 s | Measured. The 1 s target is for a warm start, about 2 s cold. No splash work on the capture route |
| F-Droid later rejects a dependency or model | The no-Google CI check and free-licence-only models from day one |
