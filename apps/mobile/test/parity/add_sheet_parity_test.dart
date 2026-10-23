@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../support/parity.dart';
import '../support/parity_home.dart';

/// The add and edit sheet against the stories of apps/web/app/features/home/Home.stories.tsx that
/// leave it open: `home-home--more-options` (Más opciones opened, with pending ticked),
/// `home-home--shortcut-picks-category` (a recent name picked), `home-home--sheet-day-theme` (pesos
/// with the lukas hint) and `home-home--edit-sheet-day-theme` (the pending Spotify), each as
/// Storybook shows it after its `play` function.
///
/// The sheet opens over home, as in the story, and reads what the story's fake API answered
/// (test/parity/fixtures): the movements and categories home shows, and the names it suggested.
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

Widget _home() => ShellFrame(
  padding: const EdgeInsets.all(16),
  // The web has no 🎤 (spec §5).
  showMic: false,
  child: HomeScreen(menu: (context, close) => const SizedBox.shrink()),
);

List<Override> _overrides(ParityFixture fixture) =>
    parityHomeOverrides(FixtureHomeRepository(fixture), add: FixtureAddRepository(fixture));

Future<void> _openAdd(WidgetTester t) async {
  await precacheLukitas(t);
  await t.tap(find.byKey(const Key('home.add')));
  await t.pumpAndSettle();
}

Future<void> _keys(WidgetTester t, String keys) async {
  for (final key in keys.split('')) {
    await t.tap(find.byKey(Key(key == ',' ? 'keypad.decimal' : 'keypad.$key')));
    await t.pump();
  }
  await t.pumpAndSettle();
}

/// A click focuses what it clicks in Chrome, and `userEvent` does it from script, which counts as
/// keyboard: the control rings. A tap focuses nothing in Flutter, so it is asked to, in keyboard
/// mode.
Future<void> _clickFocus(WidgetTester t, Finder finder) async {
  await t.sendKeyEvent(LogicalKeyboardKey.shift);
  Focus.of(t.element(find.descendant(of: finder, matching: find.byType(RichText)).first))
      .requestFocus();
  await t.pumpAndSettle();
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('add sheet parity: Más opciones open, pending ticked ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--more-options');
      await parityGolden(
        t,
        'add-sheet-more-options',
        _home(),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await _openAdd(t);
          await _keys(t, '39,9');
          await t.tap(find.byKey(const Key('category.cat-groceries')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('add.more')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('add.pending')));
          await t.pumpAndSettle();
          await _clickFocus(t, find.byKey(const Key('add.pending')));
        },
      );
    });

    testWidgets('add sheet parity: a recent name picked ($theme)', (t) async {
      final fixture = ParityFixtures.load('home-home--shortcut-picks-category');
      await parityGolden(
        t,
        'add-sheet-shortcut',
        _home(),
        theme: theme,
        overrides: _overrides(fixture),
        act: (t) async {
          await _openAdd(t);
          await t.tap(find.byKey(const Key('category.cat-fun')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('shortcut.continente')));
          await t.pumpAndSettle();
          await _clickFocus(t, find.byKey(const Key('shortcut.continente')));
        },
      );
    });
  }

  testWidgets('add sheet parity: pesos, 15.500 typed (day)', (t) async {
    final fixture = ParityFixtures.load('home-home--sheet-day-theme');
    await parityGolden(
      t,
      'add-sheet-pesos',
      _home(),
      theme: 'day',
      overrides: _overrides(fixture),
      act: (t) async {
        await _openAdd(t);
        await _keys(t, '15500');
        await _clickFocus(t, find.byKey(const Key('keypad.0')));
      },
    );
  });

  testWidgets('add sheet parity: editing the pending Spotify (day)', (t) async {
    final fixture = ParityFixtures.load('home-home--edit-sheet-day-theme');
    await parityGolden(
      t,
      'add-sheet-edit',
      _home(),
      theme: 'day',
      overrides: _overrides(fixture),
      act: (t) async {
        await precacheLukitas(t);
        await t.tap(find.text('Movimientos'));
        await t.pumpAndSettle();
        await t.tap(find.text('Spotify'));
        await t.pumpAndSettle();
      },
    );
  });
}
