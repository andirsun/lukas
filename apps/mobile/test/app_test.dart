import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/app.dart';
import 'package:lukitas/theme/tokens.g.dart';

import 'entry/fakes.dart';

void main() {
  testWidgets('a smoke widget test renders the app shell in night theme when the phone is dark', (
    tester,
  ) async {
    // Signed out, on the real providers: the first-run screen.
    mockStorage();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const ProviderScope(child: LukitasApp()));
    await tester.pumpAndSettle();

    expect(find.text('Lukitas'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, LukitasTokens.night.bg);
    expect(theme.colorScheme.primary, LukitasTokens.night.brand);
  });

  testWidgets('the theme follows the phone by default: a light phone gets day', (tester) async {
    mockStorage();
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const ProviderScope(child: LukitasApp()));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, LukitasTokens.day.bg);
  });
}
