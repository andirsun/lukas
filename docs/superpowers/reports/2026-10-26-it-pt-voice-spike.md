# Italian and Portuguese voice spike

**Date:** 2026-10-26 (written; the recorded run is still to do).
**Spec:** §2.4 of `docs/superpowers/specs/2026-10-26-italian-portuguese-design.md`. **Plan:** Task 4, step 4.
**Method it repeats:** `docs/superpowers/reports/2026-10-22-stage-3-voice-spike.md` (two-pass Vosk: a free pass plus a grammar-biased pass, merged by word timestamps, then the rules parser).

## Status

- **Not decided.** The bar is measured on real voices, and those do not exist yet: the founder or a friend must record the sentences below. The results table is empty.
- **What is shipped meanwhile:** voice is on for Italian and for Portuguese. Both are labelled **beta** in the copy (the offer title and body in the app, and the four store descriptions) until the recorded run clears 80% for that language: Portuguese because European Portuguese is unmeasured (spec), Italian because the synthetic run was at the bar only after a merge fix (below).
- **A provisional synthetic run exists** (macOS text-to-speech voices through the real models and the real merge and parser). It is **not** the spike and cannot pass or fail it. Its one worrying result, for Italian, is in "Provisional synthetic run" below.

## What is being tested

- **Models:** `vosk-model-small-it-0.22` (49 665 141 bytes) and `vosk-model-small-pt-0.3` (32 453 112 bytes), both Apache-2.0, from https://alphacephei.com/vosk/models. Their SHA-256 sums are in `apps/mobile/lib/capture/models_download.dart`.
- **Passes:** the free pass, and the grammar pass with each language's vocabulary (`apps/mobile/lib/capture/engine/grammar.dart`), merged by rule v2 (`apps/mobile/lib/capture/engine/merge.dart`), then `parseSentence` with the Italian or Portuguese rules.
- **The question:** are amounts right in at least 80% of the sentences (8 of 10), per language. The question for Portuguese is also whether the Brazilian-trained model copes with European Portuguese; the speaker for `pt` must be a European Portuguese speaker.

### The grammar vocabulary was checked against the models

- The small models ship no `words.txt`. Their vocabulary is the symbol table embedded in `Gr.fst` (`graph/Gr.fst` in the Italian zip; `Gr.fst` in the Portuguese one): 200 006 symbols for Italian, 99 105 for Portuguese.
- Every grammar word is in it: 1 058 words for Italian (1 057 plus `[unk]`) and 87 for Portuguese (86 plus `[unk]`). The checked subset is stored in `apps/mobile/test/fixtures/vosk_vocab_it.json` and `vosk_vocab_pt.json`, and `apps/mobile/test/capture/grammar_test.dart` fails if a grammar word is missing from it.
- It was checked a second way, with the real library: `vosk_model_find_word` from the `libvosk.so` of `vosk-android` 0.3.75, run on an Android emulator, returns a valid id for all 1 058 and 87 words, and -1 for the words listed as absent in the fixtures.
- **Words the models do not have**, so they are not in the grammar (the free pass or the typed parser still reads them where they occur): Italian `altroieri`, `avantieri` and 121 compound numbers such as `centoottanta` and `novantatre`; Portuguese `milhao`, `dolar`, `dolares`, `centimo`, `centimos`, `terca` and `cent` (the models have the accented spellings, which the grammar uses).

## Sentences to record

Same mix as Stage 3: several amounts, kinds (spent, paid, bought, received), dates (today, yesterday, a weekday), names, two movements in one sentence, decimal cents and thousands. All amounts are in euros.

Expected drafts are the parser's reading of the typed sentence (10 of 10 right in both languages, Task 3's rules). The day is relative to the day of recording. "Last Monday" is the most recent past Monday (a week back when recorded on a Monday).

### Italian (`it`)

| # | Say | Expected | Tests |
|---|---|---|---|
| it01 | ho speso quindici euro per il pranzo | expense 15,00, pranzo, today | plain amount, "ho speso" |
| it02 | ho speso quindici euro e cinquanta per il caffè | expense 15,50, caffè, today | decimal cents with "e" |
| it03 | ieri ho pagato l'affitto, ottocento euro | expense 800,00, affitto, yesterday | "pagato", "ieri", amount after the name |
| it04 | ho comprato pane e latte per otto euro e venti | expense 8,20, pane e latte, today | "comprato", cents, a name with "e" |
| it05 | mi hanno pagato milleduecento euro | income 1 200,00, no name, today | income "mi hanno pagato", thousands |
| it06 | benzina quaranta euro e farmacia dodici euro | expense 40,00 benzina and expense 12,00 farmacia, today | two movements, no verb |
| it07 | palestra centoventi euro lunedì | expense 120,00, palestra, last Monday | compound number, weekday |
| it08 | ho speso duemilacinquecento euro per le vacanze | expense 2 500,00, vacanze, today | a big compound number |
| it09 | oggi ho ricevuto trecentocinquanta euro di stipendio | income 350,00, stipendio, today | "ricevuto", "oggi" |
| it10 | ho speso dodici euro in taxi e trentacinque euro al supermercato | expense 12,00 taxi and expense 35,00 supermercato, today | two movements with a verb |

### Portuguese (`pt`, European)

| # | Say | Expected | Tests |
|---|---|---|---|
| pt01 | gastei quinze euros no almoço | expense 15,00, almoço, today | plain amount, "gastei" |
| pt02 | gastei quinze euros e cinquenta no café | expense 15,50, café, today | decimal cents with "e" |
| pt03 | ontem paguei a renda, oitocentos euros | expense 800,00, renda, yesterday | "paguei", "ontem" |
| pt04 | comprei pão e leite por oito euros e vinte | expense 8,20, pão e leite, today | "comprei", cents, a name with "e" |
| pt05 | recebi mil e duzentos euros | income 1 200,00, no name, today | income "recebi", thousands with "e" |
| pt06 | gasolina quarenta euros e farmácia doze euros | expense 40,00 gasolina and expense 12,00 farmácia, today | two movements, no verb |
| pt07 | ginásio cento e vinte euros na segunda | expense 120,00, ginásio, last Monday | hundreds with "e", weekday after "na" |
| pt08 | gastei dois mil e quinhentos euros nas férias | expense 2 500,00, férias, today | a big amount |
| pt09 | hoje recebi trezentos e cinquenta euros do cliente | income 350,00, cliente, today | "recebi", "hoje" |
| pt10 | gastei doze euros em táxi e trinta e cinco euros no supermercado | expense 12,00 táxi and expense 35,00 supermercado, today | two movements with a verb |

Optionally add two noisy takes per language (kitchen tap or street), repeating it01/pt01 and it06/pt06, and report them apart.

## Recording procedure

1. **Who and where:** one speaker per language, a native speaker (for `pt`, European Portuguese, not Brazilian). A Samsung or Pixel phone with Android 14 or later. A quiet room for the ten sentences. Normal speaking pace, no pauses to help the app, one take each; a take is repeated only if the speaker stumbled, and the stumble is noted.
2. **Models:** the two zips must already be assets of the `voice-models-v1` release (the controller uploads them after review). In the app, set the language in Settings, open quick capture and accept the voice download.
3. **Say each sentence** with the 🎤 button, and note what the preview shows before saving: every draft's amount, kind, name and date. Do not edit the drafts. If the preview is empty or shows an unread fragment, note that.
4. **Optional, for the transcripts:** record the same sentences as 16 kHz mono PCM16 WAV files with any recorder and run both passes over them off the phone, as the Stage 3 spike did, to see the free, grammar and merged texts. The throwaway runner used for the provisional run below is a 40-line C program over `vosk_recognizer_new` and `vosk_recognizer_new_grm` (100 ms chunks, `set_words(1)`, every `result` plus the final one); it is not in the repo.
5. **Write the results** in the table below, the date of the run, the phone model, and the speaker's origin.

## Scoring

- A sentence has **amounts right** when the drafts have exactly the expected amounts (in cents) and kinds, with no extra and no missing movement. This is the measure with the bar.
- **Kinds, dates and names** are counted per expected movement, separately (names compare ignoring case, accents and a leading article; an expected "no name" accepts anything).
- **The bar is 80%:** at least 8 of the 10 sentences with amounts right, per language.
- **`it` is labelled beta too** until its recorded run is at or over the bar; if it is under, the merge needs more work (see the finding below). When it clears, remove "beta" from the it copy.
- **If `pt` falls under the bar:** it stays labelled beta. Typing keeps working either way. If `pt` reaches the bar, remove "beta" from the pt copy (`captureOfferTitle`, `captureOfferBody`, the store descriptions).

## Results (to fill in)

| Language | Speaker and phone | Date | Amounts right (of 10) | Movements: amounts / kinds / dates / names (of 12) | Misses | Bar (8/10) |
|---|---|---|---|---|---|---|
| it | | | | | | |
| pt | | | | | | |

Per-sentence table, one for each language:

| # | Heard (merged text, if recorded) | Drafts shown | Amounts right | Kind | Date | Name | Note |
|---|---|---|---|---|---|---|---|
| it01 | | | | | | | |
| it02 | | | | | | | |
| it03 | | | | | | | |
| it04 | | | | | | | |
| it05 | | | | | | | |
| it06 | | | | | | | |
| it07 | | | | | | | |
| it08 | | | | | | | |
| it09 | | | | | | | |
| it10 | | | | | | | |
| pt01 | | | | | | | |
| pt02 | | | | | | | |
| pt03 | | | | | | | |
| pt04 | | | | | | | |
| pt05 | | | | | | | |
| pt06 | | | | | | | |
| pt07 | | | | | | | |
| pt08 | | | | | | | |
| pt09 | | | | | | | |
| pt10 | | | | | | | |

## Provisional synthetic run (2026-10-26)

**This is not the spike.** It used macOS text-to-speech, not people, with no new download: it only shows that the two models, the grammar, the merge and the parser work together, and where they are likely to be weak.

### Method

- **Speech:** the 20 sentences above, spoken by the macOS voices Alice (`it_IT`) and Joana (`pt_PT`), and for reference by Luciana (`pt_BR`); `say` to AIFF, `afconvert` to 16 kHz mono PCM16 WAV, 0.8 s of silence added at the end. Clean, evenly paced, no noise.
- **Vosk:** the `libvosk.so` of `vosk-android` 0.3.75 (the version the app ships, arm64) on the project's Android emulator (`lukitas-api36`, run headless), with the two official models exactly as downloaded (SHA-256 checked). A small C runner called `vosk_recognizer_new` (free pass) and `vosk_recognizer_new_grm` with the app's grammar JSON (grammar pass), both with word timestamps, in 100 ms chunks, collecting every `result` and the final one.
- **Merge and parse:** the app's own `mergePasses` and `parseSentence` (Dart, on the Mac), EUR, today 2026-10-26.
- **Scoring:** as above. The typed sentences give 10 of 10 in both languages.
- **Caveat:** text-to-speech is not a person. It has no accent variation, no hesitation, and it runs words together in places ("e venti" became "eventi"). Do not read these numbers as the bar.

### Result (amounts right, of 10 sentences)

| Voice | Free pass alone | Grammar pass alone | Merged (what the app does) | Merged: kinds / dates / names (of 12 movements) |
|---|---|---|---|---|
| Italian, Alice | 8 | 4 | **8** (6 before the gate) | 10 / 9 / 8 |
| Portuguese, Joana (pt-PT) | 6 | 5 | **7** | 9 / 9 / 8 |
| Portuguese, Luciana (pt-BR, reference) | 8 | 6 | **8** | 10 / 9 / 7 |
| Typed sentences, both languages | | | 10 | 12 / 12 / 12 |

### What it shows

- **European Portuguese is the weaker accent**, as the spec feared: the pt-PT voice gets 7 merged against 8 for the pt-BR voice, and its free pass gets 6 against 8. The grammar pass gains Joana one sentence net (the merge fixes pt05 "mil e duzentos" and pt10, and loses pt09, where a stray "quinhentas" replaced "cliente"), so the two-pass design is not hurting Portuguese here. This agrees with the beta label.
- **Italian: the merge first made it worse** (free pass 8, merged 6), for two reasons:
  - **False number words from the grammar pass.** Rule v2 lets any grammar number word win over whatever the free pass heard. With about 1 000 number words in the Italian grammar, the grammar pass put one over a name: "benzina" became "ventinove" (it06), "l'affitto" became "otto" (it03). These had low confidence (0.55, 0.54).
  - **A lost joiner:** the grammar pass dropped the "e" in "otto euro e venti" (it04), so the parser reads 8,00 and 20,00 instead of 8,20 (the free pass heard "eventi"). Still a miss.
- **Fix round 1: an Italian-only confidence gate** in \`mergePasses\`: a grammar number word with \`conf\` under 0.7 does not replace a free word that is not grammar vocabulary (it may still replace a number word, so "due" becomes "duemila" at conf 0.58). \`HeardWord\` gained \`conf\`. Spanish, English and Portuguese cannot change (tested). Re-run on the same saved outputs: **Italian 8 of 10 merged** (it03 and it06 recovered; it04 and it07 still miss, the latter "centoventi" heard as "trecentoventi", a number over a number), Portuguese unchanged at 7 and 8. The threshold was set after seeing three false words on one synthetic voice, so it must be re-checked on the recorded run.
- **A narrower Italian grammar is not the cure:** with only the numbers up to 99, the bare hundreds and "mila" (141 words), the merged result was 5 of 10 (before the gate). The compounds are needed.
- **Left open, for after the recorded run:** letting the parser read "euro venti" as cents (it changes shared behaviour).
- **Beta:** 8 of 10 is exactly the bar, on clean synthetic speech, so Italian voice is labelled beta like Portuguese until the recorded run clears 80%.

### Merged transcripts

#### Italian, macOS voice Alice (it-IT), with the confidence gate

| # | Free pass | Grammar pass | Merged (what the parser reads) | Amounts right: free / grammar / merged |
|---|---|---|---|---|
| 1 | ho speso quindici euro per il pranzo | speso quindici euro | speso quindici euro per il pranzo | yes / yes / yes |
| 2 | ho speso quindici euro e cinquanta per il caffè | speso quindici euro cinquanta | speso quindici euro e cinquanta per il caffè | yes / no / yes |
| 3 | l'aereo pagato l'affitto ottocento euro | dollari pagato otto ottocento euro | l'aereo pagato l'affitto ottocento euro | yes / no / yes |
| 4 | ho comprato pane e latte per otto euro eventi | comprato otto euro venti | comprato pane e latte per otto euro venti | no / no / no |
| 5 | mi hanno pagato milleduecento euro | mi hanno pagato mille duecento euro | mi hanno pagato mille duecento euro | yes / yes / yes |
| 6 | benzina quaranta euro e farmacie dodici euro | ventinove quaranta euro dodici euro | benzina quaranta euro e farmacie dodici euro | yes / no / yes |
| 7 | palestra centoventi euro lunedì | trecentoventi euro lunedì | palestra trecentoventi euro lunedì | yes / no / no |
| 8 | ho speso due cinquecento euro per le vacanze | speso duemila cinquecento euro | speso duemila cinquecento euro per le vacanze | no / yes / yes |
| 9 | oggi ho ricevuto trecentocinquanta euro di stipendio | oggi ricevuto trecentocinquanta euro | oggi ho ricevuto trecentocinquanta euro di stipendio | yes / yes / yes |
| 10 | ho speso dodici euro in taxi e trentacinque euro al supermercato | speso dodici euro trentacinque euro | speso dodici euro in taxi e trentacinque euro al supermercato | yes / no / yes |

#### Portuguese, macOS voice Joana (pt-PT)

| # | Free pass | Grammar pass | Merged (what the parser reads) | Amounts right: free / grammar / merged |
|---|---|---|---|---|
| 1 | quinze euros no almoço | gastei quinze euros | gastei quinze euros no almoço | yes / yes / yes |
| 2 | quinze e cinquenta no café | gastei quinze euros cinquenta | gastei quinze euros cinquenta no café | no / no / no |
| 3 | ontem venda oitocentos e | ontem paguei oitocentos euros | ontem paguei venda oitocentos euros | yes / yes / yes |
| 4 | leite por | comprei oito euros vinte | comprei leite por oito euros vinte | no / no / no |
| 5 | mil duzentos e um | recebi mil duzentos euros | recebi mil duzentos euros | no / yes / yes |
| 6 | gasolina quarenta euros e farmácia doze heróis | quarenta euros feira doze euros | gasolina quarenta euros e farmácia doze euros | yes / yes / yes |
| 7 | ginásio cento e vinte e na segunda | cento vinte euros segunda | ginásio cento e vinte euros na segunda | yes / no / yes |
| 8 | em dois mil e quinhentos euros nas férias | gastei dois mil quinhentos euros | em dois mil e quinhentos euros nas férias | yes / yes / yes |
| 9 | recebi trezentos e cinquenta euros do cliente | recebi trezentos cinquenta euros quinhentas | recebi trezentos e cinquenta euros do quinhentas | yes / no / no |
| 10 | em táxi e trinta e cinco euros no supermercado | gastei doze euros trinta cinco euros | gastei doze euros em táxi e trinta e cinco euros no supermercado | no / no / yes |

#### Portuguese, macOS voice Luciana (pt-BR), reference only

| # | Free pass | Grammar pass | Merged (what the parser reads) | Amounts right: free / grammar / merged |
|---|---|---|---|---|
| 1 | quinze euros no almoço | gastei quinze euros | gastei quinze euros no almoço | yes / yes / yes |
| 2 | quinze euros e cinquenta no café | gastei quinze euros e cinquenta | gastei quinze euros e cinquenta no café | yes / yes / yes |
| 3 | linda oitocentos euros | paguei oitocentos euros | paguei linda oitocentos euros | yes / yes / yes |
| 4 | pelo leite por oito euros e vinte | oito euros vinte | pelo leite por oito euros e vinte | yes / no / yes |
| 5 | recebi mil e duzentos euros | recebi mil duzentos euros | recebi mil e duzentos euros | yes / yes / yes |
| 6 | gasolina quarenta euros e farmácia dois euros | quarenta euros [unk] doze euros | gasolina quarenta euros e farmácia doze euros | no / yes / yes |
| 7 | ginásio cento e vinte euros na segunda | cento vinte euros segunda | ginásio cento e vinte euros na segunda | yes / no / yes |
| 8 | gastei dois mil e quinhentos euros nas férias | gastei vinte mil quinhentos euros | gastei vinte mil e quinhentos euros nas férias | yes / no / no |
| 9 | hoje recebi trezentos e cinquenta euros do cliente | hoje recebi trezentos e cinquenta euros | hoje recebi trezentos e cinquenta euros do cliente | yes / yes / yes |
| 10 | gastei dois euros e táxi trinta e cinco euros no supermercado | gastei doze euros e trinta cinco euros [unk] | gastei doze euros e táxi trinta cinco euros no supermercado | no / no / no |

## Notes

- No audio from people was recorded, and none was downloaded. The only downloads were the two model zips, approved by the founder.
- The synthetic audio, the runner, the emulator pushes and the scoring script are in the session scratchpad, not in the repo.
