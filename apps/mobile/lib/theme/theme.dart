import 'package:flutter/material.dart';

import 'text_styles.dart';
import 'tokens.g.dart';

/// The design system's colours and shadows for the current theme, as a [ThemeExtension]:
/// `Theme.of(context).extension<LukitasTheme>()!.colors.bgGlow`.
@immutable
class LukitasTheme extends ThemeExtension<LukitasTheme> {
  const LukitasTheme(this.colors, this.shadows);

  /// Night, the default theme.
  static const night = LukitasTheme(LukitasColors.night, LukitasShadows.night);

  /// Day.
  static const day = LukitasTheme(LukitasColors.day, LukitasShadows.day);

  final LukitasColors colors;

  /// The `shadow-edge-*` tokens of the theme (see lib/theme/surfaces.dart).
  final LukitasShadows shadows;

  @override
  LukitasTheme copyWith({LukitasColors? colors, LukitasShadows? shadows}) =>
      LukitasTheme(colors ?? this.colors, shadows ?? this.shadows);

  // Tokens are discrete per theme: the switch happens halfway through the animation.
  @override
  LukitasTheme lerp(LukitasTheme? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Material's text styles in Nunito at the weight of the web's body, 700 (app.css:50-56: the body
/// is `font-family: var(--font-text); font-weight: 700`), so text the app does not style itself
/// reads as the web's does, in the theme's own ink (`body { color: var(--ink) }`, app.css:50-56),
/// not in a colour Material's typography picks for black or white. Sizes stay Material's: screens
/// set theirs with [LkText].
TextTheme _webTextTheme(LukitasColors colors) {
  // Only the sizes, spacing and heights of Material's styles are kept: the colour is the ink's.
  final base = Typography.material2021().black;
  TextStyle? web(TextStyle? style) => style?.copyWith(
    fontFamily: LkText.textFamily,
    fontWeight: FontWeight.w700,
    color: colors.ink,
    // The web's text has no letter spacing but the one a style asks for (Material's own styles
    // carry 0.25 to 0.5 px, which would widen every line inside a Material).
    letterSpacing: 0,
  );
  return TextTheme(
    displayLarge: web(base.displayLarge),
    displayMedium: web(base.displayMedium),
    displaySmall: web(base.displaySmall),
    headlineLarge: web(base.headlineLarge),
    headlineMedium: web(base.headlineMedium),
    headlineSmall: web(base.headlineSmall),
    titleLarge: web(base.titleLarge),
    titleMedium: web(base.titleMedium),
    titleSmall: web(base.titleSmall),
    bodyLarge: web(base.bodyLarge),
    bodyMedium: web(base.bodyMedium),
    bodySmall: web(base.bodySmall),
    labelLarge: web(base.labelLarge),
    labelMedium: web(base.labelMedium),
    labelSmall: web(base.labelSmall),
  );
}

/// Material [ThemeData] built from the tokens of one theme.
ThemeData lukitasThemeData(LukitasTheme tokens, Brightness brightness) {
  final c = tokens.colors;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.brand,
    onPrimary: c.onBrand,
    secondary: c.gold,
    onSecondary: c.onGold,
    tertiary: c.candy,
    onTertiary: c.onBrand,
    error: c.over,
    onError: c.onBrand,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    surfaceContainerLowest: c.surfaceSunken,
    surfaceContainerLow: c.surfaceRow,
    surfaceContainer: c.surface,
    outline: c.controlEdge,
    outlineVariant: c.stroke,
    shadow: c.surfaceEdge,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    fontFamily: LkText.textFamily,
    textTheme: _webTextTheme(c),
    focusColor: c.focus,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    extensions: [tokens],
  );
}

/// Night, the default theme.
final ThemeData nightTheme = lukitasThemeData(LukitasTheme.night, Brightness.dark);

/// Day.
final ThemeData dayTheme = lukitasThemeData(LukitasTheme.day, Brightness.light);
