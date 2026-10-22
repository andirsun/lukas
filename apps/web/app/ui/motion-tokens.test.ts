import { describe, expect, it, vi } from "vitest";
import { reducedMotionStore } from "./motion-tokens.ts";

/** A stand-in for `window.matchMedia` whose one query can be flipped like the OS setting. */
function fakeMedia(initial: boolean) {
  const listeners = new Set<() => void>();
  const query = {
    matches: initial,
    addEventListener: (_: "change", listener: () => void) => listeners.add(listener),
    removeEventListener: (_: "change", listener: () => void) => listeners.delete(listener),
  };
  return {
    matchMedia: vi.fn(() => query),
    set(value: boolean) {
      query.matches = value;
      for (const listener of listeners) listener();
    },
    listeners,
  };
}

describe("reducedMotionStore", () => {
  it("reads prefers-reduced-motion", () => {
    const media = fakeMedia(true);
    const store = reducedMotionStore(() => media.matchMedia);
    expect(store.getSnapshot()).toBe(true);
    expect(media.matchMedia).toHaveBeenCalledWith("(prefers-reduced-motion: reduce)");
  });

  it("flips, and tells subscribers, when the setting changes while the page is open", () => {
    const media = fakeMedia(false);
    const store = reducedMotionStore(() => media.matchMedia);
    const onChange = vi.fn();
    const unsubscribe = store.subscribe(onChange);
    expect(store.getSnapshot()).toBe(false);

    media.set(true);
    expect(onChange).toHaveBeenCalledTimes(1);
    expect(store.getSnapshot()).toBe(true);

    media.set(false);
    expect(store.getSnapshot()).toBe(false);

    unsubscribe();
    expect(media.listeners.size).toBe(0);
  });

  it("is false without matchMedia and on the server (prerender and hydration stay motion-on)", () => {
    const store = reducedMotionStore(() => undefined);
    expect(store.getSnapshot()).toBe(false);
    expect(store.getServerSnapshot()).toBe(false);
    expect(store.subscribe(() => {})).toBeTypeOf("function");
  });
});
