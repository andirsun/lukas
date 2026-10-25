import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/ui/month_picker.dart';

import '../insights/insights_test.dart' show pumpInsights, testInsights;

/// The bottom bar means the same on every screen (the web's `BottomBar`: Inicio is `/app`, home on
/// the current month; Análisis is `/app/insights`; the pages the bar has no tab for mark none).
/// Home is under each screen here, as it is when the person got there from it.

Finder picker(String name) =>
    find.descendant(of: find.byType(MonthPicker), matching: find.text(name));

Future<void> tapBar(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

/// Home on September, which is not the current month (October).
Future<dynamic> pumpHomeOnSeptember(WidgetTester tester) async {
  final env = await pumpInsights(tester);
  await tester.tap(find.bySemanticsLabel('Mes anterior'));
  await tester.pumpAndSettle();
  expect(picker('Septiembre'), findsOneWidget);
  return env;
}

void main() {
  group('Inicio goes to home on the current month from every screen', () {
    testInsights('from Análisis, even after stepping Análisis to another month', (tester) async {
      await pumpHomeOnSeptember(tester);
      await tapBar(tester, 'Análisis');
      expect(picker('Septiembre'), findsOneWidget, reason: 'Análisis opens on home\'s month');
      await tester.tap(find.bySemanticsLabel('Mes anterior'));
      await tester.pumpAndSettle();
      expect(picker('Agosto'), findsOneWidget);

      await tapBar(tester, 'Inicio');
      expect(find.text('Análisis').evaluate().length, lessThanOrEqualTo(1)); // only the bar's
      expect(picker('Octubre'), findsOneWidget);
    });

    testInsights('from Ajustes and from Acerca de, the same', (tester) async {
      final env = await pumpHomeOnSeptember(tester);
      unawaited0(env.settings.router.push('/settings'));
      await tester.pumpAndSettle();
      await tapBar(tester, 'Inicio');
      expect(picker('Octubre'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Mes anterior'));
      await tester.pumpAndSettle();
      expect(picker('Septiembre'), findsOneWidget);
      unawaited0(env.settings.router.push('/settings'));
      await tester.pumpAndSettle();
      unawaited0(env.settings.router.push('/settings/about'));
      await tester.pumpAndSettle();
      await tapBar(tester, 'Inicio');
      expect(picker('Octubre'), findsOneWidget);
      expect(env.settings.router.canPop(), isFalse, reason: 'home is the only screen left');
    });

    testInsights('from a category\'s detail, the same', (tester) async {
      final env = await pumpHomeOnSeptember(tester);
      unawaited0(env.settings.router.push('/categories/cat-home?month=2026-09'));
      await tester.pumpAndSettle();
      await tapBar(tester, 'Inicio');
      expect(picker('Octubre'), findsOneWidget);
      expect(env.settings.router.canPop(), isFalse);
    });
  });

  group('Análisis opens on the month the screen shows, or home\'s', () {
    testInsights('from Ajustes and from Acerca de: home\'s month', (tester) async {
      final env = await pumpHomeOnSeptember(tester);
      unawaited0(env.settings.router.push('/settings'));
      await tester.pumpAndSettle();
      await tapBar(tester, 'Análisis');
      expect(picker('Septiembre'), findsOneWidget);
      env.settings.router.pop();
      await tester.pumpAndSettle();

      unawaited0(env.settings.router.push('/settings/about'));
      await tester.pumpAndSettle();
      await tapBar(tester, 'Análisis');
      expect(picker('Septiembre'), findsOneWidget);
    });

    testInsights('from the detail: the detail\'s month', (tester) async {
      final env = await pumpHomeOnSeptember(tester);
      unawaited0(env.settings.router.push('/categories/cat-home?month=2026-08'));
      await tester.pumpAndSettle();
      await tapBar(tester, 'Análisis');
      expect(picker('Agosto'), findsOneWidget);
    });
  });

  testInsights('the detail\'s bar marks neither Inicio nor Análisis, as the web\'s', (
    tester,
  ) async {
    final env = await pumpInsights(tester);
    unawaited0(env.settings.router.push('/categories/cat-home'));
    await tester.pumpAndSettle();
    for (final label in ['Inicio', 'Análisis']) {
      expect(
        tester.getSemantics(find.text(label).last).flagsCollection.isSelected.name,
        isNot('isTrue'),
        reason: label,
      );
    }
  });
}

void unawaited0(Future<void> f) {}
