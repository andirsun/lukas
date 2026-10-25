# Feedback sounds

These are the web's feedback sounds, copied unchanged from
[`apps/web/app/feedback/sounds`](../../../web/app/feedback/sounds/README.md).

Every file is original work, made for Lukitas. There are no third-party samples, so there is
nothing to attribute and no license to carry: they are released under the repository's license
(AGPL-3.0).

Each sound is a few plain sine tones with a short fade in and out, joined and encoded as mono MP3
(22.05 kHz, 48 kbps) by [`apps/web/scripts/gen-feedback-sounds.ts`](../../../web/scripts/gen-feedback-sounds.ts),
which calls `ffmpeg` (with `libmp3lame`). To regenerate them: `pnpm --filter @lukas/web sounds`,
then copy the files here. The notes (frequency in Hz, length in seconds) are listed in that script.

| File                | Web event      | Plays in the app on       |
| ------------------- | -------------- | ------------------------- |
| `expense-saved.mp3` | `expenseSaved` | `saved` (an expense)      |
| `paid.mp3`          | `paid`         | `paid`                    |
| `undo.mp3`          | `undo`         | `undo`                    |
| `income-saved.mp3`  | `incomeSaved`  | `incomeSaved`             |
| `near-limit.mp3`    | `nearLimit`    | `nearLimit`               |
| `over-budget.mp3`   | `overBudget`   | `overBudget`              |
| `tap.mp3`           | `tap`          | (not used yet)            |

All are under 4 KB. `SoundChannel.kt` loads the ones in use into a `SoundPool` when the app starts.
A save picks its event from the month's figures once they are in, like the web's `feedbackForSave`:
income, near a limit, over a limit, or a plain expense. Gestures (a swipe line, a delete, a key) only vibrate, as on the web.
