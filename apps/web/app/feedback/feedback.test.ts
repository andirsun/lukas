import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  __resetFeedbackForTests,
  FEEDBACK_DOM_EVENT,
  type FeedbackDetail,
  type FeedbackEvent,
  feedback,
  SOUND_STORAGE_KEY,
  VIBRATION_PATTERNS,
} from "./feedback.ts";

const play = vi.fn(() => Promise.resolve());
const created: string[] = [];

class FakeAudio {
  currentTime = 0;
  volume = 1;
  preload = "";
  constructor(src?: string) {
    created.push(src ?? "");
  }
  play = play;
}

function stubStorage(value: string | null) {
  vi.stubGlobal("localStorage", {
    getItem: (key: string) => (key === SOUND_STORAGE_KEY ? value : null),
  });
}

beforeEach(() => {
  play.mockClear();
  created.length = 0;
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
