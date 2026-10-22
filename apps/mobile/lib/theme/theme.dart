import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// The design system's colours for the current theme, as a [ThemeExtension]:
/// `Theme.of(context).extension<LukitasTheme>()!.colors.bgGlow`.
@immutable
class LukitasTheme extends ThemeExtension<LukitasTheme> {
  const LukitasTheme(this.colors);

  final LukitasColors colors;

  @override
  LukitasTheme copyWith({LukitasColors? colors}) => LukitasTheme(colors ?? this.colors);

  // Tokens are discrete per theme: the switch happens halfway through the animation.
  @override
  LukitasTheme lerp(LukitasTheme? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Material [ThemeData] built from the tokens of one theme.
ThemeData lukitasThemeData(LukitasColors c, Brightness brightness) {
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
    focusColor: c.focus,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    extensions: [LukitasTheme(c)],
  );
}

/// Night, the default theme.
final ThemeData nightTheme = lukitasThemeData(LukitasTokens.night, Brightness.dark);

/// Day.
final ThemeData dayTheme = lukitasThemeData(LukitasTokens.day, Brightness.light);
