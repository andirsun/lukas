import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/feedback/feedback.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/entry/entry_screen.dart';
import 'package:lukitas/settings/licenses.dart';
import 'package:lukitas/settings/preferences.dart';
import 'package:lukitas/api/server_url.dart';

import 'harness.dart';

const _honestEs = 'Sin correo, si pierdes el teléfono o borras la app, pierdes tus datos.';
const _honestEn = 'Without an email, losing the phone or deleting the app loses your data.';

Future<void> _scrollTo(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await _scrollTo(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(registerExtraLicenses);

  group('opening Settings', () {
    testWidgets('home has a gear that opens it; a guest also sees Guarda tu progreso', (
      tester,
    ) async {
      await pumpSettingsApp(tester, guest: true);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(const Key('home.saveProgress')), findsOneWidget);

      await tester.tap(find.byKey(const Key('home.settings')));
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsWidgets);
      expect(find.byKey(const Key('settings.sound')), findsOneWidget);
    });

    testWidgets('someone with an email sees no Guarda tu progreso anywhere', (tester) async {
      await pumpSettingsApp(tester);
      expect(find.byKey(const Key('home.settings')), findsOneWidget);
      expect(find.byKey(const Key('home.saveProgress')), findsNothing);

      await tester.tap(find.byKey(const Key('home.settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings.saveProgress')), findsNothing);
      expect(find.text('Guarda tu progreso'), findsNothing);
    });

    testWidgets('a guest\'s Settings offers Guarda tu progreso at the top', (tester) async {
      await pumpSettingsApp(tester, guest: true, location: '/settings');
      expect(find.text('Estás usando Lukitas sin correo.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.saveProgress')));
      await tester.pumpAndSettle();
      expect(find.text(_honestEs), findsOneWidget);
    });

    testWidgets('in English', (tester) async {
      await pumpSettingsApp(tester, locale: const Locale('en'), location: '/settings');
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Sounds'), findsOneWidget);
      expect(find.text('Vibration'), findsOneWidget);
    });
  });

  group('sound, vibration, notices and the widget', () {
    testWidgets('sounds and vibration start on, and each switch is its own setting', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: find.byKey(const Key('settings.sound')),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('settings.sound')));
      await tester.pumpAndSettle();
      expect(env.container.read(soundEnabledProvider), isFalse);
      expect(env.container.read(vibrationEnabledProvider), isTrue);
      expect(env.flags['setting.sound']?.value, isFalse);

      await tester.tap(find.byKey(const Key('settings.vibration')));
      await tester.pumpAndSettle();
      expect(env.container.read(vibrationEnabledProvider), isFalse);
      expect(env.flags['setting.vibration']?.value, isFalse);
    });

    testWidgets('the two notices are on, and the widget\'s amount is shown, until chosen', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      expect(env.container.read(dueNoticeEnabledProvider), isTrue);
      expect(env.container.read(guestNoticeEnabledProvider), isTrue);
      expect(env.container.read(hideWidgetAmountProvider), isFalse);

      await _tap(tester, 'settings.dueNotice');
      await _tap(tester, 'settings.guestNotice');
      await _tap(tester, 'settings.hideAmount');

      expect(env.container.read(dueNoticeEnabledProvider), isFalse);
      expect(env.container.read(guestNoticeEnabledProvider), isFalse);
      expect(env.container.read(hideWidgetAmountProvider), isTrue);
      expect(env.flags['setting.notice.due']?.value, isFalse);
      expect(env.flags['setting.notice.guest']?.value, isFalse);
      expect(env.flags['setting.widget.hideAmount']?.value, isTrue);
    });
  });

  group('theme and language', () {
    testWidgets('they follow the system, and an override is kept', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.system);
      expect(app().locale, isNull);

      await tester.tap(find.byKey(const Key('settings.theme.night')));
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.dark);
      expect(env.settings.values['setting.theme'], 'dark');

      await tester.tap(find.byKey(const Key('settings.theme.day')));
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.light);

      await tester.tap(find.byKey(const Key('settings.theme.auto')));
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.system);
      expect(env.settings.values.containsKey('setting.theme'), isFalse);
    });

    testWidgets('picking English changes every word at once; Automático goes back to the phone', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      expect(find.text('Ajustes'), findsWidgets);

      await tester.tap(find.byKey(const Key('settings.language.en')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Ajustes'), findsNothing);
      expect(env.settings.values['setting.locale'], 'en');

      await tester.tap(find.byKey(const Key('settings.language.auto')));
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsWidgets);
      expect(env.settings.values.containsKey('setting.locale'), isFalse);
    });
  });

  group('sign out', () {
    testWidgets('someone with an email signs out at once and lands on the first screen', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.signOut');

      expect(env.auth.calls, contains('signOut email-token-0'));
      expect(env.container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(find.byType(EntryScreen), findsOneWidget);
    });

    testWidgets('a guest is warned first, with the honest copy, and cancelling changes nothing', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/settings');
      await _tap(tester, 'settings.signOut');

      expect(find.text('¿Cerrar sesión sin guardar tu progreso?'), findsOneWidget);
      expect(find.textContaining(_honestEs), findsOneWidget);
      expect(env.auth.calls.where((c) => c.startsWith('signOut')), isEmpty);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(env.container.read(sessionProvider).status, SessionStatus.signedIn);
      expect(env.stored?.guest, isTrue);
      expect(find.byType(EntryScreen), findsNothing);
    });

    testWidgets('the warning in English says it too', (tester) async {
      await pumpSettingsApp(tester, guest: true, locale: const Locale('en'), location: '/settings');
      await _tap(tester, 'settings.signOut');
      expect(find.text('Sign out without saving your progress?'), findsOneWidget);
      expect(find.textContaining(_honestEn), findsOneWidget);
    });

    testWidgets('a guest who goes ahead anyway is signed out, and everything on the phone goes', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/settings');
      await _tap(tester, 'settings.signOut');
      await tester.tap(find.byKey(const Key('guest.signOutConfirm')));
      await tester.pumpAndSettle();

      expect(env.auth.calls, contains('signOut guest-token-0'));
      expect(env.container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(await SessionStore().read(), isNull);
      expect(find.byType(EntryScreen), findsOneWidget);
    });

    testWidgets('the warning offers Guarda tu progreso instead, and signs nobody out', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/settings');
      await _tap(tester, 'settings.signOut');
      await tester.tap(find.byKey(const Key('guest.saveInstead')));
      await tester.pumpAndSettle();

      expect(env.auth.calls.where((c) => c.startsWith('signOut')), isEmpty);
      expect(env.container.read(sessionProvider).status, SessionStatus.signedIn);
      expect(find.byKey(const Key('progress.email')), findsOneWidget);
    });
  });

  group('the server URL', () {
    testWidgets('it shows the current server, and an invalid address is refused in the dialog', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      await _scrollTo(tester, 'settings.server');
      expect(find.text('https://app-lukas.andersonlaverde.com'), findsOneWidget);

      await _tap(tester, 'settings.server');
      await tester.enterText(find.byKey(const Key('settings.server.field')), 'http://example.com');
      await tester.tap(find.byKey(const Key('settings.server.change')));
      await tester.pumpAndSettle();

      expect(find.textContaining('empiece por https://'), findsOneWidget);
      expect(env.container.read(serverUrlProvider), defaultServerUrl);
      expect(env.container.read(sessionProvider).status, SessionStatus.signedIn);
    });

    testWidgets('changing it signs out and points every call there', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.server');
      await tester.enterText(
        find.byKey(const Key('settings.server.field')),
        'https://my.server.org',
      );
      await tester.tap(find.byKey(const Key('settings.server.change')));
      await tester.pumpAndSettle();

      expect(env.container.read(serverUrlProvider).toString(), 'https://my.server.org');
      expect(env.container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(env.settings.values['setting.server'], 'https://my.server.org');
      expect(find.byType(EntryScreen), findsOneWidget);
    });

    testWidgets('the dev stack\'s http address is accepted', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.server');
      await tester.enterText(
        find.byKey(const Key('settings.server.field')),
        'http://10.0.2.2:3000',
      );
      await tester.tap(find.byKey(const Key('settings.server.change')));
      await tester.pumpAndSettle();
      expect(env.container.read(serverUrlProvider).toString(), 'http://10.0.2.2:3000');
    });

    testWidgets('a guest is warned before the server changes; cancelling keeps everything', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/settings');
      await _tap(tester, 'settings.server');
      await tester.enterText(
        find.byKey(const Key('settings.server.field')),
        'https://my.server.org',
      );
      await tester.tap(find.byKey(const Key('settings.server.change')));
      await tester.pumpAndSettle();

      expect(find.text('¿Cambiar de servidor sin guardar tu progreso?'), findsOneWidget);
      expect(find.textContaining(_honestEs), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(env.container.read(serverUrlProvider), defaultServerUrl);
      expect(env.container.read(sessionProvider).status, SessionStatus.signedIn);
    });

    testWidgets('a guest who goes ahead anyway moves to the new server, signed out', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, guest: true, location: '/settings');
      await _tap(tester, 'settings.server');
      await tester.enterText(
        find.byKey(const Key('settings.server.field')),
        'https://my.server.org',
      );
      await tester.tap(find.byKey(const Key('settings.server.change')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guest.serverConfirm')));
      await tester.pumpAndSettle();

      expect(env.container.read(serverUrlProvider).toString(), 'https://my.server.org');
      expect(env.container.read(sessionProvider).status, SessionStatus.signedOut);
    });

    testWidgets('"Usar el de Lukitas" puts the default address back in the field', (tester) async {
      await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.server');
      await tester.enterText(find.byKey(const Key('settings.server.field')), 'https://x.org');
      await tester.tap(find.byKey(const Key('settings.server.default')));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byKey(const Key('settings.server.field')));
      expect(field.controller?.text, defaultServerUrl.toString());
    });
  });

  group('Más en la web', () {
    testWidgets('opens the web app at the current server in the browser', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.web');
      expect(env.opener.opened, [defaultServerUrl]);
    });

    testWidgets('it says so when there is no browser', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      env.opener.works = false;
      await _tap(tester, 'settings.web');
      expect(find.text('No pudimos abrir el navegador.'), findsOneWidget);
    });
  });

  group('the voice models', () {
    testWidgets('a button deletes them, after asking', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.deleteVoice');
      expect(find.text('¿Borrar los modelos de voz?'), findsOneWidget);
      expect(env.models.deletes, 0);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(env.models.deletes, 0);

      await tester.tap(find.byKey(const Key('settings.deleteVoice')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings.deleteVoice.confirm')));
      await tester.pumpAndSettle();
      expect(env.models.deletes, 1);
      expect(find.text('Listo: borramos los modelos de voz.'), findsOneWidget);
      expect(
        find.byKey(const Key('settings.deleteVoice')),
        findsNothing,
        reason: 'nothing left to delete',
      );
    });

    testWidgets('with no model downloaded, there is nothing to delete', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings', modelsInstalled: false);
      expect(env.models.installed, isFalse);
      expect(find.byKey(const Key('settings.deleteVoice')), findsNothing);
    });

    testWidgets('a failed delete says so', (tester) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      env.models.deleteFailure = StateError('disk');
      await _tap(tester, 'settings.deleteVoice');
      await tester.tap(find.byKey(const Key('settings.deleteVoice.confirm')));
      await tester.pumpAndSettle();
      expect(
        find.text('No pudimos borrar los modelos de voz. Inténtalo otra vez.'),
        findsOneWidget,
      );
    });
  });

  group('About', () {
    testWidgets('About lists every dependency\'s licence and the model\'s', (tester) async {
      await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.about');
      expect(find.text('Acerca de Lukitas'), findsOneWidget);
      expect(find.textContaining('AGPL-3.0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('about.licenses')));
      await tester.pumpAndSettle();

      // Flutter's own page lists the packages of the registry; the app's extras are in it.
      for (final name in [
        'vosk-model-small-es-0.42',
        'vosk-model-small-en-us-0.15',
        'vosk-android 0.3.75',
        'Lukitas feedback sounds',
      ]) {
        await tester.scrollUntilVisible(
          find.text(name),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });
  });
}
