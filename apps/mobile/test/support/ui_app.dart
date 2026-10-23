import 'package:flutter/material.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/theme/theme.dart';

/// A component in the app's theme and copy, for the behaviour tests of `lib/ui` (how each looks is
/// test/parity's job). [width] is the phone's width in logical pixels; [textScale] the system's
/// font size (1.3 is "130%"); [disableAnimations] the system's "remove animations".
Widget uiApp(
  Widget child, {
  Locale locale = const Locale('es'),
  double width = 412,
  double textScale = 1,
  bool disableAnimations = false,
  ThemeData? theme,
}) => MaterialApp(
  theme: theme ?? nightTheme,
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  debugShowCheckedModeBanner: false,
  builder: (context, home) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: disableAnimations),
    child: home!,
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);
