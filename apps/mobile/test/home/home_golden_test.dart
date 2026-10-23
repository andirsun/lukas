@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fonts.dart';
import 'fakes.dart';
import 'home_harness.dart';

/// Home as a phone shows it, in the night theme (the default) and in the day theme.
///
/// Golden images are pixels from the machine that made them, so they are tagged `golden` and CI
/// (Linux) skips them (dart_test.yaml). Text is drawn with the app's bundled Fredoka and Nunito
/// (loadAppFonts), not the test font, so these catch typography as well as layout, colour and
/// spacing. Update with `flutter test --update-goldens --tags golden`.
Future<void> pumpGoldenHome(WidgetTester tester, ThemeMode mode, FakeHomeRepository repo) async {
  await pumpHome(tester, repo, themeMode: mode, settle: false);
  // The sprite sheets decode with the real engine, outside the test clock.
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    for (final sheet in ['wave', 'worried', 'celebrate']) {
      await precacheImage(AssetImage('assets/lukas/$sheet.webp'), context);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // The ＋, the 🎤 and the sheet's close button are Material icons: draw them, not boxes.
    await loadMaterialIcons();
  });

  testWidgets('home at night, with budgets', (tester) async {
    await pumpGoldenHome(tester, ThemeMode.dark, monthWithBudgets());
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_night.png'));
  });

  testWidgets('home by day, with budgets', (tester) async {
    await pumpGoldenHome(tester, ThemeMode.light, monthWithBudgets());
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_day.png'));
  });

  testWidgets('home at night, without budgets', (tester) async {
    await pumpGoldenHome(tester, ThemeMode.dark, monthWithBudgets()..budgetTotal = 0);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_night_no_budgets.png'),
    );
  });
}
