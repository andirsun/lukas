import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/auth_api.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/router.dart';

import 'fakes.dart';

Future<void> _enterEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('entry.email')), email);
  await tester.tap(find.text('Enviar código'));
  await tester.pumpAndSettle();
}

Future<void> _enterCode(WidgetTester tester, String code, {String submit = 'Entrar'}) async {
  await tester.enterText(find.byKey(const Key('entry.code')), code);
  await tester.tap(find.widgetWithText(FilledButton, submit));
  await tester.pumpAndSettle();
}

StoredSession? _stored(ProviderContainer container) => container.read(sessionProvider).stored;

void main() {
  late FakeAuthApi auth;
  setUp(() {
    auth = FakeAuthApi();
    mockStorage();
  });

  group('first run', () {
    testWidgets('first run shows three choices; "Entrar con huella" is hidden when '
        'passkeysSupported is false', (tester) async {
      await pumpApp(tester, auth: auth, passkeys: FakePasskeys(isSupported: false));

      expect(find.text('Probar sin correo'), findsOneWidget);
      expect(find.text('Entrar con mi correo'), findsOneWidget);
      expect(find.text('Entrar con huella'), findsNothing);
    });

    testWidgets('with a passkey provider on the phone, all three choices show', (tester) async {
      await pumpApp(tester, auth: auth, passkeys: FakePasskeys(isSupported: true));

      expect(find.text('Probar sin correo'), findsOneWidget);
      expect(find.text('Entrar con mi correo'), findsOneWidget);
      expect(find.text('Entrar con huella'), findsOneWidget);
    });

    testWidgets('in English, the same three choices', (tester) async {
      await pumpApp(
        tester,
        auth: auth,
        passkeys: FakePasskeys(isSupported: true),
        locale: const Locale('en'),
      );

      expect(find.text('Try it without an email'), findsOneWidget);
      expect(find.text('Sign in with my email'), findsOneWidget);
      expect(find.text('Sign in with fingerprint'), findsOneWidget);
    });

    testWidgets('Probar sin correo creates a guest and lands on home', (tester) async {
      final container = await pumpApp(tester, auth: auth);

      await tester.tap(find.text('Probar sin correo'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['signInAsGuest']);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_stored(container)?.guest, isTrue);
      expect((await SessionStore().read())?.token, 'guest-token-1');
    });

    testWidgets('a closed guest sign-up says so and stays on the first screen', (tester) async {
      await pumpApp(tester, auth: auth);
      auth.failures['signInAsGuest'] = const AuthFailure(
        code: 'guest_signup_disabled',
        status: 403,
      );

      await tester.tap(find.text('Probar sin correo'));
      await tester.pumpAndSettle();

      expect(find.text('Por ahora no se pueden crear cuentas de invitado.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });

  group('email', () {
    testWidgets('the email code signs in', (tester) async {
      final container = await pumpApp(tester, auth: auth);

      await tester.tap(find.text('Entrar con mi correo'));
      await tester.pumpAndSettle();
      await _enterEmail(tester, ' Ana@Correo.com ');

      expect(auth.calls, ['sendCode ana@correo.com']);
      expect(find.text('Revisa tu correo'), findsOneWidget);

      await _enterCode(tester, '123456');

      expect(auth.calls.last, 'verifyCode ana@correo.com 123456');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_stored(container)?.guest, isFalse);
      expect((await SessionStore().read())?.token, 'email-token-1');
    });

    testWidgets('a not-allowlisted email shows "Lukitas todavía no está abierto al público…"', (
      tester,
    ) async {
      await pumpApp(tester, auth: auth);
      auth.failures['sendCode'] = const AuthFailure(code: 'sign_in_not_allowed', status: 403);

      await tester.tap(find.text('Entrar con mi correo'));
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'nadie@correo.com');

      expect(
        find.text(
          'Lukitas todavía no está abierto al público. Si quieres probarlo, escríbele a quien te '
          'invitó.',
        ),
        findsOneWidget,
      );
      expect(find.text('Revisa tu correo'), findsNothing);
    });

    testWidgets('a mistyped email is caught before asking the server', (tester) async {
      await pumpApp(tester, auth: auth);

      await tester.tap(find.text('Entrar con mi correo'));
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'ana@correo');

      expect(find.text('Escribe un correo válido, como ana@correo.com.'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('a wrong code says so and keeps the person on the code', (tester) async {
      await pumpApp(tester, auth: auth);
      await tester.tap(find.text('Entrar con mi correo'));
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'ana@correo.com');
      auth.failures['verifyCode'] = const AuthFailure(code: 'INVALID_OTP', status: 400);

      await _enterCode(tester, '000000');

      expect(
        find.text('Ese código no es correcto. Revísalo e inténtalo otra vez.'),
        findsOneWidget,
      );
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('no connection says so', (tester) async {
      await pumpApp(tester, auth: auth);
      auth.failures['sendCode'] = const AuthFailure(status: 0);

      await tester.tap(find.text('Entrar con mi correo'));
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'ana@correo.com');

      expect(find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'), findsOneWidget);
    });
  });

  group('magic link', () {
    testWidgets('opening the magic link in the app signs in', (tester) async {
      final container = await pumpApp(tester, auth: auth);

      container.read(routerProvider).go('/auth/verify?email=ana%40correo.com&code=654321&lang=es');
      await tester.pumpAndSettle();

      expect(auth.calls, ['verifyCode ana@correo.com 654321']);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(_stored(container)?.guest, isFalse);
    });

    testWidgets('a used link says so and offers a new code for that email', (tester) async {
      final container = await pumpApp(tester, auth: auth);
      auth.failures['verifyCode'] = const AuthFailure(code: 'INVALID_OTP', status: 400);

      container.read(routerProvider).go('/auth/verify?email=ana%40correo.com&code=654321');
      await tester.pumpAndSettle();

      expect(find.text('No pudimos hacerte entrar'), findsOneWidget);
      expect(
        find.text('Este código ya no sirve: venció o ya se usó. Pide uno nuevo.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Enviar un código nuevo'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byKey(const Key('entry.email'))).controller?.text,
        'ana@correo.com',
      );
    });
  });

  group('a guest choosing to enter with an email', () {
    setUp(() {
      mockStorage(token: 'guest-token-0', guest: true);
      auth.guests['guest-token-0'] = true;
    });

    Future<ProviderContainer> openEmail(WidgetTester tester) async {
      final container = await pumpApp(tester, auth: auth);
      auth.calls.clear();
      container.read(routerProvider).go('/entry/email');
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('is offered to save their progress, and claims the email in place', (tester) async {
      final container = await openEmail(tester);

      await _enterEmail(tester, 'ana@correo.com');

      // Nothing is sent before the person decides.
      expect(auth.calls.where((c) => c.startsWith('sendCode')), isEmpty);
      expect(find.text('¿Guardamos lo que ya anotaste?'), findsOneWidget);

      await tester.tap(find.text('Guardar mi progreso'));
      await tester.pumpAndSettle();
      expect(auth.calls, ['claimSend guest-token-0 ana@correo.com']);
      expect(find.text('Revisa tu correo'), findsOneWidget);

      await _enterCode(tester, '111222', submit: 'Guardar');

      expect(auth.calls.last, 'claimVerify guest-token-0 ana@correo.com 111222');
      // The same user, the same token: no second account, nothing left behind.
      expect(
        auth.calls.where((c) => c.startsWith('sendCode') || c.startsWith('verifyCode')),
        isEmpty,
      );
      expect(_stored(container)?.token, 'guest-token-0');
      expect(_stored(container)?.guest, isFalse);
      expect((await SessionStore().read())?.guest, isFalse);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('is warned before signing in as another account, and nothing happens on cancel', (
      tester,
    ) async {
      final container = await openEmail(tester);
      await _enterEmail(tester, 'ana@correo.com');

      await tester.tap(find.text('Entrar con otra cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('¿Dejar tu cuenta de invitado?'), findsOneWidget);
      expect(
        find.textContaining('lo que anotaste como invitado se queda en esa cuenta'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(auth.calls, isEmpty);
      expect(_stored(container)?.token, 'guest-token-0');
    });

    testWidgets('who confirms the warning signs in with the email', (tester) async {
      final container = await openEmail(tester);
      await _enterEmail(tester, 'ana@correo.com');
      await tester.tap(find.text('Entrar con otra cuenta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar de todos modos'));
      await tester.pumpAndSettle();
      expect(auth.calls, ['sendCode ana@correo.com']);

      await _enterCode(tester, '123456');
      expect(_stored(container)?.token, 'email-token-1');
      expect(_stored(container)?.guest, isFalse);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('who goes back to change the email is asked again', (tester) async {
      await openEmail(tester);
      await _enterEmail(tester, 'ana@correo.com');
      await tester.tap(find.text('Entrar con otra cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar de todos modos'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usar otro correo'));
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'luis@correo.com');

      expect(find.text('¿Guardamos lo que ya anotaste?'), findsOneWidget);
      expect(auth.calls, ['sendCode ana@correo.com']);
    });

    testWidgets('gets email_taken: told to sign in with it, and the guest stays', (tester) async {
      final container = await openEmail(tester);
      auth.failures['claimSend'] = const AuthFailure(code: 'email_taken', status: 409);
      await _enterEmail(tester, 'ana@correo.com');

      await tester.tap(find.text('Guardar mi progreso'));
      await tester.pumpAndSettle();

      expect(find.text('Ese correo ya tiene una cuenta. Entra con él.'), findsOneWidget);
      expect(_stored(container)?.token, 'guest-token-0');
      expect(_stored(container)?.guest, isTrue);
    });

    testWidgets('opening a magic link is warned before replacing the guest', (tester) async {
      final container = await pumpApp(tester, auth: auth);
      auth.calls.clear();

      container.read(routerProvider).go('/auth/verify?email=ana%40correo.com&code=654321');
      await tester.pumpAndSettle();

      expect(auth.calls, isEmpty);
      expect(find.text('¿Dejar tu cuenta de invitado?'), findsOneWidget);

      await tester.tap(find.text('Entrar de todos modos'));
      await tester.pumpAndSettle();
      expect(auth.calls, ['verifyCode ana@correo.com 654321']);
      expect(_stored(container)?.guest, isFalse);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('passkey', () {
    testWidgets('Entrar con huella signs in with the passkey', (tester) async {
      final passkeys = FakePasskeys();
      final container = await pumpApp(tester, auth: auth, passkeys: passkeys);

      await tester.tap(find.text('Entrar con huella'));
      await tester.pumpAndSettle();

      expect(passkeys.calls, ['get {"challenge":"sign-in"}']);
      expect(auth.calls.take(3), [
        'passkeySignInOptions',
        'passkeySignIn {"assertion":true}',
        'isGuest passkey-token-1',
      ]);
      expect(_stored(container)?.token, 'passkey-token-1');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('closing the phone prompt says nothing; a failure suggests the email', (
      tester,
    ) async {
      final passkeys = FakePasskeys();
      await pumpApp(tester, auth: auth, passkeys: passkeys);

      passkeys.failure = const AuthFailure(code: 'AUTH_CANCELLED', status: 400);
      await tester.tap(find.text('Entrar con huella'));
      await tester.pumpAndSettle();
      expect(find.textContaining('huella. Inténtalo'), findsNothing);

      passkeys.failure = const AuthFailure(code: 'NO_CREDENTIAL', status: 400);
      await tester.tap(find.text('Entrar con huella'));
      await tester.pumpAndSettle();
      expect(
        find.text('No pudimos hacerte entrar con tu huella. Inténtalo otra vez o usa tu correo.'),
        findsOneWidget,
      );
      expect(find.byType(HomeScreen), findsNothing);
    });
  });

  group('errors that are not an AuthFailure', () {
    const network = 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
    const generic = 'Algo salió mal. Inténtalo de nuevo en un momento.';

    bool enabled(WidgetTester tester, Finder button) =>
        tester.widget<ButtonStyleButton>(button).onPressed != null;

    testWidgets('a timeout on Probar sin correo says no connection and the button works again', (
      tester,
    ) async {
      await pumpApp(tester, auth: auth);
      auth.failures['signInAsGuest'] = TimeoutException('slow network');

      await tester.tap(find.text('Probar sin correo'));
      await tester.pumpAndSettle();

      expect(find.text(network), findsOneWidget);
      expect(enabled(tester, find.byKey(const Key('entry.guest'))), isTrue);
      expect(find.text('Probar sin correo'), findsOneWidget);

      await tester.tap(find.text('Probar sin correo'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a network failure sending the code says so and the screen stays usable', (
      tester,
    ) async {
      await pumpApp(tester, auth: auth);
      await tester.tap(find.text('Entrar con mi correo'));
      await tester.pumpAndSettle();
      auth.failures['sendCode'] = const SocketException('Network is unreachable');

      await _enterEmail(tester, 'ana@correo.com');

      expect(find.text(network), findsOneWidget);
      expect(find.text('Enviando…'), findsNothing);
      expect(enabled(tester, find.byKey(const Key('entry.send'))), isTrue);

      await _enterEmail(tester, 'ana@correo.com');
      expect(find.text('Revisa tu correo'), findsOneWidget);
    });

    testWidgets('anything else while checking the code says something went wrong, and the '
        'button stops saying Entrando…', (tester) async {
      await pumpApp(tester, auth: auth);
      await tester.tap(find.text('Entrar con mi correo'));
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'ana@correo.com');
      auth.failures['verifyCode'] = StateError('storage write failed');

      await _enterCode(tester, '123456');

      expect(find.text(generic), findsOneWidget);
      expect(find.text('Entrando…'), findsNothing);
      expect(enabled(tester, find.byKey(const Key('entry.submitCode'))), isTrue);
    });

    testWidgets('a timeout on a magic link stops the spinner and offers to try again', (
      tester,
    ) async {
      final container = await pumpApp(tester, auth: auth);
      auth.failures['verifyCode'] = TimeoutException('slow network');

      container.read(routerProvider).go('/auth/verify?email=ana%40correo.com&code=654321');
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No pudimos hacerte entrar'), findsOneWidget);
      expect(find.text(network), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a broken answer from the passkey prompt suggests the email', (tester) async {
      final passkeys = FakePasskeys();
      await pumpApp(tester, auth: auth, passkeys: passkeys);
      passkeys.failure = const FormatException('not JSON');

      await tester.tap(find.text('Entrar con huella'));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos hacerte entrar con tu huella. Inténtalo otra vez o usa tu correo.'),
        findsOneWidget,
      );
      expect(enabled(tester, find.byKey(const Key('entry.passkey'))), isTrue);
    });

    testWidgets('in English, the same message in English', (tester) async {
      await pumpApp(tester, auth: auth, locale: const Locale('en'));
      auth.failures['signInAsGuest'] = TimeoutException('slow network');

      await tester.tap(find.text('Try it without an email'));
      await tester.pumpAndSettle();

      expect(find.text('No connection. Check your internet and try again.'), findsOneWidget);
    });
  });

  testWidgets('a returning person goes straight home', (tester) async {
    mockStorage(token: 'email-token-9');
    await pumpApp(tester, auth: auth);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Probar sin correo'), findsNothing);
  });

  testWidgets('a session the server no longer knows goes back to the first screen', (tester) async {
    mockStorage(token: 'email-token-9');
    auth.failures['isGuest'] = const AuthFailure(code: 'unauthenticated', status: 401);
    await pumpApp(tester, auth: auth);

    expect(find.text('Probar sin correo'), findsOneWidget);
    expect(await SessionStore().read(), isNull);
  });
}
