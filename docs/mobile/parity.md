# Parity: the app against the web, picture by picture

Stage 3b's rule is that the app looks like the web (spec
`docs/superpowers/specs/2026-10-23-stage-3b-mobile-parity-design.md`, §4 and §5). The parity
harness checks it. Each **pair** is a web Storybook story in one theme and an app test that
renders the same thing as a golden, at the same size, from the same data. A review picture puts
the two side by side, with the pixels that differ marked.

## The loop

From the repository root (Flutter on PATH: `export PATH="$HOME/development/flutter/bin:$PATH"`):

```sh
pnpm --filter @lukas/web parity:fixtures        # the stories' data → apps/mobile/test/parity/fixtures
pnpm --filter @lukas/web parity:shots           # the stories' pictures → apps/mobile/test/parity/web
cd apps/mobile
flutter test --update-goldens test/parity       # the app's pictures → test/parity/app
dart run tool/parity/compose.dart --max 2       # side by side → build/parity; fails over 2% of ink
```

Each command takes an optional id filter, e.g. `parity:shots money` or `compose.dart money`.

Then open `apps/mobile/build/parity/<id>-<theme>.png`:

- top left: the web;
- top right: the app;
- underneath: the web in grey, with every differing pixel in magenta, and the two shares below.

### What differs, and the pass rule

- **A pixel differs** when its colour on one side is nowhere within one logical pixel (two physical
  pixels, at the parity's ratio of 2) of the same place on the other side. Colours count as the
  same within 24 of 255 per channel.
  - That forgives what spec §5 allows: antialiasing, and text that Chrome and Flutter round to
    different pixels (see "Known differences").
  - It does not forgive a wrong size, weight, colour or spacing.
- **The ink share** is the measure: differing pixels over the pixels that are not the page's
  background on either side. The share of the whole page is printed too, but a small component on
  an empty page is almost all background, so that number says little.
- **A pair passes** when:
  - the picture shows no visible difference except those spec §5 allows: the system bars, the 🎤
    next to the ＋, the web-only demo banner, and text antialiasing; and
  - **under 2% of its ink differs.** `compose.dart --max 2` exits non-zero when a pair is over.
- Look at the picture first. The number backs it up; it does not replace it.

How the rule was set, on Money (compose's unit tests pin the tolerances):

| | Ink that differs |
| --- | --- |
| The true Money pairs | 0.00% on all 7 |
| Probe: Money's colour at 85% alpha | 64% to 85% (all 7 over) |
| Probe: Money's font 1 px bigger | 26% to 35% (all 7 over) |
| A tolerance of ±1 physical pixel instead, true pairs | 20–22% for the hero amount |

The last row is why the shift tolerance is a logical pixel, not a physical one. Blink rounds line
metrics to whole CSS pixels, so the hero amount sits 2 physical pixels away. With ±1 physical
pixel, the true pair would fail the 2% rule.

`compose.dart` writes both shares for every pair to `build/parity/summary.json`.

Once the app's side is right, plain `flutter test test/parity` is the regression test: it fails
when the app's picture changes. The web shots are regenerated only when the web changes.

## Adding a pair

1. Add the pair to `apps/mobile/test/parity/parity.json`, once per theme:

   ```json
   { "id": "money-spanish", "storyId": "ui-money--spanish", "theme": "night",
     "appTest": "test/parity/money_parity_test.dart" }
   ```

   - `id` is the file stem: `web/<id>-<theme>.png` and `app/<id>-<theme>.png`.
   - `storyId` is the Storybook id, as in the URL's `?id=`.
   - Every shared screen and component has a pair in `night` and in `day`. A story that pins
     `globals: { theme: "day" }` only has a day pair; the shots script refuses the other one.

2. Write the app test first, so it fails before the widget exists. Mark the file
   `@Tags(['golden'])` and call:

   ```dart
   await parityGolden(t, 'money-spanish', screen, theme: 'night');
   ```

   - Pass `locale: const Locale('en')` for a story with `globals: { locale: "en" }`.
   - A component's story goes in `ParityStoryFrame`, which is what Storybook's decorator puts
     around it: the page background, 16px padding, and the body's text as the line it sits on.
   - A full-screen story (`layout: "fullscreen"`, its own screen) is passed as is.

3. Read the story's data from its fixture: `ParityFixtures.load(storyId)`.
   - `fixture.get('/v1/summary?month=2026-10').body` is the JSON the story's fake API answered.
   - `fixture.now` is the clock the story ran at. `parityGolden` pins the app's `clockProvider`
     to it.

4. Run the loop, look at the picture, and fix the app until the picture shows no visible
   difference and `compose.dart --max 2` passes. Commit the web shot, the fixture and the golden.
   `build/parity` stays out of git.

## How the two sides are made the same

- **Size.** 412 × 915 logical pixels at a device pixel ratio of 2, so both pictures are 824 × 1830.
  On the web it is the Playwright viewport. In the app it is the test view.
- **Clock.** Both sides use the e2e suite's "now", 21 October 2026 at 15:00 UTC (`E2E_NOW`), in
  Europe/Madrid.
  - The shots and the fixtures pin the page's clock before anything loads, with the demo stories'
    own `fakeClock` (`apps/web/app/demo/fake-clock.ts`). The stories' "today" and month (for example
    `STORY_TODAY`) therefore come out the same on any real date.
  - The fixture records that time, and `parityGolden` gives it to the app.
- **Data.** A story harness hands its fake `fetch` to `exposeStoryFetch`
  (`apps/web/.storybook/parity.ts`). `HomeStage`, the demo's `DemoStage` and `SignInStage` do. A
  harness for a new kind of screen does the same.
  - `parity:fixtures` opens the story and lets it render and play.
  - Then it asks that same fake API every GET the story made, plus the app's GETs (`APP_GETS` in
    `apps/web/scripts/parity-fixtures.ts`).
  - When a screen needs a GET that is not there, add it to `APP_GETS`.
  - Keys are the API path without the web's `/api` mount, with the query sorted:
    `GET /v1/transactions?limit=50&month=2026-10`.
  - A component's story has no fake API, so its fixture has only the clock.
- **Theme.** The shots open `iframe.html?id=<story>&globals=theme:<theme>`, which is what the
  toolbar's theme does (`.storybook/preview.tsx`). The app test uses the app's `nightTheme` or
  `dayTheme`.
- **Settling.**
  - The shots wait for Storybook's "finished" phase, after the story has rendered, played and
    finished its animations.
  - Then they take pictures until two in a row are identical. CSS animations are taken at rest:
    finite ones at their end, endless ones (Lukitas' sprite) at their first frame.
  - The app test uses `pumpAndSettle`.
- **Fonts.** Both sides draw Fredoka and Nunito, from the web's `@fontsource` files and from the
  app's bundled upstream files.
- **Emoji.** Both sides draw emoji with Noto Color Emoji (SIL OFL 1.1). The font is committed
  unmodified in `apps/mobile/test/parity/fonts` with its licence. It is test-only and never goes
  into the APK.
  - The shots add it to each of the page's font faces, for the emoji code points only. Chrome then
    draws it instead of the Mac's Apple Color Emoji.
  - The font keeps its pictures as PNGs in `CBDT` tables. `flutter test` on macOS draws through Core
    Text, which only draws Apple's `sbix` tables. So `test/support/emoji_font.dart` moves the same
    PNGs into an `sbix` table, in memory, for the goldens.
  - The file is the 2017 build (v1.39) that ships in the Flutter SDK's engine sources. Emoji newer
    than Unicode 10 are not in it: of those the web uses, 🧪 and 🧾. Chrome falls back to Apple's
    for those and the app draws a box. The current CBDT `NotoColorEmoji.ttf` from
    googlefonts/noto-emoji can replace it in that folder, with its OFL; nothing else changes.
  - `test/parity/emoji_font_test.dart` checks that `sbixFromCbdt` converts the committed file. It
    also fails when an emoji in any fixture has no picture in it, so a missing emoji is reported
    rather than drawn as a box.
- **Icons.** Material icons draw with the Flutter SDK's own `MaterialIcons-Regular.otf`
  (`loadMaterialIcons` in `test/support/fonts.dart`), the file `flutter build` bundles. The Stage 3
  goldens load it too.

## Known differences

- **Inline line boxes.** Blink rounds a font's ascent and descent to whole pixels and floors the
  half-leading. Flutter does neither.
  - `ParityStoryFrame` places its child on the body's line the way Blink does (`cssStrutAscent`).
  - A text style whose line height is smaller than its font's own (`.lk-hero-amount` at 1.05) still
    sits up to one logical pixel lower in the app than in Chrome.
  - That is within spec §5's one-pixel wobble. compose's one-logical-pixel tolerance forgives it.
- **Glyph rasterising.** Chrome and `flutter test` rasterise the same glyphs a little differently:
  edges differ by a physical pixel here and there, which the tolerance forgives too.
- **What the tolerance hides.** An element off by one logical pixel, such as padding of 15 instead
  of 16, is not counted. Two pixels or more is.
- **Pictures are the Mac's.** Text and shadows rasterise differently on Linux. The parity goldens
  are tagged `golden`, so CI skips them (`dart_test.yaml`), as it skips the other goldens.
