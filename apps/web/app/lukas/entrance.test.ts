import { describe, expect, it } from "vitest";
import {
  ENTRANCE_KEY,
  ENTRANCE_MS,
  entrancePhase,
  markEntranceSeen,
  rollAt,
  shouldPlayEntrance,
} from "./entrance.ts";

describe("entrancePhase", () => {
  it("rolls in, settles, unfolds his limbs, waves, then is done (about 2 s)", () => {
    expect(entrancePhase(0)).toEqual({ phase: "roll", progress: 0 });
    expect(entrancePhase(ENTRANCE_MS.roll / 2)).toEqual({ phase: "roll", progress: 0.5 });
    expect(entrancePhase(ENTRANCE_MS.roll)).toEqual({ phase: "settle", progress: 0 });
    const unfold = ENTRANCE_MS.roll + ENTRANCE_MS.settle;
    expect(entrancePhase(unfold)).toEqual({ phase: "unfold", progress: 0 });
    expect(entrancePhase(unfold + ENTRANCE_MS.unfold / 2)).toEqual({
      phase: "unfold",
      progress: 0.5,
    });
    const wave = unfold + ENTRANCE_MS.unfold;
    expect(entrancePhase(wave)).toEqual({ phase: "wave", progress: 0 });
    expect(entrancePhase(ENTRANCE_MS.total)).toEqual({ phase: "done", progress: 1 });
    expect(entrancePhase(60_000)).toEqual({ phase: "done", progress: 1 });
    expect(ENTRANCE_MS.total).toBeGreaterThanOrEqual(1800);
    expect(ENTRANCE_MS.total).toBeLessThanOrEqual(2200);
    expect(ENTRANCE_MS.roll).toBe(800);
    expect(ENTRANCE_MS.unfold).toBe(400);
  });

  it("treats negative or invalid time as the start", () => {
    expect(entrancePhase(-50)).toEqual({ phase: "roll", progress: 0 });
    expect(entrancePhase(Number.NaN)).toEqual({ phase: "roll", progress: 0 });
  });
});

describe("rollAt", () => {
  const radius = 100;
  const distance = 2 * Math.PI * radius;

  it("starts a full turn away and ends on the spot, upright", () => {
    expect(rollAt(0, distance, radius)).toEqual({ offset: distance, angle: 0 });
    const end = rollAt(1, distance, radius);
    expect(end.offset).toBeCloseTo(0);
    expect(end.angle).toBeCloseTo(2 * Math.PI);
  });

  it("turns exactly as far as he has travelled (no sliding)", () => {
    for (const p of [0.1, 0.3, 0.5, 0.8]) {
      const { offset, angle } = rollAt(p, distance, radius);
      expect(angle * radius).toBeCloseTo(distance - offset);
    }
  });

  it("slows down as he arrives", () => {
    const early = distance - rollAt(0.2, distance, radius).offset;
    const late = rollAt(0.8, distance, radius).offset;
    expect(early).toBeGreaterThan(late);
  });
});

/** An in-memory Storage, or one that throws (private mode, blocked storage). */
function storage(throws = false): Storage {
  const data = new Map<string, string>();
  return {
    get length() {
      return data.size;
    },
    clear: () => data.clear(),
    key: (i) => [...data.keys()][i] ?? null,
    getItem: (key) => {
      if (throws) throw new Error("blocked");
      return data.get(key) ?? null;
    },
    setItem: (key, value) => {
      if (throws) throw new Error("blocked");
      data.set(key, value);
    },
    removeItem: (key) => {
      data.delete(key);
    },
  };
}

describe("shouldPlayEntrance", () => {
  it("plays once per session, while the hero is in view", () => {
    const session = storage();
    expect(shouldPlayEntrance(session, true)).toBe(true);
    markEntranceSeen(session);
    expect(session.getItem(ENTRANCE_KEY)).toBe("seen");
    expect(shouldPlayEntrance(session, true)).toBe(false);
  });

  it("is skipped when the page is already scrolled past the hero", () => {
    expect(shouldPlayEntrance(storage(), false)).toBe(false);
  });

  it("plays when storage is unavailable, and marking it does not throw", () => {
    const blocked = storage(true);
    expect(shouldPlayEntrance(blocked, true)).toBe(true);
    expect(() => markEntranceSeen(blocked)).not.toThrow();
    expect(shouldPlayEntrance(undefined, true)).toBe(true);
  });
});
