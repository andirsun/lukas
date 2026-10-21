import { describe, expect, it } from "vitest";
import { type ScrollSection, scrollPose, sectionIndexAt } from "./use-scroll-pose.ts";

/** The landing's order: hero, ways, how it works, FAQ, closing call to action. */
const SECTIONS: ScrollSection[] = [
  { id: "hero", start: 0, pose: "wave" },
  { id: "ways", start: 0.2, pose: "point" },
  { id: "how", start: 0.4, pose: "carry" },
  { id: "faq", start: 0.7, pose: "point" },
  { id: "closing", start: 0.9, pose: "celebrate" },
];

describe("scrollPose", () => {
  it("waves at the top of the page", () => {
    expect(scrollPose(0, SECTIONS)).toEqual({ pose: "wave", y: 0 });
  });

  it("takes the pose of the section the progress is in", () => {
    expect(scrollPose(0.3, SECTIONS).pose).toBe("point");
    expect(scrollPose(0.2, SECTIONS).pose).toBe("point");
    expect(scrollPose(0.45, SECTIONS).pose).toBe("carry");
  });

  it("celebrates at the end of the page", () => {
    expect(scrollPose(1, SECTIONS)).toEqual({ pose: "celebrate", y: 1 });
  });

  it("gives how far through the current section the page is, as y (0 to 1)", () => {
    expect(scrollPose(0.1, SECTIONS).y).toBeCloseTo(0.5);
    expect(scrollPose(0.35, SECTIONS).y).toBeCloseTo(0.75);
    expect(scrollPose(0.95, SECTIONS).y).toBeCloseTo(0.5);
  });

  it("clamps progress outside 0..1 (overscroll)", () => {
    expect(scrollPose(-0.2, SECTIONS)).toEqual({ pose: "wave", y: 0 });
    expect(scrollPose(1.3, SECTIONS)).toEqual({ pose: "celebrate", y: 1 });
  });

  it("does not need the sections in order", () => {
    const shuffled = [SECTIONS[3], SECTIONS[0], SECTIONS[4], SECTIONS[2], SECTIONS[1]].filter(
      (s): s is ScrollSection => s !== undefined,
    );
    expect(scrollPose(0.45, shuffled).pose).toBe("carry");
    expect(scrollPose(1, shuffled).pose).toBe("celebrate");
  });

  it("treats a last section that starts at the very end as reached at 1", () => {
    const late = [SECTIONS[0], { id: "closing", start: 1, pose: "celebrate" as const }].filter(
      (s): s is ScrollSection => s !== undefined,
    );
    expect(scrollPose(0.99, late).pose).toBe("wave");
    expect(scrollPose(1, late)).toEqual({ pose: "celebrate", y: 1 });
  });

  it("waves without sections", () => {
    expect(scrollPose(0.5, [])).toEqual({ pose: "wave", y: 0 });
  });
});

describe("sectionIndexAt", () => {
  it("is the index of the current section in start order", () => {
    expect(sectionIndexAt(0, SECTIONS)).toBe(0);
    expect(sectionIndexAt(0.75, SECTIONS)).toBe(3);
    expect(sectionIndexAt(1, SECTIONS)).toBe(4);
    expect(sectionIndexAt(0.5, [])).toBe(-1);
  });
});
