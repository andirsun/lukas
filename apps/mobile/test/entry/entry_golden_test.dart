@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/entry/entry_screen.dart';
import 'package:lukitas/entry/verify_link_screen.dart';
import 'package:lukitas/l10n/app_localizations.dart';
import 'package:lukitas/progress/progress_screen.dart';

import '../support/parity.dart';
import '../support/parity_home.dart' show precacheLukitas;
import 'fakes.dart';

/// The entry screens that have no web story, to review by eye: the first screen with "Probar sin
/// correo" (the web's sign-in has no guest, so the parity pairs of the sign-in screens do not draw
/// it), "Guarda tu progreso", and the magic link that finds a guest signed in. They are built from
/// the parts of the web's sign-in screens (`lib/entry/sign_in_frame.dart`), in night and in day, at
/// the phone's size.
///
/// The goldens are the Mac's pixels, tagged `golden`; update them with
/// `flutter test --update-goldens test/entry/entry_golden_test.dart`.

Future<void> _golden(
  WidgetTester t,
  String name,
  String theme,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  await t.runAsync(loadParityFonts);
  t.view
    ..physicalSize = parityViewSize * parityPixelRatio
    ..devicePixelRatio = parityPixelRatio;
  addTearDown(t.view.reset);
  // `flutter test` draws shadows hard-edged; the primary button's glow is a blur.
  debugDisableShadows = false;
  try {
    await t.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: parityTheme(theme),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          home: screen,
        ),
      ),
    );
    await t.pumpAndSettle();
    await precacheLukitas(t);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        Uri.file('${Directory.current.path}/test/entry/goldens/${name}_$theme.png'),
      ),
    );
  } finally {
    debugDisableShadows = true;
  }
}

List<Override> _overrides({bool guest = false, bool passkeys = true}) {
  final auth = FakeAuthApi();
  mockStorage(token: guest ? 'guest-token-0' : null, guest: guest);
  auth.guests['guest-token-0'] = true;
  return [
    authApiProvider.overrideWithValue(auth),
    passkeysProvider.overrideWithValue(FakePasskeys(isSupported: passkeys)),
  ];
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('the first screen, with "Probar sin correo" ($theme)', (t) async {
      await _golden(t, 'entry', theme, const EntryScreen(), overrides: _overrides());
    });

    testWidgets('Guarda tu progreso ($theme)', (t) async {
      await _golden(
        t,
        'progress',
        theme,
        const ProgressScreen(),
        overrides: _overrides(guest: true),
      );
    });

    testWidgets('a magic link that finds a guest signed in ($theme)', (t) async {
      await _golden(
        t,
        'verify_guest',
        theme,
        const VerifyLinkScreen(email: 'ana@correo.com', code: '123456'),
        overrides: _overrides(guest: true),
      );
    });
  }
}
