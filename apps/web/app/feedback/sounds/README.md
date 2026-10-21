# Feedback sounds

Every file here is original work, made for Lukitas. There are no third-party samples, so there is
nothing to attribute and no license to carry: they are released under the repository's license.

Each sound is a few plain sine tones with a short fade in and out, joined and encoded as mono MP3
(22.05 kHz, 48 kbps) by [`scripts/gen-feedback-sounds.ts`](../../../scripts/gen-feedback-sounds.ts),
which calls `ffmpeg` (with `libmp3lame`). To regenerate them: `pnpm --filter @lukas/web sounds`.
The notes (frequency in Hz, length in seconds) are listed in that script.

| File               | Event                      | Notes                                   |
| ------------------ | -------------------------- | --------------------------------------- |
| `tap.mp3`          | `tap`                      | one 1200 Hz blip                        |
| `expense-saved.mp3`| `expenseSaved`             | two notes, rising                       |
| `income-saved.mp3` | `incomeSaved`              | C-E-G arpeggio, rising                  |
| `paid.mp3`         | `paid`                     | C-E-G-C arpeggio, the longest           |
| `near-limit.mp3`   | `nearLimit`                | two notes, a small step down            |
| `over-budget.mp3`  | `overBudget`               | two low notes, falling                  |
| `undo.mp3`         | `undo`                     | two notes, falling                      |

All are under 4 KB. They are not loaded with the page: `feedback()` creates each `Audio` element
the first time its event happens (always from a user gesture, so autoplay policies allow it).
