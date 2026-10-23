import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/auth_api.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/progress/progress_screen.dart';
import 'package:lukitas/router.dart';

import '../settings/harness.dart';

const _honestEs = 'Sin correo, si pierdes el teléfono o borras la app, pierdes tus datos.';
const _honestEn = 'Without an email, losing the phone or deleting the app loses your data.';

Future<void> _claimWith(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('progress.email')), email);
  await tester.tap(find.byKey(const Key('progress.save')));
  await tester.pumpAndSettle();
}

/// The fingerprint button (an icon button is two widgets sharing the key).
final _passkeyButton = find.byKey(const Key('progress.passkey')).first;

/// Scrolls the progress screen (not the home under it) down to the fingerprint button.
Future<void> _showPasskey(WidgetTester tester) => tester.scrollUntilVisible(
  _passkeyButton,
  100,
  scrollable: find
      .descendant(of: find.byType(ProgressScreen), matching: find.byType(Scrollable))
      .first,
);

void main() {
  group('Guarda tu progreso', () {
    testWidgets('a guest sees it from home, with the honest copy', (tester) async {
      await pumpSettingsApp(tester, guest: true);
      await tester.tap(find.byKey(const Key('home.saveProgress')));
      await tester.pumpAndSettle();

      expect(find.text('Guarda tu progreso'), findsWidgets);
      expect(find.text(_honestEs), findsOneWidget);
    });

    testWidgets('in English, the honest copy is the brief\'s', (tester) async {
      await pumpSettingsApp(tester, guest: true, locale: const Locale('en'), location: '/progress');
      expect(find.text('Save your progress'), findsWidgets);
      expect(find.text(_honestEn), findsOneWidget);
    });

    testWidgets('someone with an email who opens it is sent home', (tester) async {
      await pumpSettingsApp(tester, location: '/progress');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const Key('progress.email')), findsNothing);
    });

    testWidgets('signed out, it is not reachable either', (tester) async {
      final env = await pumpSettingsApp(tester, guest: true);
      await env.container.read(sessionProvider.notifier).signOut(discardGuest: true);
      env.container.read(routerProvider).go('/progress');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('progress.email')), findsNothing);
    });

    testWidgets('claiming an allowlisted email keeps the same account and every movement', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/progress');
      await _claimWith(tester, ' Ana@Correo.com ');

      expect(env.auth.calls, contains('claimSend guest-token-0 ana@correo.com'));
      expect(find.byKey(const Key('entry.code')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('entry.code')), '123456');
      await tester.tap(find.byKey(const Key('entry.submitCode')));
      await tester.pumpAndSettle();

      expect(env.auth.calls, contains('claimVerify guest-token-0 ana@correo.com 123456'));
      // The same token and so the same user: no sign-in, no sign-out, and no longer a guest.
      expect(env.stored?.token, 'guest-token-0');
      expect(env.stored?.guest, isFalse);
      expect(
        env.auth.calls.where((c) => c.startsWith('signOut') || c.startsWith('verifyCode')),
        isEmpty,
      );
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.byKey(const Key('home.saveProgress')),
        findsNothing,
        reason: 'nothing left to save',
      );
    });

    testWidgets('an email that is not valid is told so, and nothing is sent', (tester) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/progress');
      await _claimWith(tester, 'ana@');

      expect(find.text('Escribe un correo válido, como ana@correo.com.'), findsOneWidget);
      expect(env.auth.calls.where((c) => c.startsWith('claim')), isEmpty);
    });

    testWidgets('email_taken says to sign in with that email, and the guest stays', (tester) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/progress');
      env.auth.failures['claimSend'] = const AuthFailure(code: 'email_taken', status: 409);
      await _claimWith(tester, 'ana@correo.com');

      expect(find.text('Ese correo ya tiene una cuenta. Entra con él.'), findsOneWidget);
      expect(find.text('Entrar con ese correo'), findsOneWidget);
      expect(env.stored?.token, 'guest-token-0');
      expect(env.stored?.guest, isTrue);
      expect(
        env.auth.calls.where((c) => c.startsWith('signOut') || c.startsWith('sendCode')),
        isEmpty,
      );

      // Signing in with it is warned about, and walking away leaves the guest as it was.
      await tester.tap(find.text('Entrar con ese correo'));
      await tester.pumpAndSettle();
      expect(find.text('¿Dejar tu cuenta de invitado?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(env.stored?.guest, isTrue);
      expect(env.auth.calls.where((c) => c.startsWith('sendCode')), isEmpty);
    });

    testWidgets('an email outside the allowlist gets the existing copy', (tester) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/progress');
      env.auth.failures['claimSend'] = const AuthFailure(code: 'sign_in_not_allowed', status: 403);
      await _claimWith(tester, 'ana@correo.com');

      expect(
        find.text(
          'Lukitas todavía no está abierto al público. Si quieres probarlo, escríbele a quien te invitó.',
        ),
        findsOneWidget,
      );
      expect(env.stored?.guest, isTrue);
    });

    testWidgets('a wrong code says so and the guest stays a guest', (tester) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/progress');
      await _claimWith(tester, 'ana@correo.com');
      env.auth.failures['claimVerify'] = const AuthFailure(code: 'invalid_code', status: 400);
      await tester.enterText(find.byKey(const Key('entry.code')), '000000');
      await tester.tap(find.byKey(const Key('entry.submitCode')));
      await tester.pumpAndSettle();

      expect(
        find.text('Ese código no es correcto. Revísalo e inténtalo otra vez.'),
        findsOneWidget,
      );
      expect(env.stored?.guest, isTrue);
    });
  });

  group('adding a fingerprint', () {
    testWidgets('the button is there only when the phone supports passkeys', (tester) async {
      await pumpSettingsApp(tester, guest: true, location: '/progress');
      expect(find.byKey(const Key('progress.passkey')), findsNothing);
    });

    testWidgets(
      'it explains that the account is lost with the phone, and that sync needs an email',
      (tester) async {
        await pumpSettingsApp(tester, guest: true, passkeysSupported: true, location: '/progress');
        await _showPasskey(tester);
        expect(find.textContaining('pierdes la cuenta'), findsOneWidget);
        expect(find.textContaining('otro dispositivo'), findsOneWidget);
      },
    );

    testWidgets('it registers a passkey on the guest\'s own account, and the guest stays a guest', (
      tester,
    ) async {
      final env = await pumpSettingsApp(
        tester,
        guest: true,
        passkeysSupported: true,
        location: '/progress',
      );
      await _showPasskey(tester);
      await tester.tap(_passkeyButton);
      await tester.pumpAndSettle();

      expect(env.auth.calls, contains('passkeyRegisterOptions guest-token-0'));
      expect(env.auth.calls.any((c) => c.startsWith('passkeyRegister guest-token-0')), isTrue);
      expect(find.text('Listo: ya puedes entrar con tu huella.'), findsOneWidget);
      expect(env.stored?.guest, isTrue);
    });

    testWidgets('closing the phone\'s prompt says nothing', (tester) async {
      final env = await pumpSettingsApp(
        tester,
        guest: true,
        passkeysSupported: true,
        location: '/progress',
      );
      env.passkeys.failure = const AuthFailure(code: 'AUTH_CANCELLED', status: 400);
      await _showPasskey(tester);
      await tester.tap(_passkeyButton);
      await tester.pumpAndSettle();

      expect(find.text('Listo: ya puedes entrar con tu huella.'), findsNothing);
      expect(find.text('No pudimos guardar tu huella. Inténtalo otra vez.'), findsNothing);
    });

    testWidgets('a failure says so and the button works again', (tester) async {
      final env = await pumpSettingsApp(
        tester,
        guest: true,
        passkeysSupported: true,
        location: '/progress',
      );
      env.passkeys.failure = const AuthFailure(code: 'PASSKEY_FAILED', status: 400);
      await _showPasskey(tester);
      await tester.tap(_passkeyButton);
      await tester.pumpAndSettle();

      expect(find.text('No pudimos guardar tu huella. Inténtalo otra vez.'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(_passkeyButton).onPressed, isNotNull);
    });
  });
}
