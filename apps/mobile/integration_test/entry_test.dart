// On an Android emulator against the dev stack (`docker compose up -d` at the repo root: API,
// Postgres, Mailpit), as docs/mobile/setup.md describes:
//
//   flutter test integration_test -d emulator-5554 \
//     --dart-define=LUKITAS_SERVER=http://10.0.2.2:3000 \
//     --dart-define=MAILPIT_URL=http://10.0.2.2:8025
//
// The emulator reaches the Mac at 10.0.2.2. Buttons are found by key: the emulator's language
// decides the copy (the widget tests check the Spanish and English words).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/main.dart' as app;

const _server = String.fromEnvironment('LUKITAS_SERVER', defaultValue: 'http://10.0.2.2:3000');
const _mailpit = String.fromEnvironment('MAILPIT_URL', defaultValue: 'http://10.0.2.2:8025');

/// The host App Links are declared for in the manifest.
const _appLinkHost = 'app-lukas.andersonlaverde.com';

final _http = Dio(BaseOptions(validateStatus: (_) => true));

/// A new address per call, so each test is a new user with its own email throttle.
String _freshEmail(String label) =>
    '$label-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}@lukas.test';

/// Pumps until [finder] finds something (network calls run in real time here).
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _tap(WidgetTester tester, String key) async {
  await _pumpUntil(tester, find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
}

/// The newest email to [email] in Mailpit, waiting for it: its subject and plain text.
Future<({String subject, String text})> _mailTo(String email) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(end)) {
    final list = await _http.get<Map<String, dynamic>>('$_mailpit/api/v1/messages?limit=100');
    final messages = (list.data?['messages'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where(
          (m) => (m['To'] as List<dynamic>).any(
            (to) => (to as Map<String, dynamic>)['Address'].toString().toLowerCase() == email,
          ),
        );
    if (messages.isNotEmpty) {
      final message = messages.first;
      final detail = await _http.get<Map<String, dynamic>>(
        '$_mailpit/api/v1/message/${message['ID']}',
      );
      return (subject: message['Subject'] as String, text: detail.data?['Text'] as String? ?? '');
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw TestFailure('No email to $email in Mailpit');
}

String _codeFrom(String subject) => RegExp(r'(\d{6})$').firstMatch(subject)!.group(1)!;

/// `GET /v1/me` with the token the app stored.
Future<Map<String, dynamic>> _me() async {
  final stored = await SessionStore().read();
  expect(stored, isNotNull, reason: 'the app stored a session');
  final res = await _http.get<Map<String, dynamic>>(
    '$_server/api/v1/me',
    options: Options(headers: {'Authorization': 'Bearer ${stored!.token}'}),
  );
  expect(res.statusCode, 200);
  return res.data!;
}

Future<void> _startApp(WidgetTester tester) async {
  await SessionStore().clear();
  await tester.pumpWidget(await app.bootstrap());
  await _pumpUntil(tester, find.byKey(const Key('entry.withEmail')));
}

Future<void> _sendCodeTo(WidgetTester tester, String email) async {
  await _tap(tester, 'entry.withEmail');
  await _pumpUntil(tester, find.byKey(const Key('entry.email')));
  await tester.enterText(find.byKey(const Key('entry.email')), email);
  await _tap(tester, 'entry.send');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Probar sin correo creates a guest and lands on home', (tester) async {
    await _startApp(tester);

    await _tap(tester, 'entry.guest');
    await _pumpUntil(tester, find.byType(HomeScreen));

    expect((await SessionStore().read())?.guest, isTrue);
    final me = await _me();
    expect(me['isAnonymous'], isTrue);
    // The guest's profile starts from the phone's time zone (x-lukas-timezone).
    final zone = await const MethodChannel('lukitas/device').invokeMethod<String>('timeZone');
    expect(me['timezone'], zone);
  });

  testWidgets('the email code signs in', (tester) async {
    final email = _freshEmail('mobile-code');
    await _startApp(tester);

    await _sendCodeTo(tester, email);
    await _pumpUntil(tester, find.byKey(const Key('entry.code')));
    final mail = await _mailTo(email);
    await tester.enterText(find.byKey(const Key('entry.code')), _codeFrom(mail.subject));
    await _tap(tester, 'entry.submitCode');
    await _pumpUntil(tester, find.byType(HomeScreen));

    final me = await _me();
    expect(me['email'], email);
    expect(me['isAnonymous'], isFalse);
  });

  testWidgets('opening the magic link in the app signs in', (tester) async {
    final email = _freshEmail('mobile-link');
    await _startApp(tester);
    await _sendCodeTo(tester, email);
    await _pumpUntil(tester, find.byKey(const Key('entry.code')));

    // The dev stack writes links to its web origin; the app's App Links are for the install's
    // host, so the same query is opened there, as Android delivers it: an ACTION_VIEW intent.
    final mail = await _mailTo(email);
    final link = Uri.parse(
      RegExp(r'https?://\S+/auth/verify\?\S+').firstMatch(mail.text)!.group(0)!,
    );
    final appLink = Uri(
      scheme: 'https',
      host: _appLinkHost,
      path: '/auth/verify',
      query: link.query,
    );
    await const MethodChannel('lukitas/test').invokeMethod<void>('openLink', appLink.toString());
    await _pumpUntil(tester, find.byType(HomeScreen));

    final me = await _me();
    expect(me['email'], email);
  });

  testWidgets('a guest saves their progress by claiming an email: same user, no longer a guest', (
    tester,
  ) async {
    final email = _freshEmail('mobile-claim');
    await _startApp(tester);
    await _tap(tester, 'entry.guest');
    await _pumpUntil(tester, find.byType(HomeScreen));
    final guest = await _me();
    final guestToken = (await SessionStore().read())!.token;

    // "Guarda tu progreso" (Task 14) will lead here; until then the route is opened directly.
    GoRouter.of(tester.element(find.byType(HomeScreen))).go('/entry/email');
    await _pumpUntil(tester, find.byKey(const Key('entry.email')));
    await tester.enterText(find.byKey(const Key('entry.email')), email);
    await _tap(tester, 'entry.send');
    await _tap(tester, 'guest.save');
    await _pumpUntil(tester, find.byKey(const Key('entry.code')));

    final mail = await _mailTo(email);
    await tester.enterText(find.byKey(const Key('entry.code')), _codeFrom(mail.subject));
    await _tap(tester, 'entry.submitCode');
    await _pumpUntil(tester, find.byType(HomeScreen));

    final stored = await SessionStore().read();
    expect(stored?.token, guestToken);
    expect(stored?.guest, isFalse);
    final me = await _me();
    expect(me['id'], guest['id']);
    expect(me['email'], email);
    expect(me['isAnonymous'], isFalse);
  });
}
