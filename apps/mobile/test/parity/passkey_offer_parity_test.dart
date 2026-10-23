@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/entry/passkey_offer_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../support/parity.dart';
import '../support/parity_home.dart' show precacheLukitas;

/// The passkey offer against `sign-in-passkeyoffer--*`
/// (apps/web/app/features/sign-in/PasskeyOffer.stories.tsx), each story as Storybook shows it after
/// its `play` function (`OfferDayEnglish` pins day, and English).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

Widget _screen(Future<PasskeyOfferOutcome> Function() add) => ShellFrame(
  padding: const EdgeInsets.all(16),
  showMic: false,
  child: PasskeyOfferScreen(add: add, onAnswered: (_) {}),
);

Future<PasskeyOfferOutcome> _never() => Completer<PasskeyOfferOutcome>().future;

/// The story's click left the focus on "Crear mi huella", which Chrome rings: the button takes it,
/// and a key puts the app in keyboard mode, where it shows.
Future<void> _focusAdd(WidgetTester t) async {
  final focus = t.widget<Focus>(
    find.descendant(of: find.byKey(const Key('offer.add')), matching: find.byType(Focus)).first,
  );
  focus.focusNode!.requestFocus();
  await t.pump();
  await t.sendKeyEvent(LogicalKeyboardKey.shift);
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('passkey offer parity: the offer ($theme)', (t) async {
      await parityGolden(
        t,
        'passkey-offer',
        _screen(() async => PasskeyOfferOutcome.added),
        theme: theme,
        act: precacheLukitas,
      );
    });

    testWidgets('passkey offer parity: waiting for the fingerprint ($theme)', (t) async {
      await parityGolden(
        t,
        'passkey-offer-waiting',
        _screen(_never),
        theme: theme,
        act: (t) async {
          await precacheLukitas(t);
          await t.tap(find.byKey(const Key('offer.add')));
          await t.pump();
        },
      );
    });

    testWidgets('passkey offer parity: the passkey could not be saved ($theme)', (t) async {
      await parityGolden(
        t,
        'passkey-offer-failed',
        _screen(() async => PasskeyOfferOutcome.failed),
        theme: theme,
        act: (t) async {
          await precacheLukitas(t);
          await t.tap(find.byKey(const Key('offer.add')));
          await t.pumpAndSettle();
          await _focusAdd(t);
        },
      );
    });
  }

  testWidgets('passkey offer parity: the offer, by day in English', (t) async {
    await parityGolden(
      t,
      'passkey-offer-day-english',
      _screen(() async => PasskeyOfferOutcome.added),
      theme: 'day',
      locale: const Locale('en'),
      act: precacheLukitas,
    );
  });
}
