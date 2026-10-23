import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/app.dart';
import 'package:lukitas/api/server_url.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/settings/initial_settings.dart';
import 'package:lukitas/theme/tokens.g.dart';

import 'entry/fakes.dart';

void main() {
  testWidgets('night is the default theme, even on a light phone', (tester) async {
    // Signed out, on the real providers: the first-run screen.
    mockStorage();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const ProviderScope(child: LukitasApp()));
    await tester.pumpAndSettle();

    expect(find.text('Lukitas'), findsOneWidget);

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, LukitasTokens.night.bg);
    expect(theme.colorScheme.primary, LukitasTokens.night.brand);
  });

  testWidgets('"System" follows the phone: a light phone gets day', (tester) async {
    mockStorage();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(
            InitialSettings(serverUrl: defaultServerUrl, themeMode: ThemeMode.system),
          ),
        ],
        child: const LukitasApp(),
      ),
    );
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, LukitasTokens.day.bg);
  });

  testWidgets('the language follows the phone when it is Spanish or English, else Spanish', (
    tester,
  ) async {
    mockStorage();
    Future<String> wordsFor(Locale locale) async {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const ProviderScope(child: LukitasApp()));
      await tester.pumpAndSettle();
      return AppLocalizations.of(tester.element(find.byType(Scaffold))).localeName;
    }

    expect(await wordsFor(const Locale('en', 'GB')), 'en');
    expect(await wordsFor(const Locale('es', 'CO')), 'es');
    expect(await wordsFor(const Locale('fr')), 'es');
  });
}
