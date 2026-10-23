import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/notices/notice_backend.dart';
import 'package:lukitas/notices/notice_platform.dart';

import '../settings/harness.dart';
import 'fakes.dart';

void main() {
  /// The app with the real dialog, and a platform that has not been asked yet.
  Future<(SettingsEnv, FakeNoticePlatform)> pump(
    WidgetTester tester, {
    bool guest = false,
    bool hasRecurring = true,
    Locale locale = const Locale('es'),
    bool systemAnswer = true,
  }) async {
    final platform = FakeNoticePlatform(systemAnswer: systemAnswer);
    final env = await pumpSettingsApp(
      tester,
      guest: guest,
      locale: locale,
      overrides: [
        noticePlatformProvider.overrideWithValue(platform),
        noticeBackendProvider.overrideWithValue(FakeNoticeBackend(hasRecurring: hasRecurring)),
      ],
    );
    // The question stays on screen until it is answered, so no waiting for the sync to be idle.
    await tester.pumpAndSettle();
    return (env, platform);
  }

  testWidgets('one sentence on why, in the app, before Android\'s own prompt', (tester) async {
    final (_, platform) = await pump(tester);
    expect(find.byKey(const Key('notices.ask')), findsOneWidget);
    expect(find.byKey(const Key('notices.askWhy')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('notices.askWhy'))).data,
      'Así Lukitas puede avisarte a las 9:00 los días en que vence un pago recurrente.',
    );
    expect(platform.callsNamed('requestPermission'), isEmpty, reason: 'Android is asked after "Permitir"');

    await tester.tap(find.byKey(const Key('notices.askAllow')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notices.ask')), findsNothing);
    expect(platform.callsNamed('requestPermission'), hasLength(1));
  });

  testWidgets('"Ahora no" asks Android nothing and closes', (tester) async {
    final (_, platform) = await pump(tester);
    await tester.tap(find.byKey(const Key('notices.askLater')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notices.ask')), findsNothing);
    expect(platform.callsNamed('requestPermission'), isEmpty);
  });

  testWidgets('for a guest, the sentence is about the warning', (tester) async {
    await pump(tester, guest: true, hasRecurring: false);
    expect(
      tester.widget<Text>(find.byKey(const Key('notices.askWhy'))).data,
      'Así Lukitas puede avisarte si pasan 45 días sin abrirlo y tu cuenta no tiene correo, antes de que se borren tus datos.',
    );
  });

  testWidgets('in English', (tester) async {
    await pump(tester, locale: const Locale('en'));
    expect(
      tester.widget<Text>(find.byKey(const Key('notices.askWhy'))).data,
      'So Lukitas can tell you at 9:00 on the days a recurring payment is due.',
    );
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Allow notices'), findsOneWidget);
  });
}
