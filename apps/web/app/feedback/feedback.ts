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
/** Elements whose silent unlock `play()` is still settling (see `unlockSounds`). */
const unlocking = new Set<HTMLAudioElement>();

/** Forgets the loaded audio elements, so a test starts as a fresh page would. */
export function __resetFeedbackForTests(): void {
  sounds.clear();
  unlocking.clear();
}

function soundMuted(): boolean {
  return !soundEnabled();
}

/** Whether sounds play (the settings switch). Blocked or missing storage: sound stays on. */
export function soundEnabled(): boolean {
  try {
    return localStorage.getItem(SOUND_STORAGE_KEY) !== "off";
  } catch {
    return true;
  }
}

/**
 * Turns sounds on or off on this device (vibration stays either way). With storage blocked the
 * choice is not kept, and sound stays on.
 */
export function setSoundEnabled(on: boolean): void {
  try {
    if (on) localStorage.removeItem(SOUND_STORAGE_KEY);
    else localStorage.setItem(SOUND_STORAGE_KEY, "off");
  } catch {
    // Not kept; see above.
  }
}

/** The event's audio element, created (and so fetched) the first time it is needed. */
function soundFor(event: FeedbackEvent): HTMLAudioElement {
  let audio = sounds.get(event);
  if (!audio) {
    audio = new Audio(SOUND_URLS[event]);
    audio.preload = "auto";
    audio.volume = VOLUME;
    sounds.set(event, audio);
  }
  return audio;
}

function playSound(event: FeedbackEvent): void {
  if (typeof Audio === "undefined" || soundMuted()) return;
  const audio = soundFor(event);
  // A real sound takes over from a silent unlock still settling on this element.
  if (unlocking.delete(audio)) audio.muted = false;
  audio.currentTime = 0;
  // play() rejects when the browser blocks it (no gesture yet, no audio device): not an error here.
  audio.play()?.catch(() => {});
}

/**
 * iOS Safari only lets an `Audio` element start playing if its first `play()` happens inside a
 * user gesture. Events that resolve later (a server answer, a limit crossed after a save) would
 * then be silent the first time. So, in a gesture, every sound element is created and played once
 * muted, then paused: from then on `play()` works at any time. Call it from a gesture handler.
 */
export function unlockSounds(): void {
  if (typeof Audio === "undefined") return;
  for (const event of Object.keys(SOUND_URLS) as FeedbackEvent[]) {
    try {
      const audio = soundFor(event);
      if (!audio.paused) continue; // Already playing for real.
      audio.muted = true;
      unlocking.add(audio);
      const settle = () => {
        // Gone from the set means a real sound took the element over: leave it playing.
        if (!unlocking.delete(audio)) return;
        audio.pause();
        audio.currentTime = 0;
        audio.muted = false;
      };
      Promise.resolve(audio.play()).then(settle, settle);
    } catch {
      // A browser that refuses even this: sounds just stay as they were.
    }
  }
}

/** Capture phase, so a handler that stops propagation cannot hide the gesture. */
const CAPTURE = { capture: true };

/**
 * Unlocks the sounds on the first `pointerdown` or `keydown` anywhere, then removes itself.
 * Nothing is loaded before that gesture. Returns a function that removes the listeners.
 */
export function installSoundUnlock(): () => void {
  if (typeof window === "undefined") return () => {};
  const gestures = ["pointerdown", "keydown"] as const;
  const remove = () => {
    for (const type of gestures) window.removeEventListener(type, onGesture, CAPTURE);
  };
  function onGesture() {
    remove();
    unlockSounds();
  }
  for (const type of gestures) window.addEventListener(type, onGesture, CAPTURE);
  return remove;
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
