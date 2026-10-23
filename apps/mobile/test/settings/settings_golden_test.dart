@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/app.dart';
import 'package:lukitas/capture/models_download.dart';
import 'package:lukitas/entry/guest_dialogs.dart';
import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/settings/settings_screen.dart';

import '../entry/fakes.dart';
import '../home/fakes.dart';
import '../support/parity.dart';
import 'fakes.dart';
import 'harness.dart' show DeletableModelStore;

/// What Settings has that the web's has not, to review by eye: the guest's "Guarda tu progreso", the
/// phone's own switches (vibration, the two notices, the widget), the voice models, the server,
/// "Más en la web", About and signing out. They are drawn with the web's parts (`SettingsSection`,
/// `SettingSwitch`, `PressButton`), in the web's settings style, so the web has no story of them and
/// the parity pairs (`settings-app-sections*`) cannot compare them. The sheets the guest dialogs
/// became (the sign-out warning, the claim offer) and the server's sheet are here too.
///
/// The goldens are the Mac's pixels, tagged `golden`; update them with
/// `flutter test --update-goldens test/settings/settings_golden_test.dart`.

/// The whole page, taller than a phone, so one picture shows every card.
const _page = Size(412, 2500);

List<Override> _overrides({required bool guest}) {
  final token = guest ? 'guest-token-0' : 'email-token-0';
  mockStorage(token: token, guest: guest);
  final auth = FakeAuthApi()..guests[token] = guest;
  return [
    toastBarAnimatesProvider.overrideWithValue(false),
    authApiProvider.overrideWithValue(auth),
    homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
    flagStoreProvider.overrideWith((ref, key) => FakeFlagStore()),
    modelStoreProvider.overrideWithValue(DeletableModelStore()),
  ];
}

Future<void> _golden(
  WidgetTester t,
  String name,
  String theme, {
  required bool guest,
  Size size = _page,
  Future<void> Function(WidgetTester t)? act,
}) async {
  await t.runAsync(loadParityFonts);
  t.view
    ..physicalSize = size * parityPixelRatio
    ..devicePixelRatio = parityPixelRatio;
  addTearDown(t.view.reset);
  debugDisableShadows = false;
  try {
    await t.pumpWidget(
      ProviderScope(
        overrides: _overrides(guest: guest),
        child: MaterialApp(
          theme: parityTheme(theme),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => withAppHosts(child!, animateToastBar: false),
          home: const SettingsScreen(),
        ),
      ),
    );
    await t.pumpAndSettle();
    if (act != null) {
      await act(t);
      await t.pumpAndSettle();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        Uri.file('${Directory.current.path}/test/settings/goldens/${name}_$theme.png'),
      ),
    );
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('Settings, a guest, with every card of the app ($theme)', (t) async {
      await _golden(t, 'settings_guest', theme, guest: true);
    });

    testWidgets('Settings, with an email ($theme)', (t) async {
      await _golden(t, 'settings_email', theme, guest: false);
    });

    testWidgets('the server\'s sheet ($theme)', (t) async {
      await _golden(
        t,
        'server_sheet',
        theme,
        guest: false,
        size: parityViewSize,
        act: (t) async {
          await t.scrollUntilVisible(find.byKey(const Key('settings.server')), 200);
          await t.tap(find.byKey(const Key('settings.server')));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('the voice models\' question ($theme)', (t) async {
      await _golden(
        t,
        'voice_sheet',
        theme,
        guest: false,
        size: parityViewSize,
        act: (t) async {
          await t.scrollUntilVisible(find.byKey(const Key('settings.deleteVoice')), 200);
          await t.tap(find.byKey(const Key('settings.deleteVoice')));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('the guest\'s warning before signing out ($theme)', (t) async {
      await _golden(
        t,
        'guest_signout_sheet',
        theme,
        guest: true,
        size: parityViewSize,
        act: (t) async {
          await t.scrollUntilVisible(find.byKey(const Key('settings.signOut')), 300);
          await t.tap(find.byKey(const Key('settings.signOut')));
          await t.pumpAndSettle();
        },
      );
    });
  }

  // The claim offer (a guest who typed an email) is asked from the email screen: here it opens
  // over Settings' page to be drawn.
  for (final theme in ['night', 'day']) {
    testWidgets('the guest\'s offer to save their progress ($theme)', (t) async {
      await _golden(
        t,
        'guest_claim_sheet',
        theme,
        guest: true,
        size: parityViewSize,
        act: (t) async {
          final context = t.element(find.byType(SettingsScreen));
          // Not awaited: the sheet stays open for the picture.
          unawaited(askGuestChoice(context, 'ana@correo.com'));
          await t.pumpAndSettle();
        },
      );
    });
  }
}
