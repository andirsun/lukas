/**
 * Synthesizes the feedback sounds (app/feedback/sounds/*.mp3) from plain sine tones with ffmpeg,
 * so they are original work with no third-party samples. Run: `pnpm --filter @lukas/web sounds`.
 * Needs ffmpeg with libmp3lame on the PATH. Each sound is a few short notes: [frequency Hz, seconds].
 */
import { execFileSync } from "node:child_process";
import { mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";

type Note = readonly [hz: number, seconds: number];

export const SOUNDS: Record<string, readonly Note[]> = {
  tap: [[1200, 0.04]],
  "expense-saved": [
    [660, 0.07],
    [880, 0.13],
  ],
  "income-saved": [
    [523, 0.07],
    [659, 0.07],
    [784, 0.16],
  ],
  paid: [
    [523, 0.07],
    [659, 0.07],
    [784, 0.07],
    [1047, 0.22],
  ],
  "near-limit": [
    [520, 0.11],
    [440, 0.14],
  ],
  "over-budget": [
    [330, 0.13],
    [247, 0.24],
  ],
  undo: [
    [700, 0.06],
    [500, 0.1],
  ],
};

const SAMPLE_RATE = 22050;
const FADE = 0.012;

/** ffmpeg arguments for one sound: each note a sine with a short fade in and out, then joined. */
export function ffmpegArgs(notes: readonly Note[], output: string): string[] {
  const inputs = notes.flatMap(([hz, seconds]) => [
    "-f",
    "lavfi",
    "-i",
    `sine=frequency=${hz}:duration=${seconds}:sample_rate=${SAMPLE_RATE}`,
  ]);
  const shaped = notes.map(
    ([, seconds], index) =>
      `[${index}:a]afade=t=in:d=${FADE},afade=t=out:st=${(seconds - FADE).toFixed(3)}:d=${FADE}[n${index}]`,
  );
  const joined = `${notes.map((_, index) => `[n${index}]`).join("")}concat=n=${notes.length}:v=0:a=1,volume=0.45[out]`;
  return [
    "-y",
    "-loglevel",
    "error",
    ...inputs,
    "-filter_complex",
    [...shaped, joined].join(";"),
    "-map",
    "[out]",
    "-ac",
    "1",
    "-c:a",
    "libmp3lame",
    "-b:a",
    "48k",
    "-map_metadata",
    "-1",
    output,
  ];
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const dir = fileURLToPath(new URL("../app/feedback/sounds/", import.meta.url));
  mkdirSync(dir, { recursive: true });
  for (const [name, notes] of Object.entries(SOUNDS)) {
    execFileSync("ffmpeg", ffmpegArgs(notes, `${dir}${name}.mp3`), { stdio: "inherit" });
    console.log(`wrote ${name}.mp3`);
  }
}
