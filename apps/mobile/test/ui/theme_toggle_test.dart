import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/settings/preferences.dart';
import 'package:lukitas/theme/theme.dart';
import 'package:lukitas/ui/theme_toggle.dart';

import '../support/ui_app.dart';

/// The web's ThemeToggle: a moon at night and a sun by day, named for what a press does.
void main() {
  Future<ProviderContainer> pump(WidgetTester tester, ThemeData theme, {Locale? locale}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: uiApp(
          theme: theme,
          locale: locale ?? const Locale('es'),
          const Align(alignment: Alignment.topLeft, child: ThemeToggle()),
        ),
      ),
    );
    return container;
  }

  testWidgets('at night it offers day', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, nightTheme);
    expect(find.bySemanticsLabel('Cambiar a modo día'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('by day it offers night', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, dayTheme);
    expect(find.bySemanticsLabel('Cambiar a modo noche'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('in English', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, nightTheme, locale: const Locale('en'));
    expect(find.bySemanticsLabel('Switch to day mode'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a press at night keeps day', (tester) async {
    final container = await pump(tester, nightTheme);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await tester.tap(find.byType(ThemeToggle));
    await tester.pump();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('a press by day keeps night', (tester) async {
    final container = await pump(tester, dayTheme);

    await tester.tap(find.byType(ThemeToggle));
    await tester.pump();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('it is a 44px target', (tester) async {
    await pump(tester, nightTheme);
    expect(tester.getSize(find.byType(ThemeToggle)), const Size(44, 44));
  });
}
