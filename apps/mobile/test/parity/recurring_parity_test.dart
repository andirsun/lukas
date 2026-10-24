@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/recurring/recurring_repository.dart';
import 'package:lukitas/recurring/recurring_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../support/parity.dart';
import '../support/parity_home.dart';

/// The recurring payments against the stories that show them (`manage-recurring--*`,
/// apps/web/app/features/recurring/Recurring.stories.tsx), each as Storybook shows it after its
/// `play` function: the list, the empty page, the page after a payment was made or deleted (a story's
/// last picture holds the list the fake API answered then, and the ring a script's click leaves on
/// the add button), and the new, edit and delete sheets.
///
/// The app reads what the story's fake API answered (test/parity/fixtures). Update the goldens with
/// `flutter test --update-goldens test/parity`, then compare with `dart run tool/parity/compose.dart`
/// (docs/mobile/parity.md).

/// The story's API for the recurring payments: the list it answered.
class _FixtureRecurring implements RecurringRepository {
  _FixtureRecurring(this.fixture);

  final ParityFixture fixture;

  @override
  Future<List<Recurrence>> list() async => [
    for (final rule in fixtureJson(fixture, '/v1/recurrences')! as List)
      readBuilt(Recurrence.serializer, rule),
  ];

  @override
  Future<Recurrence> create(NewRecurrence values) async => throw UnimplementedError();

  @override
  Future<Recurrence> update(
    String id,
    NewRecurrence values, {
    required bool categoryChanged,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();
}

/// The page in the story's frame: Storybook's 16px of padding, the bar under it, no 🎤.
Widget _screen() => const ShellFrame(padding: EdgeInsets.all(16), showMic: false, child: RecurringScreen());

List<Override> _overrides(ParityFixture fixture) => [
  ...parityHomeOverrides(FixtureHomeRepository(fixture)),
  recurringRepositoryProvider.overrideWithValue(_FixtureRecurring(fixture)),
];

/// What a story's `userEvent.click` leaves behind: the focus on the control clicked (the sheet's
/// close gives it back to the button that opened it).
void _focus(WidgetTester t, Finder control) {
  final node = Focus.of(
    t.element(find.descendant(of: control, matching: find.byType(GestureDetector)).first),
  );
  node.requestFocus();
}

/// A key after the clicks: keyboard mode, where the focused control shows its ring, as Chrome rings
/// what a script's click focused.
Future<void> _keyboardMode(WidgetTester t) => t.sendKeyEvent(LogicalKeyboardKey.shift);

/// The page after a save: the add button, where the sheet's close put the focus, has its ring.
Future<void> _ringOnAdd(WidgetTester t) async {
  _focus(t, find.byKey(const Key('recurring.add')));
  await _keyboardMode(t);
}

Future<void> _openSpotify(WidgetTester t) async {
  await t.tap(find.text('Spotify'));
  await t.pumpAndSettle();
}

void main() {
  for (final theme in ['night', 'day']) {
    void pair(
      String name,
      String id,
      String storyId,
      Future<void> Function(WidgetTester t)? act,
    ) {
      testWidgets('recurring parity: $name ($theme)', (t) async {
        await parityGolden(
          t,
          id,
          _screen(),
          theme: theme,
          overrides: _overrides(ParityFixtures.load(storyId)),
          act: act,
        );
      });
    }

    pair('the list', 'recurring-list', 'manage-recurring--list', null);
    pair('nothing yet', 'recurring-empty', 'manage-recurring--empty', precacheLukitas);
    pair(
      'a yearly payment saved',
      'recurring-yearly-saved',
      'manage-recurring--yearly-requires-month',
      _ringOnAdd,
    );
    pair(
      'a monthly income saved',
      'recurring-income-saved',
      'manage-recurring--create-monthly-income',
      _ringOnAdd,
    );
    pair('Spotify deleted', 'recurring-deleted', 'manage-recurring--edit-and-delete', null);
    pair('in pesos', 'recurring-pesos', 'manage-recurring--pesos-recurring', _ringOnAdd);
    pair('the new payment sheet', 'recurring-new-sheet', 'manage-recurring--new-sheet-open', (
      t,
    ) async {
      await t.tap(find.byKey(const Key('recurring.add')));
      await t.pumpAndSettle();
    });
    pair('the edit sheet', 'recurring-edit-sheet', 'manage-recurring--edit-sheet-open', _openSpotify);
    pair('the delete question', 'recurring-delete-sheet', 'manage-recurring--delete-sheet-open', (
      t,
    ) async {
      await _openSpotify(t);
      await t.tap(find.byKey(const Key('recurring.delete')));
      await t.pumpAndSettle();
    });
  }

  testWidgets('recurring parity: the new payment sheet, yearly (day)', (t) async {
    await parityGolden(
      t,
      'recurring-new-sheet-yearly',
      _screen(),
      theme: 'day',
      overrides: _overrides(ParityFixtures.load('manage-recurring--new-sheet-yearly')),
      act: (t) async {
        await t.tap(find.byKey(const Key('recurring.add')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('recurring.frequency.yearly')));
        await t.pumpAndSettle();
      },
    );
  });
}
