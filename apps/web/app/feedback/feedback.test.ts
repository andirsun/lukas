import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  __resetFeedbackForTests,
  FEEDBACK_DOM_EVENT,
  type FeedbackDetail,
  type FeedbackEvent,
  feedback,
  installSoundUnlock,
  SOUND_STORAGE_KEY,
  unlockSounds,
  VIBRATION_PATTERNS,
} from "./feedback.ts";

const play = vi.fn((): Promise<void> | undefined => Promise.resolve());
const created: string[] = [];

const pause = vi.fn();
const instances: FakeAudio[] = [];

class FakeAudio {
  currentTime = 0;
  volume = 1;
  preload = "";
  muted = false;
  paused = true;
  constructor(src?: string) {
    created.push(src ?? "");
    instances.push(this);
  }
  play() {
    this.paused = false;
    return play();
  }
  pause() {
    this.paused = true;
    pause();
  }
}

function stubStorage(value: string | null) {
  vi.stubGlobal("localStorage", {
    getItem: (key: string) => (key === SOUND_STORAGE_KEY ? value : null),
  });
}

beforeEach(() => {
  play.mockClear();
  pause.mockClear();
  created.length = 0;
  instances.length = 0;
  __resetFeedbackForTests();
  stubStorage(null);
  vi.stubGlobal("Audio", FakeAudio);
  vi.stubGlobal("navigator", { vibrate: vi.fn(() => true) });
  vi.stubGlobal("window", new EventTarget());
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("feedback: vibration", () => {
  it("vibrates with the pattern of the event", () => {
    feedback("paid");
    expect(navigator.vibrate).toHaveBeenCalledWith([10, 30, 10, 30, 24]);
  });

  it("has the documented pattern for every event", () => {
    expect(VIBRATION_PATTERNS).toEqual({
      tap: [8],
      expenseSaved: [12, 40, 18],
      incomeSaved: [12, 40, 18],
      paid: [10, 30, 10, 30, 24],
      nearLimit: [30],
      overBudget: [40, 60, 40],
      undo: [8],
    });
  });

  it("does not throw without navigator.vibrate (iOS Safari)", () => {
    vi.stubGlobal("navigator", {});
    expect(() => feedback("paid")).not.toThrow();
  });

  it("does not throw when vibrate itself throws", () => {
    vi.stubGlobal("navigator", {
      vibrate: () => {
        throw new Error("blocked");
      },
    });
    expect(() => feedback("tap")).not.toThrow();
  });
});

describe("feedback: sound", () => {
  it("plays the sound of the event", () => {
    feedback("expenseSaved");
    expect(play).toHaveBeenCalledTimes(1);
    expect(created).toHaveLength(1);
  });

  it("plays a different sound per kind of event and reuses the loaded element", () => {
    feedback("tap");
    feedback("undo");
    feedback("tap");
    expect(created).toHaveLength(2);
    expect(new Set(created).size).toBe(2);
    expect(play).toHaveBeenCalledTimes(3);
  });

  it("loads nothing until the first call", () => {
    expect(created).toHaveLength(0);
  });

  it("plays nothing when sound is muted, but still vibrates", () => {
    stubStorage("off");
    feedback("paid");
    expect(play).not.toHaveBeenCalled();
    expect(created).toHaveLength(0);
    expect(navigator.vibrate).toHaveBeenCalled();
  });

  it("plays when the stored value is anything but off", () => {
    stubStorage("on");
    feedback("tap");
    expect(play).toHaveBeenCalledTimes(1);
  });

  it("does not throw without Audio", () => {
    vi.stubGlobal("Audio", undefined);
    expect(() => feedback("paid")).not.toThrow();
  });

  it("does not throw when play() rejects (autoplay policy)", async () => {
    play.mockImplementationOnce(() => Promise.reject(new Error("NotAllowedError")));
    expect(() => feedback("paid")).not.toThrow();
    await Promise.resolve();
  });

  it("does not throw when reading storage is blocked", () => {
    vi.stubGlobal("localStorage", {
      getItem: () => {
        throw new Error("denied");
      },
    });
    expect(() => feedback("tap")).not.toThrow();
    expect(play).toHaveBeenCalledTimes(1);
  });

  it("does not throw with nothing available at all", () => {
    vi.stubGlobal("Audio", undefined);
    vi.stubGlobal("navigator", undefined);
    vi.stubGlobal("localStorage", undefined);
    vi.stubGlobal("window", undefined);
    expect(() => feedback("overBudget")).not.toThrow();
  });
});

describe("feedback: DOM event", () => {
  it("dispatches lukas:feedback with the event name", () => {
    const received: FeedbackDetail[] = [];
    window.addEventListener(FEEDBACK_DOM_EVENT, (event) => {
      received.push((event as CustomEvent<FeedbackDetail>).detail);
    });
    const events: FeedbackEvent[] = ["expenseSaved", "undo"];
    for (const event of events) feedback(event);
    expect(FEEDBACK_DOM_EVENT).toBe("lukas:feedback");
    expect(received).toEqual([{ event: "expenseSaved" }, { event: "undo" }]);
  });

  it("dispatches even when muted", () => {
    stubStorage("off");
    const listener = vi.fn();
    window.addEventListener(FEEDBACK_DOM_EVENT, listener);
    feedback("paid");
    expect(listener).toHaveBeenCalledTimes(1);
  });
});

describe("feedback: unlocking sound for iOS Safari", () => {
  const settle = () => new Promise((resolve) => setTimeout(resolve, 0));

  it("loads nothing before the first gesture", () => {
    installSoundUnlock();
    expect(created).toHaveLength(0);
    expect(play).not.toHaveBeenCalled();
  });

  for (const type of ["pointerdown", "keydown"]) {
    it(`on the first ${type}, plays every sound once, muted, then pauses it`, async () => {
      installSoundUnlock();
      const mutedWhilePlaying: boolean[] = [];
      play.mockImplementation(() => {
        mutedWhilePlaying.push(instances[play.mock.calls.length - 1]?.muted ?? false);
        return Promise.resolve();
      });
      window.dispatchEvent(new Event(type));
      expect(created).toHaveLength(7);
      expect(new Set(created).size).toBe(7);
      expect(play).toHaveBeenCalledTimes(7);
      expect(mutedWhilePlaying).toEqual(Array(7).fill(true));
      await settle();
      expect(pause).toHaveBeenCalledTimes(7);
      for (const audio of instances) {
        expect(audio.muted).toBe(false);
        expect(audio.paused).toBe(true);
        expect(audio.currentTime).toBe(0);
      }
      play.mockImplementation(() => Promise.resolve());
    });
  }

  it("unlocks only once and removes its listeners", async () => {
    installSoundUnlock();
    window.dispatchEvent(new Event("pointerdown"));
    await settle();
    play.mockClear();
    window.dispatchEvent(new Event("pointerdown"));
    window.dispatchEvent(new Event("keydown"));
    expect(play).not.toHaveBeenCalled();
  });

  it("can be cancelled before any gesture", () => {
    const remove = installSoundUnlock();
    remove();
    window.dispatchEvent(new Event("pointerdown"));
    expect(created).toHaveLength(0);
  });

  it("reuses the unlocked elements for later sounds", async () => {
    unlockSounds();
    await settle();
    feedback("paid");
    expect(created).toHaveLength(7);
    expect(play).toHaveBeenCalledTimes(8);
  });

  it("lets a real sound that starts while unlocking keep playing", async () => {
    unlockSounds();
    feedback("paid"); // Before the silent play() has settled.
    await settle();
    const paid = instances.find((audio) => audio.muted === false && audio.paused === false);
    expect(paid).toBeDefined();
    expect(pause).toHaveBeenCalledTimes(6);
  });

  it("does not throw when play() rejects or returns nothing", async () => {
    play.mockImplementationOnce(() => Promise.reject(new Error("NotAllowedError")));
    play.mockImplementationOnce(() => undefined);
    expect(() => unlockSounds()).not.toThrow();
    await settle();
    for (const audio of instances) expect(audio.muted).toBe(false);
  });

  it("does nothing without Audio or window", () => {
    vi.stubGlobal("Audio", undefined);
    expect(() => unlockSounds()).not.toThrow();
    vi.stubGlobal("window", undefined);
    expect(() => installSoundUnlock()()).not.toThrow();
  });
});
