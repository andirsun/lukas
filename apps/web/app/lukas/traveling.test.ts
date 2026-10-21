import { describe, expect, it } from "vitest";
import { ENTRANCE_MS, rollAt } from "./entrance.ts";
import {
  COIN,
  entranceFrame,
  MAX_TILT_DEG,
  spotMood,
  TRAVEL_FROM,
  tiltToward,
  travelFrame,
} from "./traveling.ts";

describe("spotMood", () => {
  it("maps the landing's spots to their moods", () => {
    const spots = [
      { id: "hero", pose: "wave", mood: "happy" },
      { id: "ways", pose: "point", mood: "happy" },
      { id: "how", pose: "carry", mood: "worried" },
      { id: "faq", pose: "point", mood: "happy" },
      { id: "closing", pose: "celebrate", mood: "celebrating" },
    ];
    expect(spots.map((spot) => [spot.id, spotMood(spot.pose, spot.mood)])).toEqual([
      ["hero", "happy"],
      ["ways", "happy"],
      ["how", "worried"],
      ["faq", "happy"],
      ["closing", "celebrating"],
    ]);
  });

  it("falls back to the pose's mood without a (valid) data-lukas-mood", () => {
    expect(spotMood("wave", undefined)).toBe("happy");
    expect(spotMood("point", undefined)).toBe("happy");
    expect(spotMood("carry", undefined)).toBe("happy");
    expect(spotMood("celebrate", undefined)).toBe("celebrating");
    expect(spotMood("celebrate", "grumpy")).toBe("celebrating");
  });

  it("lets data-lukas-mood win over the pose", () => {
    expect(spotMood("wave", "worried")).toBe("worried");
  });

  it("is happy for an unknown pose", () => {
    expect(spotMood(undefined, undefined)).toBe("happy");
    expect(spotMood("dance", undefined)).toBe("happy");
  });
});

describe("tiltToward", () => {
  const viewport = { width: 1000, height: 800 };
  const center = { x: 500, y: 400 };

  it("faces the viewer when the pointer is on him", () => {
    const tilt = tiltToward({ x: 500, y: 400 }, center, viewport);
    expect(tilt.rotateX).toBeCloseTo(0);
    expect(tilt.rotateY).toBeCloseTo(0);
  });

  it("turns toward the pointer: right is a positive rotateY, below a negative rotateX", () => {
    // Half of the 45%-of-viewport reach: half the maximum.
    const tilt = tiltToward(
      { x: 500 + 1000 * 0.45 * 0.5, y: 400 + 800 * 0.45 * 0.5 },
      center,
      viewport,
    );
    expect(tilt.rotateY).toBeCloseTo(MAX_TILT_DEG / 2);
    expect(tilt.rotateX).toBeCloseTo(-MAX_TILT_DEG / 2);
  });

  it("clamps to ±12°", () => {
    expect(MAX_TILT_DEG).toBe(12);
    const far = tiltToward({ x: 99_999, y: -99_999 }, center, viewport);
    expect(far).toEqual({ rotateX: 12, rotateY: 12 });
    const other = tiltToward({ x: -99_999, y: 99_999 }, center, viewport);
    expect(other).toEqual({ rotateX: -12, rotateY: -12 });
  });

  it("stays still on a degenerate viewport", () => {
    expect(tiltToward({ x: 10, y: 10 }, center, { width: 0, height: 0 })).toEqual({
      rotateX: 0,
      rotateY: 0,
    });
  });
});

describe("travelFrame", () => {
  it("stands on the current spot for most of the section", () => {
    for (const y of [0, 0.3, TRAVEL_FROM]) {
      expect(travelFrame(y, true)).toEqual({ at: "current", opacity: 1, turn: 0, moving: false });
    }
  });

  it("never leaves the last spot", () => {
    expect(travelFrame(0.95, false)).toEqual({
      at: "current",
      opacity: 1,
      turn: 0,
      moving: false,
    });
  });

  it("flips edge-on and fades out on the current spot, then in on the next one", () => {
    const leaving = travelFrame(TRAVEL_FROM + (1 - TRAVEL_FROM) * 0.25, true);
    expect(leaving.at).toBe("current");
    expect(leaving.moving).toBe(true);
    expect(leaving.opacity).toBeGreaterThan(0);
    expect(leaving.opacity).toBeLessThan(1);
    expect(leaving.turn).toBeGreaterThan(0);
    expect(leaving.turn).toBeLessThan(90);

    // Halfway he is edge-on and invisible: the only moment he changes spots.
    const swap = travelFrame(TRAVEL_FROM + (1 - TRAVEL_FROM) * 0.5, true);
    expect(swap.at).toBe("next");
    expect(swap.opacity).toBeCloseTo(0);
    expect(Math.abs(swap.turn)).toBeCloseTo(90);

    const arriving = travelFrame(TRAVEL_FROM + (1 - TRAVEL_FROM) * 0.75, true);
    expect(arriving.at).toBe("next");
    expect(arriving.opacity).toBeGreaterThan(0);
    expect(arriving.turn).toBeLessThan(0);
    expect(arriving.turn).toBeGreaterThan(-90);
  });

  it("has arrived at the end of the section", () => {
    expect(travelFrame(1, true)).toEqual({ at: "next", opacity: 1, turn: 0, moving: false });
  });

  it("is only ever in one place: never visible between spots", () => {
    for (let y = 0; y <= 1; y += 0.01) {
      const frame = travelFrame(y, true);
      expect(["current", "next"]).toContain(frame.at);
      expect(frame.opacity).toBeGreaterThanOrEqual(0);
      expect(frame.opacity).toBeLessThanOrEqual(1);
    }
  });
});

describe("entranceFrame", () => {
  const size = 400;
  const radius = COIN.radius * size;
  const distance = 2 * Math.PI * radius;
  const at = (phase: keyof typeof ENTRANCE_MS, progress: number) => {
    const order = ["roll", "settle", "unfold", "wave"] as const;
    let ms = 0;
    for (const name of order) {
      if (name === phase) break;
      ms += ENTRANCE_MS[name];
    }
    return ms + ENTRANCE_MS[phase] * progress;
  };

  it("starts one circumference away on the entrance side, tucked into the coin", () => {
    const start = entranceFrame(0, size, 1);
    expect(start.phase).toBe("roll");
    expect(start.x).toBeCloseTo(distance);
    expect(start.rotate).toBeCloseTo(0);
    expect(start.reveal).toBe(0);
    expect(start.drop).toBeCloseTo(COIN.drop);
    expect(start.still).toBe(true);
  });

  it("rolls without sliding: the turn is the distance travelled over the radius", () => {
    const ms = at("roll", 0.4);
    const { offset, angle } = rollAt(0.4, distance, radius);
    const frame = entranceFrame(ms, size, 1);
    expect(frame.x).toBeCloseTo(offset);
    // Coming from the right he rolls to the left: counter-clockwise, a negative CSS rotate().
    expect(frame.rotate).toBeCloseTo((-angle * 180) / Math.PI);
    const mirrored = entranceFrame(ms, size, -1);
    expect(mirrored.x).toBeCloseTo(-offset);
    expect(mirrored.rotate).toBeCloseTo((angle * 180) / Math.PI);
  });

  it("ends the roll upright on his spot", () => {
    const frame = entranceFrame(at("roll", 0.9999), size, 1);
    expect(frame.x).toBeCloseTo(0, 0);
    expect(Math.abs(frame.rotate)).toBeCloseTo(360, 0);
  });

  it("settles with a small bounce on the spot, still tucked", () => {
    const frame = entranceFrame(at("settle", 0.5), size, 1);
    expect(frame.phase).toBe("settle");
    expect(frame.x).toBe(0);
    expect(frame.drop).toBeLessThan(COIN.drop);
    expect(frame.reveal).toBe(0);
    expect(frame.still).toBe(true);
    expect(entranceFrame(at("settle", 0.9999), size, 1).drop).toBeCloseTo(COIN.drop, 2);
  });

  it("unfolds: the arms and legs come out as he rises onto his feet", () => {
    const mid = entranceFrame(at("unfold", 0.5), size, 1);
    expect(mid.phase).toBe("unfold");
    expect(mid.reveal).toBeGreaterThan(0);
    expect(mid.drop).toBeLessThan(COIN.drop);
    expect(mid.still).toBe(true);
    const end = entranceFrame(at("unfold", 0.9999), size, 1);
    expect(end.reveal).toBeCloseTo(1, 2);
    expect(end.drop).toBeCloseTo(0, 2);
    expect(end.scale).toBeCloseTo(1, 2);
  });

  it("waves with the sheet playing, then is done", () => {
    const wave = entranceFrame(at("wave", 0.5), size, 1);
    expect(wave).toMatchObject({
      phase: "wave",
      x: 0,
      rotate: 0,
      drop: 0,
      reveal: 1,
      still: false,
    });
    expect(entranceFrame(ENTRANCE_MS.total + 10, size, 1)).toMatchObject({
      phase: "done",
      x: 0,
      reveal: 1,
      still: false,
    });
  });
});
