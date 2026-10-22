import { monthOf, todayIn } from "@lukas/core";
import { afterEach, describe, expect, it, vi } from "vitest";
import { createApiClient } from "../api/client.ts";
import { createDemoBackend } from "./demo-backend.ts";
import { DEMO_SEED } from "./demo-data.ts";
import { fakeClock } from "./fake-clock.ts";

afterEach(() => {
  vi.useRealTimers();
});

describe("fakeClock (the demo stories' clock)", () => {
  it("moves `new Date()` and `Date.now()` to the given day whatever the machine's date, and puts it back", () => {
    // The machine thinks it is 15 November.
    vi.useFakeTimers({ now: new Date("2026-11-15T12:00:00Z"), toFake: ["Date"] });
    const restore = fakeClock(new Date("2026-10-21T18:00:00Z"));
    expect(new Date().toISOString().slice(0, 10)).toBe("2026-10-21");
    expect(new Date(Date.now()).toISOString().slice(0, 16)).toBe("2026-10-21T18:00");
    expect(todayIn("America/Bogota")).toBe("2026-10-21");
    // Dates from explicit values are untouched.
    expect(new Date("2026-01-02T00:00:00Z").toISOString()).toBe("2026-01-02T00:00:00.000Z");
    restore();
    expect(new Date().toISOString().slice(0, 10)).toBe("2026-11-15");
  });

  it("makes the screens and a backend built with its default clock agree on October", async () => {
    vi.useFakeTimers({ now: new Date("2026-11-15T12:00:00Z"), toFake: ["Date"] });
    const restore = fakeClock(new Date("2026-10-21T18:00:00Z"));
    try {
      const backend = createDemoBackend(DEMO_SEED.es);
      const api = createApiClient({ fetch: backend.fetch, baseUrl: "http://demo.test/api" });
      // What Home asks for: the month of `todayIn(me.timezone)`.
      const month = monthOf(todayIn("America/Bogota"));
      const { data } = await api.GET("/v1/summary", { params: { query: { month } } });
      expect(data).toMatchObject({ month: "2026-10", remaining: 638_100_00, spent: 3_341_900_00 });
    } finally {
      restore();
    }
  });
});
