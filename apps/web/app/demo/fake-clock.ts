/**
 * Moves the page's clock to `at` (and lets it run on from there) until the returned function
 * puts the real one back: `new Date()` and `Date.now()` answer from `at`, while dates built from
 * explicit values are untouched. For stories of the demo: the screens ask `new Date()` which month
 * it is, and the demo's backend asks the same clock, so both agree on the same day whatever the
 * real date is when the stories run. Timers and animation frames keep real time.
 */
export function fakeClock(at: Date): () => void {
  const RealDate = globalThis.Date;
  const offset = at.getTime() - RealDate.now();
  class ShiftedDate extends RealDate {
    constructor(...args: unknown[]) {
      if (args.length === 0) super(RealDate.now() + offset);
      else super(...(args as [string | number | Date]));
    }
    static override now(): number {
      return RealDate.now() + offset;
    }
  }
  globalThis.Date = ShiftedDate as DateConstructor;
  return () => {
    globalThis.Date = RealDate;
  };
}
