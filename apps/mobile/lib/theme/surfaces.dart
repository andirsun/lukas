import 'package:flutter/widgets.dart';

import 'theme.dart';
import 'tokens.g.dart';

/// Which of the web's `shadow-edge-*` utilities: `sm` for rows, chips and the month pill, `md` for
/// the hero card, keypad keys and option cards, `brand` for primary buttons and the ＋.
enum LkEdge { sm, md, brand }

/// The radii of tokens.css `--radius-*`.
enum LkRadius {
  sm(LukitasTokens.radiusSm),
  md(LukitasTokens.radiusMd),
  lg(LukitasTokens.radiusLg),
  xl(LukitasTokens.radiusXl),
  pill(LukitasTokens.radiusPill);

  const LkRadius(this.pixels);

  final double pixels;
}

/// The web's surfaces: the screen's background gradient, the solid bottom edges ("3D" shadows),
/// borders and radii, as app.css and tokens.css define them. Every helper takes the theme's
/// [LukitasTheme] (or its colours), so night and day follow the tokens.
abstract final class LkSurface {
  /// The screen background, app.css `.lk-screen`:
  /// `radial-gradient(120% 60% at 50% 0%, var(--bg-glow) 0%, var(--bg) 55%)`. An ellipse as wide
  /// as 120% of the screen and 60% as tall, centred on the top edge; never a flat fill.
  static Gradient background(LukitasColors colors) => RadialGradient(
    center: Alignment.topCenter,
    radius: 1,
    colors: [colors.bgGlow, colors.bg],
    stops: const [0, 0.55],
    transform: const _EllipseGradient(widthFactor: 1.2, heightFactor: 0.6),
  );

  /// The web's `shadow-edge-*`: a solid bottom edge (and, for `brand`, a soft glow).
  static List<BoxShadow> edgeShadow(LukitasTheme theme, LkEdge size) => switch (size) {
    LkEdge.sm => theme.shadows.edgeSm,
    LkEdge.md => theme.shadows.edgeMd,
    LkEdge.brand => theme.shadows.edgeBrand,
  };

  /// A pressed surface's edge, collapsed to 1px: app.css `.lk-press:active`, `.lk-row.is-pressed`
  /// (`box-shadow: 0 1px 0 var(--surface-edge)`). The surface itself moves down by the edge it
  /// lost (3px for [LkEdge.sm]).
  static List<BoxShadow> pressedEdge(LukitasTheme theme) => [
    BoxShadow(color: theme.colors.surfaceEdge, offset: const Offset(0, 1)),
  ];

  /// `--edge-brand` at rest, or its pressed `0 1px 0 var(--brand-edge)`, in Flutter's paint order.
  ///
  /// CSS paints the first shadow of a list on top, Flutter the last, so the list is reversed: the
  /// glow underneath, the solid edge over it. The pressed list keeps two entries (the glow gone, at
  /// no offset and no blur) so the two lists animate into each other shadow by shadow, as CSS does
  /// when it pads the shorter list.
  static List<BoxShadow> brandEdge(LukitasTheme theme, {required bool pressed}) {
    final [edge, glow] = theme.shadows.edgeBrand;
    if (!pressed) return [glow, edge];
    return [BoxShadow(color: glow.color), ...pressedBrandEdge(theme)];
  }

  /// A pressed primary button's edge: app.css `.lk-btn-primary:active`
  /// (`box-shadow: 0 1px 0 var(--brand-edge)`), the surface 5px down.
  static List<BoxShadow> pressedBrandEdge(LukitasTheme theme) => [
    BoxShadow(color: theme.colors.brandEdge, offset: const Offset(0, 1)),
  ];

  /// The sheet's backdrop: app.css `--scrim`, dark in both themes. Night mixes 72 % of
  /// `surface-edge` into nothing, day 40 % of `ink`.
  static Color scrim(LukitasColors colors, Brightness brightness) => brightness == Brightness.light
      ? colors.ink.withValues(alpha: 0.4)
      : colors.surfaceEdge.withValues(alpha: 0.72);

  /// The edge of a field that has no other cue (the sign-in code boxes), app.css `--field-edge`:
  /// 60 % of `ink-muted` over `surface-sunken` at night, 80 % by day (at least 3:1 against its own
  /// fill and the background, WCAG 1.4.11).
  static Color fieldEdge(LukitasColors colors, Brightness brightness) => Color.lerp(
    colors.surfaceSunken,
    colors.inkMuted,
    brightness == Brightness.light ? 0.8 : 0.6,
  )!;

  /// The corner radius of a token.
  static BorderRadius radius(LkRadius radius) => BorderRadius.circular(radius.pixels);

  /// The 2px `stroke` border of rows and cards: app.css `.lk-rowcard` (`border: 2px solid
  /// var(--stroke)`).
  static Border border(LukitasColors colors) => Border.all(color: colors.stroke, width: 2);

  /// A row card, app.css `.lk-rowcard`: `surface-row`, radius `lg`, the 2px stroke and `edge-sm`.
  static BoxDecoration rowCard(LukitasTheme theme) => BoxDecoration(
    color: theme.colors.surfaceRow,
    borderRadius: radius(LkRadius.lg),
    border: border(theme.colors),
    boxShadow: edgeShadow(theme, LkEdge.sm),
  );
}

/// Stretches a unit radial gradient into the ellipse CSS' `radial-gradient(W% H% at x y)` draws:
/// Flutter's [RadialGradient] is a circle whose radius is a fraction of the box's shortest side,
/// so the horizontal and vertical radii are scaled to [widthFactor] of the width and
/// [heightFactor] of the height, around the gradient's centre.
class _EllipseGradient extends GradientTransform {
  const _EllipseGradient({required this.widthFactor, required this.heightFactor});

  final double widthFactor;
  final double heightFactor;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final shortest = bounds.shortestSide;
    final centre = bounds.topCenter;
    return Matrix4.identity()
      ..translateByDouble(centre.dx, centre.dy, 0, 1)
      ..scaleByDouble(
        widthFactor * bounds.width / shortest,
        heightFactor * bounds.height / shortest,
        1,
        1,
      )
      ..translateByDouble(-centre.dx, -centre.dy, 0, 1);
  }
}
