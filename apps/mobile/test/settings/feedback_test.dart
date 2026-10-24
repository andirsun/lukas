// "Comentarios e ideas" in Settings (apps/web/app/features/settings/FeedbackSection.tsx): a button
// that opens the email app with a message to the founder, and, where no email app answers, the
// address with a button to copy it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/settings/feedback.dart';

import 'harness.dart';

Finder _said(String text) => find.bySemanticsLabel(text);

Future<SettingsEnv> _pump(
  WidgetTester t, {
  Locale locale = const Locale('es'),
  bool guest = false,
}) async {
  final env = await pumpSettingsApp(
    t,
    locale: locale,
    guest: guest,
    overrides: [appVersionProvider.overrideWith((ref) async => '1.2.3')],
  );
  env.router.go('/settings');
  await t.pumpAndSettle();
  return env;
}

Future<void> _scrollTo(WidgetTester t, String key) async {
  await t.scrollUntilVisible(find.byKey(Key(key)), 200, scrollable: find.byType(Scrollable).first);
  await t.pumpAndSettle();
}

void main() {
  group('the link', () {
    // The web's tests pin the same strings (apps/web/app/features/settings/feedback.test.ts).
    test('is the founder\'s address with the subject and body percent-encoded', () {
      expect(feedbackEmail, 'lukitas@andersonlaverde.com');
      expect(
        feedbackMailto(subject: 'Lukitas: comentarios', body: '\n\nVersión: 1.2.3\nIdioma: es'),
        'mailto:lukitas@andersonlaverde.com?subject=Lukitas%3A%20comentarios&body=%0A%0AVersi%C3%B3n%3A%201.2.3%0AIdioma%3A%20es',
      );
    });

    test('encodes what could end the query early or start another header', () {
      final link = feedbackMailto(subject: 'a&b=c', body: 'x?y#z&cc=someone@else.com');
      expect(
        link,
        'mailto:lukitas@andersonlaverde.com?subject=a%26b%3Dc&body=x%3Fy%23z%26cc%3Dsomeone%40else.com',
      );
      expect(Uri.parse(link).queryParameters.containsKey('cc'), isFalse);
    });
  });

  group('the card', () {
    testWidgets('is the web\'s, between "Tus datos" and deleting the account', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t);
      await _scrollTo(t, 'settings.feedback');
      expect(_said('Comentarios e ideas'), findsWidgets);
      expect(
        _said('¿Algo no funciona, o quieres que Lukitas haga algo más? Cuéntanos por correo.'),
        findsOneWidget,
      );
      expect(find.text('ESCRIBIRNOS'), findsOneWidget);
      expect(
        _said('Si no se abre tu correo, escribe a lukitas@andersonlaverde.com.'),
        findsOneWidget,
      );
      final data = t.getTopLeft(find.byKey(const Key('settings.card.data'))).dy;
      final feedback = t.getTopLeft(find.byKey(const Key('settings.card.feedback'))).dy;
      final delete = t.getTopLeft(find.byKey(const Key('settings.card.delete'))).dy;
      expect(data < feedback && feedback < delete, isTrue);
      handle.dispose();
    });

    testWidgets('is in English, with the web\'s English', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t, locale: const Locale('en'));
      await _scrollTo(t, 'settings.feedback');
      expect(_said('Feedback and ideas'), findsWidgets);
      expect(find.text('WRITE TO US'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a guest has it too: it needs no account', (t) async {
      final env = await _pump(t, guest: true);
      await _scrollTo(t, 'settings.feedback');
      await t.tap(find.byKey(const Key('settings.feedback')));
      await t.pumpAndSettle();
      expect(env.opener.opened, hasLength(1));
    });
  });

  group('the button', () {
    testWidgets(
      'opens the exact mailto: Spanish subject, and only the version and language in the body',
      (t) async {
        final env = await _pump(t);
        await _scrollTo(t, 'settings.feedback');
        await t.tap(find.byKey(const Key('settings.feedback')));
        await t.pumpAndSettle();
        expect(
          env.opener.opened.single.toString(),
          'mailto:lukitas@andersonlaverde.com?subject=Lukitas%3A%20comentarios'
          '&body=%0A%0AVersi%C3%B3n%20de%20Lukitas%3A%201.2.3%0AIdioma%3A%20es',
        );
        // Decoded, the body is those two lines and nothing of the account: no email, no token.
        final body = Uri.parse(env.opener.opened.single.toString()).queryParameters['body'];
        expect(body, '\n\nVersión de Lukitas: 1.2.3\nIdioma: es');
        expect(body, isNot(contains('@')));
        expect(body, isNot(contains('token')));
        // Nothing else is shown: the email app took it.
        expect(find.byKey(const Key('settings.feedback.sheet')), findsNothing);
      },
    );

    testWidgets('in English the subject and the body speak English', (t) async {
      final env = await _pump(t, locale: const Locale('en'));
      await _scrollTo(t, 'settings.feedback');
      await t.tap(find.byKey(const Key('settings.feedback')));
      await t.pumpAndSettle();
      expect(
        env.opener.opened.single.toString(),
        'mailto:lukitas@andersonlaverde.com?subject=Lukitas%3A%20feedback'
        '&body=%0A%0ALukitas%20version%3A%201.2.3%0ALanguage%3A%20en',
      );
    });

    testWidgets('a phone that cannot say its version still writes, with "dev"', (t) async {
      final env = await pumpSettingsApp(
        t,
        overrides: [appVersionProvider.overrideWith((ref) async => throw StateError('no channel'))],
      );
      env.router.go('/settings');
      await t.pumpAndSettle();
      await _scrollTo(t, 'settings.feedback');
      await t.tap(find.byKey(const Key('settings.feedback')));
      await t.pumpAndSettle();
      expect(
        Uri.parse(env.opener.opened.single.toString()).queryParameters['body'],
        '\n\nVersión de Lukitas: dev\nIdioma: es',
      );
    });
  });

  group('with no email app', () {
    String? clipboard;

    setUp(() {
      clipboard = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
    });
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    testWidgets('shows the address, with a button that copies it', (t) async {
      final handle = t.ensureSemantics();
      final env = await _pump(t);
      env.opener.works = false;
      await _scrollTo(t, 'settings.feedback');
      await t.tap(find.byKey(const Key('settings.feedback')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('settings.feedback.sheet')), findsOneWidget);
      expect(find.text('No encontramos una app de correo'), findsOneWidget);
      expect(_said('Escríbenos a lukitas@andersonlaverde.com.'), findsOneWidget);
      await t.tap(find.byKey(const Key('settings.feedback.copy')));
      await t.pumpAndSettle();
      expect(clipboard, 'lukitas@andersonlaverde.com');
      expect(find.byKey(const Key('settings.feedback.sheet')), findsNothing);
      expect(find.text('Copiamos lukitas@andersonlaverde.com.'), findsOneWidget);
      await t.pump(const Duration(seconds: 10));
      handle.dispose();
    });

    testWidgets('can be closed without copying', (t) async {
      final env = await _pump(t);
      env.opener.works = false;
      await _scrollTo(t, 'settings.feedback');
      await t.tap(find.byKey(const Key('settings.feedback')));
      await t.pumpAndSettle();
      await t.tap(find.text('CERRAR'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('settings.feedback.sheet')), findsNothing);
      expect(clipboard, isNull);
    });
  });
}
