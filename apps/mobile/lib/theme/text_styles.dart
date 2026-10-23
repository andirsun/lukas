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

  /// `text-transform: uppercase`, for [eyebrow].
  static String upperCase(String text) => text.toUpperCase();
}
