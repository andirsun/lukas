// Italian and Portuguese run 10-25% longer than Spanish: the app's screens, on a 360 px phone with
// the font at 130%, in each of them, draw without a layout overflow (the spec's German-length check).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings/harness.dart';

void main() {
  for (final (language, tag) in [('it', Locale('it', 'IT')), ('pt', Locale('pt', 'PT'))]) {
    for (final guest in [false, true]) {
      for (final location in [
        '/',
        '/settings',
        '/categories',
        '/settings/about',
        '/progress',
        '/recurring',
        '/insights',
        '/import',
      ]) {
        testWidgets(
          '$language${guest ? ' (guest)' : ''}: $location has no overflow at 360 px, text scale 1.3',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = 1.3;
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
            final env = await pumpSettingsApp(tester, guest: guest, locale: tag);
            tester.view
              ..physicalSize = const Size(360, 640)
              ..devicePixelRatio = 1;
            env.router.go(location);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              Localizations.localeOf(tester.element(find.byType(Scaffold).first)).languageCode,
              language,
            );
            expect(find.byType(Scaffold), findsWidgets);
          },
        );
      }
    }
    for (final button in ['home.add', 'home.capture']) {
      testWidgets('$language: the sheet of $button has no overflow at 360 px, text scale 1.3', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpSettingsApp(tester, locale: tag);
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(button)));
        // Something on the capture sheet keeps moving (a spinner): frames, not a settle.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
