# Lukitas — Italian and Portuguese (Portugal)

- **Date:** 2026-10-26
- **Status:** draft for review
- **Founder decisions (2026-10-26):**
  1. Add Italian (`it`) and Portuguese, the Portugal variant (`pt-PT`, stored as `pt`).
  2. Everything gets the new languages, voice included.

## 1. Goal

A person can use all of Lukitas in Italian or European Portuguese: the landing, the web app, the Android app, the widget, the notices, the emails, and quick capture by voice and by typed sentence. Spanish stays the default and the fallback. English stays.

## 2. What changes

### 2.1 Locales everywhere

The locale set becomes `es | en | it | pt` in every place that fixes it today:

| Where | What changes |
|---|---|
| Web | `apps/web/app/i18n/format.ts`, the catalogs and their parity test |
| API | `apps/api/src/auth.ts` `Locale`, `localeFor` and its tag handling |
| Core | `packages/core`, for any locale enums |
| Parser contract | `packages/core/quick-capture/cases.schema.json` |
| App | ARB files and `localeName` handling |
| Widget | Android string resources |
| Fastlane | metadata, adding `it-IT` and `pt-PT` |

A language tag maps as follows:
- `it-*` maps to `it`.
- `pt-*` maps to `pt`. That includes `pt-BR`, which then reads European Portuguese text until a Brazilian variant exists.
- An unsupported tag still falls back to Spanish.

### 2.2 Copy

- **Catalogs:** the web catalogs (`es.json`, `app.es.json` and their pairs) and the app ARB get full `it` and `pt` versions.
- **Voice:** the same voice as Spanish. Warm, plain, positive, in Lukitas' tone, with short sentences.
- **Portuguese:** European, with pt-PT spelling and vocabulary (for example, "telemóvel", "ecrã" and "registar").
- **Parity tests:** the existing catalog parity tests extend to four languages. Every key exists in every catalog, with matching placeholders.
- **Review:** the founder reviews a sample of each language before release.
- **Landing:** gets `/it` and `/pt` (with their roadmaps), alongside `/en`. The language switcher lists the four.
- **Emails:** sign-in code and claim code, in four languages.

### 2.3 Money and formats

- **Default currency:** EUR for both new locales, through the regional default currency rules used at sign-up.
- **Formatting:** `formatMoney` and dates in `it-IT` and `pt-PT` must match `Intl` on the web, and the app must match the web. Their test vectors are extended.
- **"Lukas" and "palos":** they stay COP-only slang and don't apply to `it` or `pt`.

### 2.4 Quick capture (voice and typed sentence)

- **Voice models:** Vosk small models for Italian (`vosk-model-small-it-0.22`) and Portuguese (`vosk-model-small-pt-0.3`), both Apache-2.0.
  - They are added to the `voice-models-v1` release as new assets, after the founder approves.
  - They use the same opt-in, resumable, SHA-256-checked download as the existing models.
  - The Portuguese model is trained mostly on Brazilian speech, and the spike measures how it does on European Portuguese.
- **Grammar pass:** the two-pass biasing gets each language's vocabulary for amounts, kinds, dates and separators.
- **Rules parser:**
  - number words in each language, for example "quindici euro e cinquanta" and "quinze euros e cinquenta";
  - scale words: "mila", "mil", "milhão", "milione";
  - kind words: "ho speso", "pagato", "ricevuto", "gastei", "paguei", "recebi";
  - dates: "ieri", "oggi", "ontem", "hoje";
  - connectors: "in", "per", "al", "em", "no", "na", "para";
  - separators: "e" and commas, with the same no-connector rule;
  - decimal commas.
- **Shared contract:** `cases.json` gains at least 40 cases per new language. The web and the app run the same cases.
- **Model management:** "Modelos descargados" (Stage 3d) lists the new models when they're downloaded. Until 3d lands, the existing "delete voice models" covers them.
- **Spike:** before shipping voice for the new languages, run a short check like Stage 3's. The founder or a friend records about 10 sentences per language. Measure amounts right, and check that the two-pass merge holds. The bar is the same as Stage 3: 80% or better. If European Portuguese falls short with the Brazilian-trained model, typing still works and the voice option is labelled beta.

## 3. Testing

- Catalog parity across four languages, in the web, the app and the Android strings.
- Money, date and parser tests per language, with the parser's shared cases run on the web and in the app.
- Web e2e for the landing and sign-in, run in `it` and `pt`.
- Parity pictures: the harness gains `it` and `pt` night variants of key stories (home, the add sheet, settings) to catch overflow from longer words.
- Review Focus: German-length overflow. Italian and Portuguese strings run 10–25% longer than Spanish, so buttons, the tabs, the bottom bar and the widget must not truncate badly at 360 px or at text scale 1.3.

## 4. Order

1. Locale plumbing in the API, core, web and app, plus formats.
2. Catalogs, landing and emails.
3. Parser: its rules and cases.
4. Voice: the models, the release assets (with approval) and the spike.
5. Sweep: overflow checks, parity, every suite, an APK and a final review.

## 5. Risks

- **Translation quality:** it is machine-assisted, so the founder's review of samples is the gate.
- **European Portuguese speech:** may underperform with the Brazilian-trained model. See the spike in 2.4.
- **Size:** about 12 to 16 hours of work, mostly copy and parser.
