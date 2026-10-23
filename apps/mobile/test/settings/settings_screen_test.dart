import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/feedback/feedback.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/entry/entry_screen.dart';
import 'package:lukitas/settings/licenses.dart';
import 'package:lukitas/settings/preferences.dart';
import 'package:lukitas/settings/settings_parts.dart' show LkSwitch;
import 'package:lukitas/ui/press_link.dart';
import 'package:lukitas/ui/sheet.dart' show LkSheetScope;
import 'package:lukitas/api/server_url.dart';

import '../home/fakes.dart';
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

  group('as the web\'s Settings', () {
    testWidgets('says who is signed in, as the web does, and a guest that there is no email', (
      tester,
    ) async {
      await pumpSettingsApp(
        tester,
        location: '/settings',
        homeRepo: FakeHomeRepository(email: 'ana@correo.com'),
      );
      expect(find.text('Entraste como ana@correo.com'), findsOneWidget);
    });

    testWidgets('the sections the app has not stay on the web, behind one link that says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final env = await pumpSettingsApp(tester, location: '/settings');
      await _scrollTo(tester, 'settings.web');
      // What the web has and the app has not: named in the card, with the link.
      expect(find.bySemanticsLabel('Más en la web'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Hora y moneda.*eliminar tu cuenta')), findsOneWidget);
      expect(find.byType(PressLink), findsOneWidget);
      await tester.tap(find.byKey(const Key('settings.web')));
      await tester.pumpAndSettle();
      expect(env.opener.opened, [defaultServerUrl]);
      handle.dispose();
    });

    testWidgets('the choices are the web\'s radios: one chosen, the arrows move it', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      // Night is chosen; the right arrow, with the focus on it, picks Día.
      Focus.of(tester.element(find.byKey(const Key('settings.theme.night')))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.light);
      expect(env.settings.values['setting.theme'], 'light');
    });

    testWidgets('the sound switch says the vibration is its own setting', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester, locale: const Locale('en'), location: '/settings');
      expect(
        tester.getSemantics(find.byKey(const Key('settings.sound'))).hint,
        contains('Vibration stays on.'),
      );
      await tester.tap(find.byKey(const Key('settings.vibration')));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byKey(const Key('settings.sound'))).hint,
        contains('Vibration stays off.'),
      );
      handle.dispose();
    });

    testWidgets('the guest\'s questions are the web\'s sheet, not a dialog', (tester) async {
      await pumpSettingsApp(tester, guest: true, location: '/settings');
      await _tap(tester, 'settings.signOut');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LkSheetScope), findsOneWidget);
      expect(find.text('¿Cerrar sesión sin guardar tu progreso?'), findsOneWidget);
      // The web's sheet has a "Cerrar" and the question's own ways out, one under the other.
      expect(find.text('CERRAR'), findsOneWidget);
      expect(find.byKey(const Key('guest.saveInstead')), findsOneWidget);
      expect(find.byKey(const Key('guest.signOutConfirm')), findsOneWidget);
    });

    testWidgets('the server is changed in a sheet, and the voice models\' question is one too', (
      tester,
    ) async {
      await pumpSettingsApp(tester, location: '/settings');
      await _tap(tester, 'settings.server');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Cambiar de servidor'), findsOneWidget);
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      await _tap(tester, 'settings.deleteVoice');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('¿Borrar los modelos de voz?'), findsOneWidget);
    });

    testWidgets('a toast is the web\'s: it says what happened, above the bottom bar', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      env.opener.works = false;
      await _tap(tester, 'settings.web');
      expect(find.byType(SnackBar), findsNothing);
      final toast = tester.getRect(find.text('No pudimos abrir el navegador.'));
      final bar = tester.getRect(find.byKey(const Key('home.add')));
      expect(toast.bottom, lessThan(bar.top), reason: 'the toast sits above the ＋ and the bar');
    });
  });

  group('the phone\'s font size', () {
    for (final guest in [false, true]) {
      testWidgets('at text scale 1.3 settings has no overflow${guest ? ', for a guest' : ''}', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpSettingsApp(tester, guest: guest, location: '/settings');
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Down the whole page: every card, its buttons and its switches, with the long labels.
        final page = find.byType(Scrollable).first;
        for (var i = 0; i < 40; i++) {
          await tester.drag(page, const Offset(0, -300));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'after $i drags');
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // The last button is reachable and not clipped by the bar.
        final signOut = tester.getRect(find.byKey(const Key('settings.signOut')));
        expect(signOut.bottom, lessThanOrEqualTo(640));
        expect(signOut.height, greaterThanOrEqualTo(44));
      });
    }

    testWidgets('at text scale 1.3 the sheets have no overflow either', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpSettingsApp(tester, guest: true, location: '/settings');
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      await tester.pumpAndSettle();
      await _tap(tester, 'settings.signOut');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('guest.saveInstead')), findsOneWidget);
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      await _tap(tester, 'settings.server');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('settings.server.change')), findsOneWidget);
    });
  });

  group('opening Settings', () {
    testWidgets(
      'home\'s face button opens a menu with Ajustes; a guest also sees Guarda tu progreso',
      (tester) async {
        await pumpSettingsApp(tester, guest: true);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byKey(const Key('home.settings')), findsNothing, reason: 'the menu is closed');
        await openAccountMenu(tester);
        expect(find.byKey(const Key('home.saveProgress')), findsOneWidget);

        await tester.tap(find.byKey(const Key('home.settings')));
        await tester.pumpAndSettle();
        expect(find.text('Ajustes'), findsWidgets);
        expect(find.byKey(const Key('settings.sound')), findsOneWidget);
      },
    );

    testWidgets('someone with an email sees no Guarda tu progreso anywhere', (tester) async {
      await pumpSettingsApp(tester);
      await openAccountMenu(tester);
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
      expect(
        find.descendant(
          of: find.byKey(const Key('settings.vibration')),
          matching: find.text('Vibration'),
        ),
        findsOneWidget,
      );
    });
  });

  group('sound, vibration, notices and the widget', () {
    testWidgets('sounds and vibration start on, and each switch is its own setting', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      expect(
        tester
            .widget<LkSwitch>(
              find.descendant(
                of: find.byKey(const Key('settings.sound')),
                matching: find.byType(LkSwitch),
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
    testWidgets('night is the default; Day and System can be picked, and the choice is kept', (
      tester,
    ) async {
      final env = await pumpSettingsApp(tester, location: '/settings');
      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app().themeMode, ThemeMode.dark);
      expect(app().locale, isNull);

      await tester.tap(find.byKey(const Key('settings.theme.day')));
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.light);
      expect(env.settings.values['setting.theme'], 'light');

      await tester.tap(find.byKey(const Key('settings.theme.system')));
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.system);
      expect(env.settings.values['setting.theme'], 'system');

      await tester.tap(find.byKey(const Key('settings.theme.night')));
      await tester.pumpAndSettle();
      expect(app().themeMode, ThemeMode.dark);
      expect(env.settings.values['setting.theme'], 'dark');
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

      await tester.tap(find.text('CANCELAR'));
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

      await tester.tap(find.text('CANCELAR'));
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
      final field = tester.widget<EditableText>(find.byKey(const Key('settings.server.field')));
      expect(field.controller.text, defaultServerUrl.toString());
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

      await tester.tap(find.text('CANCELAR'));
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

      // Flutter's own page lists the packages of the registry; the app's extras are in it: the
      // models, the speech engine, an Android library, the sounds.
      final list = find
          .descendant(of: find.byType(LicensePage), matching: find.byType(Scrollable))
          .first;
      for (final name in [
        'Lukitas feedback sounds',
        'androidx.core:core 1.15.0',
        'vosk-android 0.3.75',
        'vosk-model-small-en-us-0.15',
        'vosk-model-small-es-0.42',
      ]) {
        // From the top each time: the page's order is not alphabetical.
        await tester.fling(list, const Offset(0, 10000), 10000);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text(name), 100, scrollable: list, maxScrolls: 200);
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });
  });
}
