import type { CDPSession, Locator, Page } from "@playwright/test";

/**
 * Real touch input for the phone project, through the Chrome DevTools Protocol: the page gets
 * `touchstart` / `touchmove` / `touchend` and the pointer events Chrome makes from them, as on a
 * phone (Playwright's `tap()` sends only a tap, never a drag).
 */

export interface Point {
  x: number;
  y: number;
}

const sessions = new WeakMap<Page, Promise<CDPSession>>();

function cdp(page: Page): Promise<CDPSession> {
  let session = sessions.get(page);
  if (!session) {
    session = page.context().newCDPSession(page);
    sessions.set(page, session);
  }
  return session;
}

async function send(
  page: Page,
  type: "touchStart" | "touchMove" | "touchEnd" | "touchCancel",
  points: Point[],
) {
  await (await cdp(page)).send("Input.dispatchTouchEvent", {
    type,
    touchPoints: points.map(({ x, y }) => ({ x: Math.round(x), y: Math.round(y) })),
  });
}

/** The center of an element on screen. */
export async function centerOf(locator: Locator): Promise<Point> {
  // A screen that is still changing (a step of onboarding replacing the last) can swap the
  // element under us: try again with the new one.
  for (let attempt = 0; ; attempt++) {
    try {
      await locator.scrollIntoViewIfNeeded();
      // Clear of the sticky header and the bottom bar, which would take the touch instead.
      await locator.evaluate((element) => {
        const rect = element.getBoundingClientRect();
        const fixed = getComputedStyle(element).position === "fixed";
        if (!fixed && (rect.top < 80 || rect.bottom > window.innerHeight - 120)) {
          element.scrollIntoView({ block: "center" });
        }
      });
      const box = await locator.boundingBox();
      if (!box) throw new Error("The element is not on screen");
      return { x: box.x + box.width / 2, y: box.y + box.height / 2 };
    } catch (error) {
      if (attempt >= 3) throw error;
      await locator.page().waitForTimeout(100);
    }
  }
}

/** A finger down on the screen; move it, then lift it. */
export async function touchDown(page: Page, at: Point) {
  await send(page, "touchStart", [at]);
  let current = at;
  return {
    /** Moves the finger to `to` in `steps` even steps, `stepMs` apart (16 ms is one frame). */
    async moveTo(to: Point, { steps = 10, stepMs = 16 } = {}) {
      const from = current;
      for (let i = 1; i <= steps; i++) {
        const point = {
          x: from.x + ((to.x - from.x) * i) / steps,
          y: from.y + ((to.y - from.y) * i) / steps,
        };
        await send(page, "touchMove", [point]);
        if (stepMs > 0) await page.waitForTimeout(stepMs);
      }
      current = to;
    },
    async up() {
      await send(page, "touchEnd", []);
    },
  };
}

/** A tap with a finger. */
export async function tap(page: Page, target: Locator) {
  const finger = await touchDown(page, await centerOf(target));
  await finger.up();
}

/**
 * A drag from `from` by `(dx, dy)`, in `steps` frames, then the finger lifts. Fast (few steps) is a
 * flick; slow (many steps) is a drag.
 */
export async function swipe(
  page: Page,
  from: Point,
  {
    dx = 0,
    dy = 0,
    steps = 12,
    stepMs = 16,
  }: Partial<Point & { dx: number; dy: number; steps: number; stepMs: number }> = {},
) {
  const finger = await touchDown(page, from);
  await finger.moveTo({ x: from.x + dx, y: from.y + dy }, { steps, stepMs });
  await finger.up();
}
