import 'package:flutter/painting.dart';

/// The web's text styles, with the size, weight, line height and letter spacing its CSS gives
/// them (the web is the source: apps/web/app/styles/app.css and the components in apps/web/app/ui).
/// Colour is not here: it comes from the theme's tokens, so `LkText.label.copyWith(color: ...)`.
///
/// Fredoka (display: titles and amounts) and Nunito (text) are bundled in assets/fonts, in the
/// weights apps/web/app/styles/fonts.ts loads (Fredoka 500-700, Nunito 600-900); each file is a
/// variable font, so the weight asked for here is the one drawn.
///
/// The web sets a line height only on some styles. The others inherit Tailwind's preflight
/// (`html { line-height: 1.5 }`), so they carry `height: 1.5` here and take the same room.
abstract final class LkText {
  /// tokens.css `--font-display`: the web's first choice of the display stack.
  static const displayFamily = 'Fredoka';

  /// tokens.css `--font-text`.
  static const textFamily = 'Nunito';

  /// Tailwind's preflight line height, which every style below without a CSS one inherits
  /// (node_modules/tailwindcss/preflight.css, `html`).
  static const _inherited = 1.5;

  /// `font-variant-numeric: tabular-nums`, which the web puts on its amounts.
  static const _tabular = [FontFeature.tabularFigures()];

  /// The keypad's amount: app.css `.lk-amount-display`, Fredoka 36px 700.
  static const display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: _inherited,
    fontFeatures: _tabular,
  );

  /// The hero amount: app.css `.lk-hero-amount`, Fredoka 38px 700, line height 1.05.
  static const amountXl = TextStyle(
    fontFamily: displayFamily,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    height: 1.05,
    fontFeatures: _tabular,
  );

  /// A row's amount: app.css `.lk-amount`, Fredoka 14px 600, tabular figures. The web's
  /// `white-space: nowrap` is the widget's (`softWrap: false`), not the style's.
  static const amount = TextStyle(
    fontFamily: displayFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: _inherited,
    fontFeatures: _tabular,
  );

  /// A sheet's title: apps/web/app/ui/Sheet.tsx `font-display text-[24px] leading-[1.15]
  /// font-bold`, Fredoka 24px 700.
  static const title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  /// Running text: ConfirmSheet.tsx `text-[15px]` on the body's 700 (app.css `body`), Nunito.
  static const body = TextStyle(
    fontFamily: textFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: _inherited,
  );

  /// A row's title: app.css `.lk-rowtop`, Nunito 13px 800.
  static const label = TextStyle(
    fontFamily: textFamily,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    height: _inherited,
  );

  /// A row's status line: app.css `.lk-status`, Nunito 11px 800.
  static const caption = TextStyle(
    fontFamily: textFamily,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: _inherited,
  );

  /// A day header: app.css `.lk-overline`, Nunito 11px 900, `letter-spacing: 0.07em` (0.77 px at
  /// 11px) and upper case: run the text through [upperCase], Flutter has no `text-transform`.
  static const eyebrow = TextStyle(
    fontFamily: textFamily,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.07 * 11,
    height: _inherited,
  );

  /// A button's label: app.css `.lk-btn`, Fredoka 16px 700, `letter-spacing: 0.05em` (0.8 px),
  /// upper case ([upperCase]) and the 1.5 line height `font: inherit` takes from the page. The web
  /// centres the half-leading, which `leadingDistribution: even` does here.
  static const button = TextStyle(
    fontFamily: displayFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.05 * 16,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// A small button's label: app.css `.lk-btn-sm`, [button] at 13px (letter spacing 0.05em of it).
  static const buttonSm = TextStyle(
    fontFamily: displayFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.05 * 13,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The "Pendiente" badge: app.css `.lk-badge`, Nunito 9.5px 900, `letter-spacing: 0.06em`
  /// (0.57 px), upper case.
  static const badge = TextStyle(
    fontFamily: textFamily,
    fontSize: 9.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.06 * 9.5,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// A category chip's name: app.css `.lk-chip`, Nunito 10px 800.
  static const chip = TextStyle(
    fontFamily: textFamily,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The note under a chip's name: CategoryChip.tsx `text-[9px]` on the chip's weight, 800.
  static const chipNote = TextStyle(
    fontFamily: textFamily,
    fontSize: 9,
    fontWeight: FontWeight.w800,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The glyph in a chip's tile: app.css `.lk-chip-tile`, 20px.
  static const chipGlyph = TextStyle(
    fontFamily: textFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// A segmented control's option: app.css `.lk-seg button`, Nunito 12px 900.
  static const segment = TextStyle(
    fontFamily: textFamily,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The month picker's arrows: app.css `.lk-step`, Fredoka 18px 700.
  static const step = TextStyle(
    fontFamily: displayFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: _inherited,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The month picker's name: MonthPicker.tsx `font-display text-lg font-semibold`, Fredoka 18px
  /// 600 on Tailwind's `text-lg` line height (28 px).
  static const monthName = TextStyle(
    fontFamily: displayFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Lukitas' speech bubble: app.css `.lk-bubble`, Nunito 12px 800, line height 1.35.
  static const bubble = TextStyle(
    fontFamily: textFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.35,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// `text-transform: uppercase`, for [eyebrow], [button], [buttonSm] and [badge].
  static String upperCase(String text) => text.toUpperCase();
}
