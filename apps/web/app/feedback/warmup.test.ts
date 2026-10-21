import { afterEach, describe, expect, it, vi } from "vitest";
import { prefetchImageWhenIdle } from "./warmup.ts";

const loaded: string[] = [];

class FakeImage {
  set src(value: string) {
    loaded.push(value);
  }
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.useRealTimers();
  loaded.length = 0;
});

describe("prefetchImageWhenIdle", () => {
  it("fetches the image only when the browser is idle", () => {
    let idle: () => void = () => {};
    vi.stubGlobal("Image", FakeImage);
    vi.stubGlobal("window", {
      requestIdleCallback: (callback: () => void) => {
        idle = callback;
        return 7;
      },
      cancelIdleCallback: vi.fn(),
    });
    prefetchImageWhenIdle("/lukas/celebrate.webp");
    expect(loaded).toEqual([]);
    idle();
    expect(loaded).toEqual(["/lukas/celebrate.webp"]);
  });

  it("cancels the idle callback", () => {
    const cancelIdleCallback = vi.fn();
    vi.stubGlobal("Image", FakeImage);
    vi.stubGlobal("window", { requestIdleCallback: () => 7, cancelIdleCallback });
    prefetchImageWhenIdle("/x.webp")();
    expect(cancelIdleCallback).toHaveBeenCalledWith(7);
  });

  it("falls back to a timeout without requestIdleCallback", () => {
    vi.useFakeTimers();
    vi.stubGlobal("Image", FakeImage);
    vi.stubGlobal("window", {});
    prefetchImageWhenIdle("/lukas/celebrate.webp");
    expect(loaded).toEqual([]);
    vi.advanceTimersByTime(2000);
    expect(loaded).toEqual(["/lukas/celebrate.webp"]);
  });

  it("cancels the timeout", () => {
    vi.useFakeTimers();
    vi.stubGlobal("Image", FakeImage);
    vi.stubGlobal("window", {});
    prefetchImageWhenIdle("/x.webp")();
    vi.advanceTimersByTime(5000);
    expect(loaded).toEqual([]);
  });

  it("does nothing without window or Image", () => {
    expect(() => prefetchImageWhenIdle("/x.webp")()).not.toThrow();
  });
});
