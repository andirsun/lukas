import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.g.dart';

/// The design tokens of the current theme, for the web's components ported to `lib/ui`.
extension LkThemeContext on BuildContext {
  /// The theme's colours and edge shadows (`Theme.of(context).extension<LukitasTheme>()!`).
  LukitasTheme get lk => Theme.of(this).extension<LukitasTheme>()!;

  /// The theme's colours.
  LukitasColors get lkColors => lk.colors;
}

/// Where Blink starts a text with a letter spacing of [spacing]: half the spacing in from the left
/// (it puts half of a letter spacing before a glyph and half after it; Flutter puts all of it
/// after, so Flutter's glyphs sit half a spacing to the left of the web's), cut to a quarter of a
/// device pixel, the grid Skia places glyphs on, and a hair under that step: a glyph exactly on
/// a step is drawn on the next one in Flutter's tests, a hair under it on the same one as in
/// Chrome. Translate the text by it.
double letterSpacingShift(BuildContext context, double spacing) {
  final ratio = MediaQuery.devicePixelRatioOf(context);
  return ((spacing / 2 * ratio * 4).floor() - 0.15) / 4 / ratio;
}

final _baselineShifts = <(String?, double?, FontWeight?, double?), double>{};

/// How far Flutter draws a line of [style] above or below where Blink does (positive: lower in
/// Blink): Blink rounds the font's ascent and descent to whole pixels and floors the half-leading
/// when it places the baseline in a line box taller than the text; Flutter keeps the fractions.
/// [style] needs a `height` and `leadingDistribution: even`, which the web's line heights are.
double cssBaselineShift(TextStyle style) {
  final key = (style.fontFamily, style.fontSize, style.fontWeight, style.height);
  return _baselineShifts.putIfAbsent(key, () {
    final painter = TextPainter(
      text: TextSpan(
        text: 'x',
        style: TextStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final ascent = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final descent = painter.height - ascent;
    painter.dispose();
    final lineHeight = style.fontSize! * style.height!;
    final blink =
        ascent.roundToDouble() +
        ((lineHeight - ascent.roundToDouble() - descent.roundToDouble()) / 2).floorToDouble();
    final flutter = (lineHeight - ascent - descent) / 2 + ascent;
    return blink - flutter;
  });
}

/// [child] (a line of text in [style]) moved to where Blink puts its baseline: see
/// [cssBaselineShift]. The move is a paint offset; the line keeps its place in the layout.
class BlinkLine extends StatelessWidget {
  const BlinkLine({super.key, required this.style, required this.child});

  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Transform.translate(offset: Offset(0, cssBaselineShift(style)), child: child);
}
