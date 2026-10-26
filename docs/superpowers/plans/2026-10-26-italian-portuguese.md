# Italian and Portuguese (Portugal) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Italian (`it`) and European Portuguese (`pt`) everywhere Lukitas speaks: the landing, the web, the app, the widget, the notices, the emails and quick capture by voice and by typed sentence.

**Architecture:** Widen the locale set in every place that fixes it today. Add four-language catalogs guarded by parity tests. Extend the shared parser contract with per-language rules and cases. Add the Vosk models for both languages as opt-in downloads.

**Tech Stack:** The existing tooling: use-intl, ARB, Android string resources, `packages/core/quick-capture`, Vosk and the parity harness.

**Spec:** `docs/superpowers/specs/2026-10-26-italian-portuguese-design.md`

## Global Constraints

- **Locales:**
  - The set is `es | en | it | pt`.
  - `it-*` maps to `it`, and `pt-*` (including `pt-BR`) maps to `pt`.
  - Spanish stays the default and the fallback.
- **Portuguese:** European spelling and vocabulary throughout ("telemóvel", "ecrã", "registar").
- **Copy:**
  - Copy lives only in the catalogs, ARB and string resources.
  - Every key exists in all four, with the same placeholders, and the parity tests enforce this.
  - The tone is Lukitas' voice: warm, plain, positive.
- **Money:**
  - EUR is the default for `it` and `pt`.
  - Formats match `Intl` for `it-IT` and `pt-PT`, and the app matches the web.
  - "lukas" and "palos" stay COP-only.
- **No Google, and no new permissions.** All new voice models are Apache-2.0. Publishing release assets needs the founder's approval.
- **Process:**
  - TDD.
  - Path-specific commits with no Co-Authored-By line, and no push without the founder.
  - Never touch the `lukitas-personal-*` containers or `deploy/personal/.env`.

## Review Focus

1. **Long words:** Italian and Portuguese strings must not truncate the buttons, the tabs, the bottom bar or the widget at 360 px or at text scale 1.3. Tested in Task 5.
2. **A `pt-BR` phone or browser:** gets `pt`, never Spanish. Tested in Task 1.
3. **Decimal commas and thousands dots:** "15,50 €" and "1.234,50 €" are read and shown correctly in `it` and `pt`. Tested in Tasks 1 and 3.
4. **Mixed language:** a person on `it` who types a Spanish sentence gets the web's behaviour for an unknown phrasing (unread fragments), not a crash. Tested in Task 3.
5. **Emails:** a sign-in code requested from an `it` or `pt` device arrives in that language. Tested in Task 2.

---

### Task 1: Locale plumbing and formats

**Files:**
- `apps/api/src/auth.ts` (`Locale`, `localeFor`, regional default currency);
- `packages/core` locale enums;
- `apps/web/app/i18n/format.ts` and `catalog.ts`;
- the app's `localeName` handling and `l10n` config;
- `apps/mobile/lib/money/format.dart`;
- `packages/core/quick-capture/cases.schema.json` (the locale enum only).

- [ ] **Step 1:** Write failing tests:
  - `localeFor` maps `it-IT`, `it` and `pt-PT`, `pt-BR`, `pt` correctly, and unsupported tags still fall back;
  - new `it` and `pt` accounts default to EUR;
  - `formatMoney` and date vectors for `it-IT` and `pt-PT` match `Intl` on the web, and the app matches the web.
- [ ] **Step 2:** Implement, run every suite, and commit `feat: Italian and Portuguese locales and formats`.

### Task 2: Catalogs, landing and emails

**Files:**
- the web catalogs `it.json`, `pt.json`, `app.it.json` and `app.pt.json`;
- the app's `app_it.arb` and `app_pt.arb`;
- the Android `values-it` and `values-pt` strings;
- the landing routes `/it`, `/pt`, `/it/roadmap` and `/pt/roadmap`, plus the language switcher;
- the API's email templates;
- fastlane `it-IT` and `pt-PT`.

- [ ] **Step 1:** Write failing tests:
  - catalog parity across four languages on the web, in the app and in the Android strings;
  - the landing routes render;
  - the sign-in and claim emails come out in `it` and `pt`.
- [ ] **Step 2:** Translate. Write a sample file, `docs/i18n/it-pt-sample.md`, with about 40 representative lines per language for the founder to review.
- [ ] **Step 3:** Run every suite and commit `feat: Lukitas speaks Italian and Portuguese`.

### Task 3: The parser in Italian and Portuguese

**Files:**
- `packages/core/quick-capture/README.md` (the rules per language) and `cases.json` (at least 40 cases per new language);
- the app's `lib/capture/parser/`, including `words.dart` and `amounts.dart`;
- the web parser, if the web has one.

- [ ] **Step 1:** Write the new cases first and watch them fail. They cover:
  - number and scale words;
  - kind words;
  - dates;
  - connectors and separators, with the no-connector rule;
  - decimal commas;
  - a mixed-language sentence (Review Focus 4).
- [ ] **Step 2:** Implement and run the shared cases everywhere. Commit `feat: quick capture reads Italian and Portuguese sentences`.

### Task 4: Voice in Italian and Portuguese

**Files:**
- `apps/mobile/lib/capture/models_download.dart` (new models with their SHA-256);
- the grammar vocabulary per language;
- the docs.

- [ ] **Step 1:** Download the official `vosk-model-small-it-0.22.zip` and `vosk-model-small-pt-0.3.zip` and compute their hashes. Write failing tests for the model selection per locale and for the grammar JSON per language.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** The controller asks the founder before adding the two zips to the `voice-models-v1` release.
- [ ] **Step 4:** Run the spike: about 10 recorded sentences per language, scored against the 80% bar, with the result written to `docs/superpowers/reports/`. If `pt` falls below the bar, label its voice as beta in the copy.
- [ ] **Step 5:** Commit `feat: voice capture in Italian and Portuguese`.

### Task 5: Sweep

- [ ] **Step 1:** Add parity pairs for the `it` and `pt` night variants of home, the add sheet and settings. Add the overflow tests at 360 px and text scale 1.3 (Review Focus 1). Fix any overflow.
- [ ] **Step 2:** Run every suite, including the web e2e for the landing and sign-in in `it` and `pt`, and the emulator suite.
- [ ] **Step 3:** The founder reviews the copy sample. Then push, open a PR, build the APK, and run the final review.
