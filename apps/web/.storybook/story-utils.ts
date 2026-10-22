import { expect, waitFor } from "storybook/test";

/** Vertical offset of an element's transform, in px (0 when it has none). */
export function translateY(element: Element): number {
  return new DOMMatrix(getComputedStyle(element).transform).m42;
}

/** A computed color for a CSS value such as `var(--focus)`, to compare with computed styles. */
export function resolveColor(value: string): string {
  const probe = document.createElement("span");
  probe.style.color = value;
  document.body.append(probe);
  const color = getComputedStyle(probe).color;
  probe.remove();
  return color;
}

/** The pressable's touch target is at least 44×44px. */
export async function expectTarget(element: Element): Promise<void> {
  const box = element.getBoundingClientRect();
  await expect(box.height).toBeGreaterThanOrEqual(44);
  await expect(box.width).toBeGreaterThanOrEqual(44);
}

/** The focused element shows the 3px solid ring in the theme's `--focus` color. */
export async function expectFocusRing(element: Element): Promise<void> {
  const style = getComputedStyle(element);
  await expect(style.outlineStyle).toBe("solid");
  await expect(Number.parseFloat(style.outlineWidth)).toBe(3);
  await expect(style.outlineColor).toBe(resolveColor("var(--focus)"));
}

/** The element sits on a solid (unblurred) bottom edge of `px` pixels. */
export async function expectEdge(element: Element, px: number): Promise<void> {
  await expect(getComputedStyle(element).boxShadow).toMatch(new RegExp(` 0px ${px}px 0px 0px`));
}

/**
 * Pressed (`:active` or `.is-pressed`): the element has moved down by `px` and its edge has
 * collapsed to 1px. Waits out the `--press` transition.
 */
export async function expectSunk(element: Element, px: number): Promise<void> {
  await waitFor(() => expect(translateY(element)).toBe(px));
  await expectEdge(element, 1);
}

const pause = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * A finger drag, as pointer events (`pointerType: "touch"`): down at `from` (the element's center
 * by default), then `steps` moves `stepMs` apart to `from + (dx, dy)` (or through each leg of
 * `path`, offsets from `from`), then up. Fast (few steps) is a flick. `hold` runs while the finger
 * is still down at the end, to look at the drag mid-way.
 */
export async function fingerDrag(
  element: Element,
  {
    dx = 0,
    dy = 0,
    steps = 12,
    stepMs = 16,
    from,
    path,
    hold,
  }: {
    dx?: number;
    dy?: number;
    steps?: number;
    stepMs?: number;
    from?: { x: number; y: number };
    path?: { dx: number; dy?: number; steps?: number }[];
    hold?: () => Promise<void>;
  } = {},
): Promise<void> {
  const box = element.getBoundingClientRect();
  const start = from ?? { x: box.left + box.width / 2, y: box.top + box.height / 2 };
  const pointerId = 100 + Math.floor(Math.random() * 1000);
  const fire = (type: string, x: number, y: number) =>
    element.dispatchEvent(
      new PointerEvent(type, {
        pointerId,
        pointerType: "touch",
        isPrimary: true,
        clientX: x,
        clientY: y,
        bubbles: true,
        cancelable: true,
        composed: true,
      }),
    );
  fire("pointerdown", start.x, start.y);
  let at = { dx: 0, dy: 0 };
  for (const leg of path ?? [{ dx, dy, steps }]) {
    const n = leg.steps ?? steps;
    const to = { dx: leg.dx, dy: leg.dy ?? 0 };
    for (let i = 1; i <= n; i++) {
      await pause(stepMs);
      fire(
        "pointermove",
        start.x + at.dx + ((to.dx - at.dx) * i) / n,
        start.y + at.dy + ((to.dy - at.dy) * i) / n,
      );
    }
    at = to;
  }
  await hold?.();
  fire("pointerup", start.x + at.dx, start.y + at.dy);
}

/** Horizontal offset of an element's transform, in px (0 when it has none). */
export function translateX(element: Element): number {
  return new DOMMatrix(getComputedStyle(element).transform).m41;
}
