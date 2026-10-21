import expenseSavedUrl from "./sounds/expense-saved.mp3?no-inline";
import incomeSavedUrl from "./sounds/income-saved.mp3?no-inline";
import nearLimitUrl from "./sounds/near-limit.mp3?no-inline";
import overBudgetUrl from "./sounds/over-budget.mp3?no-inline";
import paidUrl from "./sounds/paid.mp3?no-inline";
import tapUrl from "./sounds/tap.mp3?no-inline";
import undoUrl from "./sounds/undo.mp3?no-inline";

/** What just happened, as the person feels it: a sound, a vibration, sometimes a celebration. */
export type FeedbackEvent =
  | "tap"
  | "expenseSaved"
  | "incomeSaved"
  | "paid"
  | "nearLimit"
  | "overBudget"
  | "undo";

/** The DOM event every `feedback()` call dispatches on `window`; `Celebration` listens to it. */
export const FEEDBACK_DOM_EVENT = "lukas:feedback";

export interface FeedbackDetail {
  event: FeedbackEvent;
}

/** `localStorage` key of the sound setting: the value `"off"` mutes sounds (vibration stays). */
export const SOUND_STORAGE_KEY = "lukas.sound";

const SAVED = [12, 40, 18];

/** Vibration patterns in ms (vibrate, pause, vibrate, ...). iOS Safari has no vibration at all. */
export const VIBRATION_PATTERNS: Record<FeedbackEvent, readonly number[]> = {
  tap: [8],
  expenseSaved: SAVED,
  incomeSaved: SAVED,
  paid: [10, 30, 10, 30, 24],
  nearLimit: [30],
  overBudget: [40, 60, 40],
  undo: [8],
};

/**
 * The sound files. The URLs are plain strings (`?no-inline` keeps Vite from embedding the tiny
 * files as data URIs in the JavaScript); nothing is fetched until an event first plays one.
 */
const SOUND_URLS: Record<FeedbackEvent, string> = {
  tap: tapUrl,
  expenseSaved: expenseSavedUrl,
  incomeSaved: incomeSavedUrl,
  paid: paidUrl,
  nearLimit: nearLimitUrl,
  overBudget: overBudgetUrl,
  undo: undoUrl,
};

const VOLUME = 0.6;

const sounds = new Map<FeedbackEvent, HTMLAudioElement>();

/** Forgets the loaded audio elements, so a test starts as a fresh page would. */
export function __resetFeedbackForTests(): void {
  sounds.clear();
}

function soundMuted(): boolean {
  try {
    return localStorage.getItem(SOUND_STORAGE_KEY) === "off";
  } catch {
    // Blocked or missing storage: sound stays on.
    return false;
  }
}

function playSound(event: FeedbackEvent): void {
  if (typeof Audio === "undefined" || soundMuted()) return;
  let audio = sounds.get(event);
  if (!audio) {
    audio = new Audio(SOUND_URLS[event]);
    audio.preload = "auto";
    audio.volume = VOLUME;
    sounds.set(event, audio);
  }
  audio.currentTime = 0;
  // play() rejects when the browser blocks it (no gesture yet, no audio device): not an error here.
  audio.play()?.catch(() => {});
}

function vibrate(event: FeedbackEvent): void {
  if (typeof navigator === "undefined" || typeof navigator.vibrate !== "function") return;
  navigator.vibrate([...VIBRATION_PATTERNS[event]]);
}

function announce(event: FeedbackEvent): void {
  if (typeof window === "undefined" || typeof CustomEvent === "undefined") return;
  window.dispatchEvent(new CustomEvent<FeedbackDetail>(FEEDBACK_DOM_EVENT, { detail: { event } }));
}

/**
 * Gives feedback for something that happened: plays its sound (unless muted), vibrates where the
 * platform allows, and tells `Celebration` through a `lukas:feedback` DOM event. Call it from a
 * user gesture. It never throws: a missing `Audio`, `navigator.vibrate` or storage, a blocked
 * `play()`, or no `window` (prerender) just skips that part.
 */
export function feedback(event: FeedbackEvent): void {
  for (const step of [playSound, vibrate, announce]) {
    try {
      step(event);
    } catch {
      // Feedback is a nicety: one part failing must not stop the others or the caller.
    }
  }
}
