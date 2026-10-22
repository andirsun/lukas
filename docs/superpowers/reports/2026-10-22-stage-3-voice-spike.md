# Stage 3 voice and model spike: results

**Date:** 2026-10-22.
**Spec:** §3 of `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md`. **Plan:** Task 1.

## Decision

*Updated after the vocabulary-biasing follow-up (last section). The first decision is kept below, struck through, for the record.*

**Engine:** Vosk small models (`vosk-model-small-es-0.42` and `vosk-model-small-en-us-0.15`), run as **two passes** on the same audio:
- a free pass;
- a grammar-biased pass, which knows only the amount, kind and date vocabulary plus `[unk]`.

The passes are merged by word timestamps (merge rule v2).
- **This is provisional** until the phone confirms it. It was measured on the Mac with Vosk 0.3.44, while the phone has 0.3.75.
  - The Mac's free pass reproduces the phone's 17/20, with the same three misses and the same latency.
- **If the phone run falls below 18/20**, the earlier fallback applies:
  - the Qwen2.5-1.5B hybrid, if the founder accepts its size;
  - otherwise, the platform `SpeechRecognizer`.
- Whisper does not qualify in any combination.

**Parsing:** rules only.
- On biased Vosk, the rules get amounts right in **19/20** sentences, with an estimated median of about 11 ms from end of speech to drafts.
- On typed text, they get 20/20.
- That meets the spec's "rules only" bar, so there is no model download.
- The Qwen2.5-1.5B hybrid stays only as the fallback in case the phone doesn't confirm.

**What the founder decides:** nothing for now; the 1.1 GB model is no longer needed. That changes only if the phone run misses the bar.

**Pending on the phone:** `bench/run_bias.sh` (see "Pending" below, about 2 minutes) confirms the two-pass Vosk on the phone. The LLM measurements are now optional.

<details><summary>First decision (before the follow-up), superseded</summary>

~~**Engine:** Vosk small, provisional. It qualified only with the rules + Qwen2.5-1.5B hybrid (18/20, measured on the Mac). If the founder declined that model, the engine would be the platform `SpeechRecognizer`.~~
~~**Parsing:** the hybrid: rules first, then Qwen2.5-1.5B (Q4_K_M, GBNF) for unread fragments, as an opt-in download (1.1 GB, about 2.2 GB peak memory, about 1.3 s per call). Rules only and the 0.5B hybrid stopped at 17/20 with single-pass Vosk. Model-only parsing reached at most 16/20.~~
</details>

## How it was measured

- **Device:** the founder's Samsung Galaxy S25 Ultra (SM-S938B), Android 17 / API 37, arm64-v8a, Snapdragon 8 Elite (8 cores).
  - The phone was fast-charging during the runs. The battery read 32 °C at the start and 42–43 °C during the parser runs, so expect some thermal throttling: the latencies are, if anything, pessimistic for this phone.
- **App:** a throwaway Flutter 3.47.7 app, built release AOT for arm64, outside the repo. It stays on the phone and in `~/lukitas-spike` only until the pending phone run, and is deleted after it.
  - Recording used Android `AudioRecord` (`VOICE_RECOGNITION`, 16 kHz mono PCM16) through a MethodChannel.
  - Vosk ran through `com.alphacephei:vosk-android:0.3.75`, which uses JNA.
  - whisper.cpp `v1.9.5` and llama.cpp `v0.7.0` were built with NDK r28c into two JNI libraries.
    - Both are CPU only, with no OpenMP, `-march=armv8.2-a+dotprod+fp16` (a generic target, not tuned to this chip), and ggml symbols hidden per library.
- **Offline:** the APK declares no `INTERNET` permission (`aapt dump permissions` shows only `RECORD_AUDIO`), so no engine could reach the network.
  - Airplane mode was **not** toggled, because adb ran over Wi-Fi.
- **Isolation:** each engine or parser configuration ran in a fresh app process (force-stop, then `am start` with intent extras).
  - The phone was woken first, and the activity shows over the lock screen. Without that, the dozing phone froze the app.
- **Speech:** the founder's 20 recordings were fed from the WAV files, not live.
  - Spanish sentences went to the es model or `language=es`; s10 and s11 went to en.
  - **Vosk latency** is "end of speech → final result". The file is fed in 100 ms chunks as fast as possible, and the timer runs from the last chunk to `finalResult()`. This is valid because Vosk runs at 0.05× real time (worst 0.14×), so in live use it keeps up while the person speaks.
  - **Whisper latency** is the full `whisper_full()` time: it isn't streaming.
- **Parsers:** they ran on the phone over five transcript sets:
  - typed reference text;
  - Vosk;
  - Whisper base (default window);
  - Whisper base (cut window);
  - Whisper tiny.

  The LLMs use greedy decoding with the GBNF grammar. A fixed system prompt and 4 few-shot examples are cached in the KV cache, and none of the examples is a test sentence.
- **4-thread mid-range proxy:**
  - Whisper and llama were run at 8 and at 4 threads.
  - Vosk is single-threaded, so the proxy doesn't apply to it. Its 20× real-time headroom is the relevant margin.
- **Memory:** the process `VmHWM` (peak RSS) after the run minus `VmRSS` before loading the model. The Flutter baseline is about 135–160 MB.
- **Rules prototype:** written to §5.2 and **frozen before any transcript was seen**. It gets 20/20 on the typed sentences. No rule was tuned to the speech output.
- **Scoring:**
  - A sentence's "amounts right" means every expected movement has the exact amount and currency, with no extra movement.
  - Names compare case- and accent-insensitively, ignoring a leading article. Expected "—" accepts any name.
  - WER is shown two ways:
    - raw;
    - "canonical", where every amount span in both texts becomes one value token. Whisper writes digits, so raw WER punishes it for "15.000" versus "quince mil".

### What was cut short (the founder had to leave with the phone)

- Measured on the phone:
  - all speech runs;
  - the rules parser;
  - Qwen2.5-0.5B at 8 and 4 threads;
  - one early Qwen2.5-1.5B run at 8 threads on the typed set only, with the final decoding code.
- **Not measured on the phone:**
  - the 1.5B at 4 threads;
  - the 1.5B over the speech sets;
  - both hybrids.
- **How their accuracy was measured instead:** on the Mac, with a CPU-only build of the same llama.cpp tag. It uses the identical generation loop (prefix reuse plus grammar check), the same models, grammar, prompts and hybrid logic.
  - **Caveat: greedy decoding is not bit-exact across thread layouts.**
    - The phone's own 0.5B outputs match between 8 and 4 threads in only 84/100 cases.
    - The Mac matches the phone in 85/100.
  - So the Mac accuracies are a proxy with about ±1 sentence of noise per set.
  - On scores, the Mac 0.5B gives 5/4/7/8/6 sentences right per set, against the phone's 3/3/8/8/7.
- Whisper small (`ggml-small-q5_1`, 190 MB, MIT) was downloaded but **not run**. Base already misses the latency bar at 4 threads (1.2 s median), and small is about 3× the compute of base, so it cannot qualify.
- The platform `SpeechRecognizer` was not measured. It is the spec's fallback, not a candidate.

## Licences (checked before download)

| Component | Licence | Source checked |
|---|---|---|
| Vosk API / `vosk-android` 0.3.75 | Apache-2.0 | https://github.com/alphacep/vosk-api (COPYING); Maven POM |
| JNA 5.18.1 (Vosk dependency) | Apache-2.0 / LGPL-2.1 (dual) | Maven Central |
| `vosk-model-small-es-0.42` | Apache-2.0 | https://alphacephei.com/vosk/models |
| `vosk-model-small-en-us-0.15` | Apache-2.0 | https://alphacephei.com/vosk/models |
| whisper.cpp v1.9.5 | MIT | https://github.com/ggml-org/whisper.cpp/blob/master/LICENSE |
| Whisper weights `ggml-tiny`, `ggml-base` (+ q5_1), `ggml-small-q5_1` | MIT | https://huggingface.co/ggerganov/whisper.cpp (card: `license: mit`); https://github.com/openai/whisper/blob/main/LICENSE |
| llama.cpp v0.7.0 | MIT | https://github.com/ggml-org/llama.cpp/blob/master/LICENSE |
| Qwen2.5-0.5B-Instruct-GGUF (`q4_k_m`) | Apache-2.0 | https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF (card + LICENSE file) |
| Qwen2.5-1.5B-Instruct-GGUF (`q4_k_m`) | Apache-2.0 | https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF (card + LICENSE file) |

Gemma and Gemini were not considered. Qwen2.5-3B was not used, because its licence is not Apache-2.0.

## Expected drafts

These were written before measuring; Phase A of the task.
- Amounts are in cents. The currency is COP unless noted.
- The day is an offset from Thursday 2026-10-22.
- There are 25 movements in 20 sentences.

| # | Sentence | Expected |
|---|---|---|
| s01 | gasté quince mil en el almuerzo | expense 1 500 000, 0, almuerzo |
| s02 | gasté 15 mil en almuerzo y 3 lukas en uber | 1 500 000 almuerzo · 300 000 uber |
| s03 | pagué el arriendo, un millón ochocientos mil | 180 000 000 arriendo |
| s04 | ayer compré pan y leche por ocho mil quinientos | 850 000, −1, pan y leche |
| s05 | me pagaron cuatro coma tres palos | income 430 000 000, — |
| s06 | rappi veintidós mil novecientos | 2 290 000 rappi |
| s07 | medio palo en el éxito | 50 000 000 éxito |
| s08 | antier gasté doce mil en taxi y cuarenta mil en mercado | 1 200 000 taxi · 4 000 000 mercado, both −2 |
| s09 | nueve euros con cincuenta en café | 950 EUR café |
| s10 | spent twelve dollars on lunch and three on coffee | 1 200 USD lunch · 300 USD coffee |
| s11 | got paid two thousand | income 200 000 USD, — |
| s12 | una luca de chicle | 100 000 chicle |
| s13 | gimnasio ciento veinte mil el lunes | 12 000 000, −3, gimnasio |
| s14 | gasté 45.500 en farmacia | 4 550 000 farmacia |
| s15 | doscientos mil de gasolina y ochenta mil de peajes | 20 000 000 gasolina · 8 000 000 peajes |
| s16 | (noise) almuerzo dieciocho mil | 1 800 000 almuerzo |
| s17 | (noise) uber siete mil quinientos y café cinco mil | 750 000 uber · 500 000 café |
| s18 | pagué el internet noventa y nueve mil novecientos | 9 990 000 internet |
| s19 | me llegó la prima, dos millones | income 200 000 000 prima |
| s20 | spotify dieciséis mil novecientos | 1 690 000 spotify |

## Speech engines (on the phone)

- "Amounts right" uses the frozen rules parser.
- Latency is end of speech to transcript; the rules add about 0.01 ms.
- "a0" is Whisper's default 30 s window; "a1" cuts the window to the clip plus 1 s.

| Engine | Threads | Amounts right | WER raw | WER canonical | Median ms | p90 ms | Max ms | Load ms | Peak Δ MB |
|---|---|---|---|---|---|---|---|---|---|
| **Vosk es + en** | 1 | **17/20** (es 16/18, en 1/2) | es 24.1%, en 38.5% | es 25.9%, en 45.5% | **8** | 16 | 32 | 306 / 413 | 185 / 208 |
| Whisper base | 8 | 15/20 | 59.7% | 39.1% | 817 | 990 | 1617 | 776 | 332 |
| Whisper base | 4 | 15/20 | 58.9% | 38.0% | 1207 | 1357 | 1490 | 274 | 328 |
| Whisper base a1 | 8 | 16/20 | 58.1% | 37.0% | 395 | 12 511 | 21 163 | 295 | 298 |
| Whisper base a1 | 4 | 16/20 | 58.1% | 37.0% | 169 | 2496 | 5866 | 209 | 298 |
| Whisper base q5_1 | 8 | 13/20 | 58.9% | 38.0% | 1342 | 1574 | 1760 | 353 | 240 |
| Whisper base q5_1 | 4 | 13/20 | 58.9% | 38.0% | 1188 | 1966 | 2458 | 150 | 239 |
| Whisper tiny | 8 | 13/20 | 62.8% | 56.5% | 289 | 453 | 656 | 144 | 230 |
| Whisper tiny | 4 | 12/20 | 63.6% | 59.8% | 418 | 484 | 909 | 150 | 231 |
| Whisper tiny q5_1 | 8 | 12/20 | 65.9% | 56.5% | 574 | 665 | 1069 | 204 | 184 |
| Whisper tiny a1 | 8 / 4 | 5/20 | 92.2% | 95.7% | 534 / 134 | 8850 / 1502 | 12 265 / 2367 | 125 | 200 |

- **Cutting the window (a1)** makes Whisper fast on most clips, but it loops on others (tails of 6–21 s). It isn't usable.
- **Vosk misses (rules):**
  - s07: "medio palo" was heard as "me de ópalo";
  - s08: "doce" was heard as "de";
  - s10: "three" was heard as "tree".
- **Vosk also loses** "uber" in s02 (heard as "de nuevo") and "café" in s17, and mishears some verbs ("este" for "gasté", "me pagar un"). That's why its name and kind scores are lower than its amounts.

### Transcripts (Vosk; Whisper base t8)

| # | Vosk | Whisper base |
|---|---|---|
| s01 | gaste quince mil en el almuerzo | en gas tecines y en villanero al modo |
| s02 | este quince mil en el almuerzo y tres lucas de nuevo | Gas te 15 mil en el almuerzo y 3 luques en un ver |
| s03 | para que la riendo un millón ochocientos mil | Pa que él arriendo 1,800,000 |
| s04 | ayer compré pan y leche por ocho mil quinientos | Ayer compré pan y leche por 8.500 |
| s05 | me pagar un cuatro coma tres palos | Me pagaron 4,3 palos |
| s06 | rapid veintidós mil novecientos | RAPI 22900 |
| s07 | me de ópalo en el éxito | Medio Palo en el éxito |
| s08 | antier gastos de mil en taxi cuarenta mil el mercado | Antiergas T12000Taxi 40.000M |
| s09 | nueve euros con cincuenta en café | 9 euros con 50 en café |
| s10 | a spend twelve dollars so learnt lunch and tree on coffee | Spend $12 on lunch and 3 on coffee. |
| s11 | got paid two thousand | God paid 2000. |
| s12 | una luca de chicle | una loca chicle |
| s13 | gimnasio ciento veinte mil el lunes | gimnasio 120 000 lunes |
| s14 | las cuarenta y cinco mil quinientos en farmacia | hasta 45.500 informacia |
| s15 | doscientos mil de gasolina y ochenta mil de peajes | 200 mil de gasolina y 80 mil de pedajes. |
| s16 | almuerzo dieciocho mil | almuerzo 18000 |
| s17 | uber siete mil quinientos y cinco mil | UR7500 y café 5 mil |
| s18 | pague el internet noventa y nueve mil novecientos | Paga el internet 99.900 |
| s19 | me llegó la prima dos millones | Me llegó la prima 2 millones |
| s20 | spotify dieciseis mil novecientos | Spotify 16900 |

## Parsers × speech

- Sentences with amounts right are out of 20; movements are out of 25.
- **Device** means measured on the phone. **Mac** means accuracy from the Mac twin (see the caveat above).

| Parser | Where | Typed | Vosk | Whisper base | Whisper base a1 | Whisper tiny |
|---|---|---|---|---|---|---|
| Rules | device | **20/20** (25/25 amounts, kinds, dates, names) | **17/20** (amounts 22, kinds 22, dates 23, names 15 /25) | 15/20 | 16/20 | 13/20 |
| Hybrid rules + Qwen2.5-0.5B | Mac | 20/20 | 17/20 | 16/20 | 17/20 | 13/20 |
| **Hybrid rules + Qwen2.5-1.5B** | Mac | 20/20 | **18/20** (amounts 23, kinds 22, dates 24, names 16 /25) | 17/20 | 17/20 | 13/20 |
| Qwen2.5-0.5B only, 8 threads | device | 3/20 | 3/20 | 8/20 | 8/20 | 7/20 |
| Qwen2.5-0.5B only, 4 threads | device | 4/20 | 3/20 | 9/20 | 9/20 | 6/20 |
| Qwen2.5-1.5B only, 8 threads | device (typed) / Mac | 12/20 | 10/20 | 16/20 | 12/20 | 11/20 |
| Qwen2.5-1.5B only, 4 threads | Mac | 12/20 | 10/20 | 16/20 | 12/20 | 11/20 |

- The **0.5B alone** confuses scales ("quince mil" becomes 1 500), splits "pan y leche" into two movements, and invents dates.
- The **1.5B alone** is better at names, but still gets amounts wrong:
  - "un millón ochocientos mil" becomes 10 800 000;
  - "dieciocho mil" becomes 180 000;
  - "two thousand" becomes COP.
- **What the hybrid's model calls actually did with Vosk:** the rules leave exactly one Vosk fragment unread, s07 "me de ópalo en el éxito".
  - The 1.5B reads it as 500 000 (amount right, kind wrong: income). That is the 18th sentence.
  - The 0.5B reads it as 1 000.
  - The model is called on 1 of 20 Vosk sentences, and on 1–4 of 20 Whisper sentences.
  - **This 18/20 rests on a single sentence, at the threshold, measured off-device.** Treat it as fragile.

### Parser latency on the phone, per model call

| Model | Threads | Median ms | p90 ms | Max ms | Tokens/s (generation, median) | Load ms | Prompt prefix (572 tok, once) |
|---|---|---|---|---|---|---|---|
| Rules | — | 0.01 | 0.02 | 0.48 | — | — | — |
| Qwen2.5-0.5B | 8 | 1278 | 2361 | 4193 | 28 | 899 | 3.4 s |
| Qwen2.5-0.5B | 4 | 713 | 1273 | 1654 | 43 | 765 | 4.1 s |
| Qwen2.5-1.5B | 8 | 1342 (typed set, 20 calls) | 3072 | 3682 | 24 | 3545 | 4.2 s |
| Qwen2.5-1.5B | 4 | **pending** | | | | | |

- **Threads:** 8 threads was slower than 4 for the 0.5B on this phone, which points to oversubscription or throttling. The app should use at most 4 threads.
- **Generation:** a typical draft is 25–60 grammar-constrained tokens.
- **Prompt prefix:** the app should evaluate the prompt prefix once, when the voice sheet opens (3–4 s), and not per sentence.

## End to end (end of speech → drafts) and the bar

| Combination | Amounts right | Median ms | p90 ms | Meets the bar (≥ 18/20, median ≤ 1000 ms)? |
|---|---|---|---|---|
| Vosk + rules | 17/20 | 8 | 16 | No: amounts |
| Vosk + hybrid 0.5B | 17/20 (Mac) | 8 | 16 (+ ~0.7–1.3 s on the 1 sentence that calls the model) | No: amounts |
| **Vosk + hybrid 1.5B** | **18/20 (Mac)** | **8** | 16 (+ ~1.3 s, up to 3.7 s, on the 1 sentence that calls the model) | **Yes, provisionally:** accuracy is off-device; the founder must accept the model |
| Whisper base + rules, 8 / 4 threads | 15/20 | 817 / 1207 | 990 / 1357 | No: amounts; at 4 threads also latency |
| Whisper base + hybrid 1.5B | 17/20 (Mac) | ≥ 817 | — | No |
| Whisper tiny + any | ≤ 13/20 | 289 | 453 | No |

- **The speech bar doesn't hinge on the 1.5B's phone latency.** The model runs on only 1 of 20 Vosk sentences, so the median stays about 8 ms at any thread count. What remains is whether that one slow sentence (1–4 s) is acceptable.
- **The decision does hinge on:**
  1. the founder accepting the 1.5B model;
  2. the phone confirming that s07 is recovered.

## Size and memory

| Component | Download | On disk | Native library in the APK (arm64) | Peak Δ RSS |
|---|---|---|---|---|
| Vosk es small | 39.8 MB zip | 58 MB | libvosk 10.0 MB + JNA 0.17 MB | 185 MB |
| Vosk en small | 41.2 MB zip | 68 MB | (same) | 208 MB |
| Whisper tiny / tiny q5_1 | 77.7 / 32.2 MB | same | 1.7 MB | 230 / 184 MB |
| Whisper base / base q5_1 | 148 / 59.7 MB | same | (same) | 332 / 240 MB |
| Qwen2.5-0.5B Q4_K_M | 491 MB | same | 4.6 MB | about 765 MB (VmHWM 917 MB) |
| Qwen2.5-1.5B Q4_K_M | 1117 MB | same | (same) | about 2065 MB (VmHWM 2224 MB) |

- Vosk ships one model per language, downloaded on demand, so a person who uses only Spanish needs about 40 MB.
- Including Vosk adds about 10 MB per ABI to the APK. The `vosk-android` AAR ships armeabi-v7a, arm64-v8a and x86_64.

## Pending (when the phone is back)

- **Setup:** the spike app and its models are still installed on the phone, and `~/lukitas-spike` is kept for this.
- **What's needed:** the phone unlocked once, awake and connected over Wi-Fi adb (`192.168.1.47:33293`).

**1. Confirm the decision (about 2 minutes).** This installs the updated spike APK, which adds the grammar pass and word timestamps. It then runs the free and grammar passes for es and en, merges them, and scores them:

```sh
~/lukitas-spike/bench/run_bias.sh
```

- **It confirms the decision** if the `merge v2` row shows at least 18/20, and the free and grammar `finalMs` in `bench/results/speech-vosk-*.json` keep the median end to end under 1000 ms.
- **If it doesn't:** go to step 2, and the fallback in "Decision" applies.

**2. Optional, needed only if step 1 misses the bar:** the LLM latency and the hybrids on the phone.

```sh
cd ~/lukitas-spike
Q15=qwen2.5-1.5b-instruct-q4_k_m.gguf; Q05=qwen2.5-0.5b-instruct-q4_k_m.gguf
bench/run_parse.sh ref,vosk \
  parse-llm15-t8:llm:$Q15:8 parse-llm15-t4:llm:$Q15:4 \
  parse-hyb15-t4:hybrid:$Q15:4 parse-hyb05-t4:hybrid:$Q05:4
~/development/flutter/bin/dart run tool/score.dart parse bench/results
```

**3. Clean up:**

```sh
~/Library/Android/sdk/platform-tools/adb -s 192.168.1.47:33293 shell rm -f /data/local/tmp/transcripts.json
~/Library/Android/sdk/platform-tools/adb -s 192.168.1.47:33293 uninstall dev.lukitas.spike.lukitas_spike
rm -r ~/lukitas-spike
```

## Notes for Tasks 8 and 12

- **Task 8 (rules):** these gaps showed up in speech output. They were deliberately not fixed in the frozen prototype.
  - Whisper's comma-grouped "1,800,000" in Spanish;
  - glued tokens ("T12000Taxi", "UR7500");
  - "spend" (Vosk's form of "spent");
  - names that swallow unread words ("so learnt lunch and tree on coffee").
- **Task 8 (hybrid trigger):** the hybrid only calls the model when the rules leave a fragment. A sentence the rules read wrongly but completely (Vosk s08: "doce" lost, so 1 000 is read as "mil") never reaches the model.
- **Task 12 (memory):** the 1.5B model peaks at about 2.2 GB RSS. It may not fit mid-range phones with 4–6 GB RAM, so the opt-in screen should say so.
- **Task 12 (speech):** with Vosk, stream audio into the recognizer while the person talks. Finalizing then takes about 10 ms.
- **Task 12 (packaging):** release builds need R8 keep rules for JNA and Vosk (`-keep class com.sun.jna.** { *; }`, `-keep class org.vosk.** { *; }`), or Vosk fails at load.
- **Sample size:** one speaker, one take per sentence. One sentence is 5 points, so the 17 versus 18 boundary is within noise.

## Follow-up: vocabulary biasing (Vosk grammar mode)

All three Vosk misses were mishearings:
- s07: "me de ópalo" for "medio palo";
- s08: "de" or "dos" for "doce";
- s10: "tree" for "three".

So the follow-up tried biasing Vosk toward the words the amounts need.

### Method

- **Where:** on the Mac (Apple M1 Pro), because the phone was away.
  - Same 20 WAVs and same two Vosk models.
  - Same 100 ms chunk feeding, then the same frozen rules parser and the same scorer.
- **Vosk build:** the Python package `vosk` 0.3.44 (Apache-2.0, https://github.com/alphacep/vosk-api). That is PyPI's newest macOS build; the phone has 0.3.75.
- **How the Mac compares with the phone:**
  - The Mac free pass scores the same as the phone (17/20, misses s07, s08, s10). Kinds and dates match too; names differ by one movement.
  - Its timing matches as well: finalize median 7.5 ms vs 8 ms, RTF 0.050 vs 0.05.
  - One transcript differs: s08 is "gaste dos mil" on the Mac and "gastos de mil" on the phone.
- **Pass 1 (free):** the normal recognizer, with `SetWords(true)` for word timestamps.
- **Pass 2 (grammar):** `KaldiRecognizer(model, 16000, <JSON word list>)` with `SetWords(true)`. The list holds only single words, which Vosk combines into any sequence (for example "noventa y nueve mil novecientos"):
  - **Spanish numbers:** cero…nueve, un/uno/una, diez…veintinueve (with veintiún/veintiuna), treinta…noventa, cien/ciento, doscientos…novecientos (both genders);
  - **multipliers and amount words:** mil, millón/millones, luca/lucas/luka/lukas, palo/palos, medio, coma, punto, con;
  - **currencies:** euro(s), dólar(es), peso(s);
  - **verbs:** gasté, pagué, compré, me, pagaron, recibí, llegó;
  - **dates:** hoy, ayer, antier, anteayer, lunes…domingo;
  - **separators:** y, también;
  - **English:** zero…nineteen, twenty…ninety, hundred, thousand, million, point; dollar(s), euro(s), pesos; spent, paid, got; today, yesterday, monday…sunday; and, also;
  - plus `[unk]`.

  All of these words are in both models' vocabularies.
- **Two traps found:**
  - The JSON must be passed as UTF-8. With `\u00e9` escapes, Vosk silently ignores every accented word: gasté, millón, veintidós, and so on.
  - The grammar pass hits an endpoint mid-sentence (18 of 20 clips). Its intermediate `Result()` must be collected, not only `FinalResult()`.

### Merge rules (word level, by timestamps)

- **Overlap:** a free word and a grammar word overlap when their time intersection covers at least 50% of either word. `[unk]` grammar words are ignored.
- **v1, written before seeing any merged output:**
  - Any grammar word wins over the free words it overlaps.
  - The only exception is a separator ("y", "and"…), which yields to an overlapping free word that is not in the grammar vocabulary.
  - Free words that overlap nothing are kept.
- **v2, the recommended rule:**
  - **Number words** (numbers, multipliers, medio, coma, punto, con) **from the grammar pass always win.**
  - **A grammar currency, kind, date or separator word** replaces an overlapping free word only if that free word is in the grammar vocabulary, or looks like the grammar word (normalized edit similarity ≥ 0.5, such as "este"/"gasté" or "pagar"/"pagaron"). Otherwise, the free word is kept as part of a name and the grammar word is dropped.
  - Free words that overlap nothing are kept.
- **Honesty note:** v2 was written **after** seeing v1's two name regressions on these 20 sentences: "almuerzo" became "peso", and "pan" became "pagué". v1 and v2 give **identical amounts, kinds and dates**, so the amounts decision doesn't depend on that tuning.
- The merged text is the kept words in time order. The rules parser reads it unchanged.

### Results (rules parser, same scorer, same bar)

| Vosk transcript | Sentences with amounts right | Amounts | Kinds | Dates | Names | WER (canonical) | Misses |
|---|---|---|---|---|---|---|---|
| Phase B phone, free pass (0.3.75) | 17/20 | 22/25 | 22/25 | 23/25 | 15/25 | 28.3% | s07, s08, s10 |
| Mac free pass (0.3.44) | 17/20 | 22/25 | 22/25 | 23/25 | 16/25 | 25.0% | s07, s08, s10 |
| Mac grammar pass alone | 15/20 | 16/25 | 20/25 | 20/25 | 2/25 | 63.0% | s02, s08, s10, s15, s17 |
| Mac merge v1 | **19/20** | 24/25 | 24/25 | 24/25 | 16/25 | 16.3% | s10 |
| **Mac merge v2** | **19/20** | **24/25** | **24/25** | **24/25** | **18/25** | 16.3% | s10 |

**The three misses:**
- **s07: fixed.** The grammar pass hears "medio palo", which gives 500 000, and the merge keeps "en el éxito" from the free pass. Amount, kind, date and name are all right now.
- **s08: fixed for amounts.** The grammar pass hears "gasté doce mil … cuarenta mil", so both amounts and kinds are right. The names are still wrong. Both passes drop the "y" between "taxi" and "cuarenta", so the rules attach "taxi" to the second movement.
- **s10: still a miss.** For "lunch and three on coffee", the English grammar pass returns `[unk] [unk] [unk]`, and the free pass still says "tree". Only "spend" becomes "spent".

**Other changes:**
- **Gains:**
  - s05's kind is now right ("me pagaron", so income).
  - s02's first name is now right ("almuerzo", where "este" used to leak into the name).
- **Regressions:**
  - **None in amounts, kinds or dates**: every sentence that passed before still passes.
  - **Names:** v1 loses s01 ("almuerzo" became "peso") and s04 ("pan y leche" became "leche"). v2 loses nothing.
- The grammar pass alone is not usable: names fall to 2/25. It is only useful merged.

### Cost of two passes

| Pass (Mac M1 Pro) | Finalize median ms | p90 ms | Max ms | Whole clip median ms | RTF median (max) |
|---|---|---|---|---|---|
| Free | 7.5 | 15.1 | 34.1 | 180 | 0.050 (0.179) |
| Grammar | 2.8 | 3.5 | 3.6 | 26 | 0.008 (0.009) |

- **CPU:** the grammar pass costs about 16% of the free pass, so two passes use about 1.16× the CPU (RTF about 0.06).
- **Estimate for the phone,** from the measured 8 ms median and 16 ms p90 for the free pass, since Mac and phone timings matched for Vosk:
  - Run one after the other at end of speech, finalizing takes about 11 ms median and about 20 ms p90.
  - Run in parallel, it takes about 8 ms, because each recognizer is single-threaded and two threads are enough.
  - The 8- and 4-thread settings don't apply: Vosk uses one thread per recognizer, so the 4-thread proxy is unaffected.
  - The parse adds 0.01 ms.
  - The median end to end stays around 10 ms, far under 1000 ms.
- **Memory:** both recognizers share one `Model`. The grammar recognizer adds only its small grammar FST. This wasn't measured here; the phone run records VmHWM.
- **Mid-range phones:** an RTF of about 0.06 leaves roughly 16× headroom on this phone. A slower mid-range core should still keep up with live speech, but that is unmeasured.

### Caveats

- **Mac only:** Vosk 0.3.44 on the Mac versus 0.3.75 on the phone. The scores matched on the free pass, but one transcript differed, so the phone run (`bench/run_bias.sh`) must confirm the merged 19/20.
- **The margin is thin:** one speaker and one take per sentence, so 19/20 is one sentence above the bar.
- **Biasing can pull names toward number or verb words:** "almuerzo" became "peso", and "pan" became "pagué". v2 guards against that. Task 8's shared cases should include names that sound like amount words.

### Notes for Task 12

- **Run two recognizers** on one `Model` while the person speaks: free and grammar, both with `setWords(true)`.
- **Collect** every `getResult()` on endpoints, not only `getFinalResult()`.
- **Pass the grammar JSON** unescaped (UTF-8).
- **Merge with rule v2** before the rules parser.

