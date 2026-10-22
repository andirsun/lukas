import { describe, expect, it } from "vitest";
import {
  armedSide,
  gestureOwner,
  lockAxis,
  pagerTarget,
  rowOffset,
  rowRelease,
  rubberBand,
  velocityTracker,
} from "./gesture.ts";

describe("lockAxis", () => {
  it("waits until the finger has moved past the slop", () => {
    expect(lockAxis(5, 3, 8)).toBeNull();
    expect(lockAxis(-8, 0, 8)).toBeNull();
  });

  it("is horizontal only when the move is more sideways than down", () => {
    expect(lockAxis(12, 4, 8)).toBe("x");
    expect(lockAxis(-12, 11, 8)).toBe("x");
    expect(lockAxis(4, 12, 8)).toBe("y");
    expect(lockAxis(-3, -20, 8)).toBe("y");
  });

  it("gives a perfect diagonal to scrolling", () => {
    expect(lockAxis(10, 10, 8)).toBe("y");
    expect(lockAxis(-10, -10, 8)).toBe("y");
  });
});

describe("rubberBand", () => {
  it("follows 1:1 inside the bounds", () => {
    expect(rubberBand(0.4, 0, 1, 0.3)).toBe(0.4);
  });

  it("resists past either bound by the factor", () => {
    expect(rubberBand(-100, 0, 1, 0.3)).toBeCloseTo(-30);
    expect(rubberBand(2, 0, 1, 0.3)).toBeCloseTo(1.3);
  });
});

describe("velocityTracker", () => {
  it("measures px/s over the last moves", () => {
    const tracker = velocityTracker();
    tracker.add(0, 0);
    tracker.add(16, 8);
    tracker.add(32, 16);
    expect(tracker.velocity(32)).toBeCloseTo(500);
  });

  it("forgets moves older than its window, so a pause stops a flick", () => {
    const tracker = velocityTracker(100);
    tracker.add(0, 0);
    tracker.add(16, 100);
    tracker.add(300, 100);
    expect(tracker.velocity(300)).toBe(0);
  });

  it("is 0 with fewer than two moves", () => {
    const tracker = velocityTracker();
    expect(tracker.velocity(0)).toBe(0);
    tracker.add(0, 10);
    expect(tracker.velocity(0)).toBe(0);
  });
});

describe("pagerTarget", () => {
  const base = { width: 400, count: 2, flick: 500 };

  it("snaps to the nearer page", () => {
    expect(pagerTarget({ ...base, index: 0, dx: -150, vx: 0 })).toBe(0);
    expect(pagerTarget({ ...base, index: 0, dx: -250, vx: 0 })).toBe(1);
    expect(pagerTarget({ ...base, index: 1, dx: 250, vx: 0 })).toBe(0);
  });

  it("switches on a flick, even after a short distance", () => {
    expect(pagerTarget({ ...base, index: 0, dx: -30, vx: -600 })).toBe(1);
    expect(pagerTarget({ ...base, index: 1, dx: 30, vx: 600 })).toBe(0);
  });

  it("ignores a slow release under the flick speed", () => {
    expect(pagerTarget({ ...base, index: 0, dx: -30, vx: -400 })).toBe(0);
  });

  it("never leaves the pages", () => {
    expect(pagerTarget({ ...base, index: 0, dx: 300, vx: 900 })).toBe(0);
    expect(pagerTarget({ ...base, index: 1, dx: -300, vx: -900 })).toBe(1);
  });

  it("follows the flick's direction over the distance", () => {
    // Dragged most of the way, then flung back: back it goes.
    expect(pagerTarget({ ...base, index: 0, dx: -300, vx: 700 })).toBe(0);
  });
});

describe("rowOffset", () => {
  const base = { width: 360, factor: 0.3, left: true, right: true };

  it("follows the finger 1:1 to either side with an action", () => {
    expect(rowOffset({ ...base, start: 0, dx: -100 })).toBe(-100);
    expect(rowOffset({ ...base, start: 0, dx: 120 })).toBe(120);
    expect(rowOffset({ ...base, start: -88, dx: 30 })).toBe(-58);
  });

  it("resists toward a side without an action", () => {
    expect(rowOffset({ ...base, right: false, start: 0, dx: 100 })).toBeCloseTo(30);
    expect(rowOffset({ ...base, left: false, start: 0, dx: -100 })).toBeCloseTo(-30);
  });

  it("stops at the row's width", () => {
    expect(rowOffset({ ...base, start: 0, dx: -500 })).toBe(-360);
  });
});

describe("armedSide", () => {
  it("arms a side past the threshold (40 % of the row)", () => {
    expect(armedSide(-143, 360, 0.4)).toBeNull();
    expect(armedSide(-144, 360, 0.4)).toBe("left");
    expect(armedSide(150, 360, 0.4)).toBe("right");
  });
});

describe("rowRelease", () => {
  const base = { width: 360, threshold: 0.4, flick: 500, openWidth: 88, left: true, right: true };

  it("commits past the threshold", () => {
    expect(rowRelease({ ...base, offset: -150, vx: 0 })).toBe("commit-left");
    expect(rowRelease({ ...base, offset: 150, vx: 0 })).toBe("commit-right");
  });

  it("commits on a flick toward the action, even after a short distance", () => {
    expect(rowRelease({ ...base, offset: -30, vx: -700 })).toBe("commit-left");
    expect(rowRelease({ ...base, offset: 30, vx: 700 })).toBe("commit-right");
  });

  it("leaves a short swipe open", () => {
    expect(rowRelease({ ...base, offset: -60, vx: 0 })).toBe("open-left");
    expect(rowRelease({ ...base, offset: 60, vx: 0 })).toBe("open-right");
  });

  it("closes a tiny swipe, or one flung back", () => {
    expect(rowRelease({ ...base, offset: -20, vx: 0 })).toBe("close");
    expect(rowRelease({ ...base, offset: -80, vx: 700 })).toBe("close");
  });

  it("never commits a side without an action", () => {
    expect(rowRelease({ ...base, right: false, offset: 200, vx: 800 })).toBe("close");
  });
});

describe("gestureOwner (the gesture-priority ruling)", () => {
  const on = (row: boolean) => ({ closest: (selector: string) => (row ? { selector } : null) });

  it("gives a gesture that starts on a swipeable row to the row", () => {
    expect(gestureOwner(on(true))).toBe("row");
  });

  it("gives every other gesture to the pager", () => {
    expect(gestureOwner(on(false))).toBe("pager");
    expect(gestureOwner(null)).toBe("pager");
  });
});
