import { describe, expect, it } from "vitest";
import { TOOLS } from "../src/index.ts";
import phrases from "./phrases.json" with { type: "json" };

// The live run against a real model is a manual step before launch (spec §8); this keeps the
// expected calls valid while the tool schemas change.
describe("the Spanish phrases set", () => {
  it("has at least 12 phrases", () => {
    expect(phrases.length).toBeGreaterThanOrEqual(12);
  });

  it.each(phrases)("«$phrase» → $tool", ({ tool, input }) => {
    const found = TOOLS.find((t) => t.name === tool);
    expect(found, `unknown tool ${tool}`).toBeDefined();
    const parsed = found?.input.safeParse(input);
    expect(parsed?.error).toBeUndefined();
  });
});
