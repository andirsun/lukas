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
