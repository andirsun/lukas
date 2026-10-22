@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_sheet.dart';
import 'package:lukitas/home/home_screen.dart';

import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../home/home_harness.dart';
import 'fakes.dart';

/// The add sheet as a phone shows it, in the night theme (the default) and in the day theme, with
/// 25.000 typed and a few recent names. Golden images are pixels from the machine that made them,
/// so they are tagged `golden` and CI (Linux) skips them (dart_test.yaml). Update with
/// `flutter test --update-goldens --tags golden`.
Future<void> pumpSheet(WidgetTester tester, ThemeMode mode) async {
  final server = FakeHomeRepository(
    categoryList: [
      category('cat-groceries', 'Supermercado', icon: '🛒'),
      category('cat-home', 'Hogar', icon: '🏠', color: 'orange'),
      category('cat-fun', 'Ocio', icon: '🎬'),
      category('cat-salary', 'Nómina', kind: 'income', icon: '💰'),
    ],
    items: [
      for (final (i, name) in ['Café', 'Almuerzo', 'Cine', 'Taxi'].indexed)
        for (var n = 0; n < 4 - i; n++) tx('$name$n', '2026-10-2$i', -1000, name: name),
    ],
  );
  await pumpHome(tester, server, themeMode: mode, addRepo: FakeAddRepository(server));
  unawaited(openAddSheet(tester.element(find.byType(HomeScreen))));
  await tester.pumpAndSettle();
  for (final key in '25000'.split('')) {
    await tester.tap(find.byKey(Key('keypad.$key')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the add sheet at night', (tester) async {
    await pumpSheet(tester, ThemeMode.dark);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_night.png'));
  });

  testWidgets('the add sheet by day', (tester) async {
    await pumpSheet(tester, ThemeMode.light);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/add_day.png'));
  });
}
