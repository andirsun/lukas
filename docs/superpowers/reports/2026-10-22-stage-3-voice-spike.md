# Stage 3 voice and model spike: results

**Date:** 2026-10-22.
**Spec:** §3 of `docs/superpowers/specs/2026-10-22-stage-3-mobile-design.md`. **Plan:** Task 1.

## Decision

**Engine:** Vosk small models (`vosk-model-small-es-0.42` and `vosk-model-small-en-us-0.15`).
- This is **provisional**. Vosk reaches the 18/20 amounts bar only together with the 1.5B hybrid parser below.
  - That result was measured on the Mac twin, not yet on the phone.
  - It also needs the founder to accept that model.
- If the founder declines the 1.5B model, or the phone run doesn't confirm 18/20, the spec's rule falls to the platform `SpeechRecognizer`. That fallback needs honest copy that audio may go to the phone's speech service.
- Whisper does not qualify in any combination.

**Parsing:** a hybrid. Rules run first. **Qwen2.5-1.5B-Instruct** (Q4_K_M, grammar-constrained JSON) only sees the fragments the rules can't read. It is an opt-in download.
- This is **subject to the founder accepting** its 1.1 GB download, about 2 GB of peak memory, and about 1.3 s (up to 3.7 s) per model call on this phone.
- **Why not the alternatives:**
  - Rules only stop at 17/20 with Vosk.
  - The 0.5B hybrid also stops at 17/20.
  - A model alone is ruled out: at most 16/20 on any transcript set, and 12/20 even on the typed sentences.
- **Typed input:** the rules alone get 20/20 on the typed sentences, so typing never needs the model.

**What the founder decides:**
1. Is a 1.1 GB opt-in model acceptable for recovering about 1 sentence in 20?
2. If not, the engine is the platform `SpeechRecognizer`, per the spec.

**Pending on the phone:** the 1.5B latency at 4 threads, and both hybrids run on the device. The command is in "Pending" below.

## How it was measured

- **Device:** the founder's Samsung Galaxy S25 Ultra (SM-S938B), Android 17 / API 37, arm64-v8a, Snapdragon 8 Elite (8 cores).
  - The phone was fast-charging during the runs. The battery read 32 °C at the start and 42–43 °C during the parser runs, so expect some thermal throttling: the latencies are, if anything, pessimistic for this phone.
- **App:** a throwaway Flutter 3.47.7 app, built release AOT for arm64. It lived outside the repo and has been deleted.
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

- **What's needed:** the on-device latency of the 1.5B at 8 and 4 threads, and both hybrids on the phone. The spike app and its models are still installed on the phone, and `~/lukitas-spike` is kept for this.
- **How long:** about 5 minutes, with the phone unlocked once, awake and connected over Wi-Fi adb (`192.168.1.47:33293`).

```sh
cd ~/lukitas-spike
Q15=qwen2.5-1.5b-instruct-q4_k_m.gguf; Q05=qwen2.5-0.5b-instruct-q4_k_m.gguf
bench/run_parse.sh ref,vosk \
  parse-llm15-t8:llm:$Q15:8 parse-llm15-t4:llm:$Q15:4 \
  parse-hyb15-t4:hybrid:$Q15:4 parse-hyb05-t4:hybrid:$Q05:4
~/development/flutter/bin/dart run tool/score.dart parse bench/results
```

**Then clean up:**

```sh
~/Library/Android/sdk/platform-tools/adb -s 192.168.1.47:33293 shell rm /data/local/tmp/transcripts.json
~/Library/Android/sdk/platform-tools/adb -s 192.168.1.47:33293 uninstall dev.lukitas.spike.lukitas_spike
rm -r ~/lukitas-spike
```

- **What confirms the decision:**
  1. `parse-hyb15-t4` shows `vosk 18/20`;
  2. the founder accepts the `parse-llm15-t4` median and p90.
- **What reverses it:** if s07 is not recovered on the phone, the engine becomes the platform `SpeechRecognizer`, per the spec.

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
