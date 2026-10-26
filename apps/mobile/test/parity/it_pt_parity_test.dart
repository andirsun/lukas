@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/recurring/recurring_repository.dart';
import 'package:lukitas/settings/passkeys_settings.dart';
import 'package:lukitas/settings/preferences.dart';
import 'package:lukitas/settings/settings_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../entry/fakes.dart';
import '../support/parity.dart';
import '../support/parity_home.dart';

/// Italian and European Portuguese, at night, against the stories that show them
/// (`home-home--transactions-italian|portuguese`, `home-home--more-options-italian|portuguese` and
/// `manage-settings--app-sections-italian|portuguese`, in Home.stories.tsx and
/// Settings.stories.tsx): the longer words of the tabs, the bottom bar, the add sheet and the
/// settings rows (spec §3), each as Storybook shows it after its `play` function.
///
/// Update the goldens with `flutter test --update-goldens test/parity/it_pt_parity_test.dart`, then
/// compare with `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// What the stories say in each language.
const _movements = {'it': 'Movimenti', 'pt': 'Movimentos'};

Widget _home() => ShellFrame(
  padding: const EdgeInsets.all(16),
  // The web has no 🎤 (spec §5).
  showMic: false,
  child: HomeScreen(menu: (context, close) => const SizedBox.shrink()),
);

Widget _settings() => const ShellFrame(
  padding: EdgeInsets.all(16),
  showMic: false,
  child: SettingsScreen(webSectionsOnly: true),
);

/// A click focuses what it clicks in Chrome, and `userEvent` does it from script, which counts as
/// keyboard: the control rings.
Future<void> _clickFocus(WidgetTester t, Finder finder) async {
  await t.sendKeyEvent(LogicalKeyboardKey.shift);
  Focus.of(t.element(find.descendant(of: finder, matching: find.byType(RichText)).first))
      .requestFocus();
  await t.pumpAndSettle();
}

Future<void> _keys(WidgetTester t, String keys) async {
  for (final key in keys.split('')) {
    await t.tap(find.byKey(Key(key == ',' ? 'keypad.decimal' : 'keypad.$key')));
    await t.pump();
  }
  await t.pumpAndSettle();
}

/// The story's recurring payments, as its API answered them.
class _FixtureRecurring implements RecurringRepository {
  _FixtureRecurring(this.fixture);

  final ParityFixture fixture;

  @override
  Future<List<Recurrence>> list() async => [
    for (final r in fixtureJson(fixture, '/v1/recurrences')! as List)
      readBuilt(Recurrence.serializer, r),
  ];

  @override
  Future<Recurrence> create(NewRecurrence values) => throw UnimplementedError();

  @override
  Future<Recurrence> update(String id, NewRecurrence values, {required bool categoryChanged}) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();
}

class _Night extends ThemeModeSetting {
  @override
  ThemeMode build() => ThemeMode.dark;
}

class _NoPasskeys implements SettingsPasskeys {
  @override
  Future<bool> supported() async => true;

  @override
  Future<List<PasskeyItem>> list() async => [];

  @override
  Future<PasskeyOutcome> add() async => PasskeyOutcome.added;

  @override
  Future<void> remove(String id) async {}
}

List<Override> _settingsOverrides(ParityFixture fixture) {
  mockStorage(token: 'email-token-0');
  final auth = FakeAuthApi()..guests['email-token-0'] = false;
  return [
    authApiProvider.overrideWithValue(auth),
    themeModeProvider.overrideWith(_Night.new),
    ...parityHomeOverrides(FixtureHomeRepository(fixture, fromFixture: true)),
    recurringRepositoryProvider.overrideWithValue(_FixtureRecurring(fixture)),
    settingsPasskeysProvider.overrideWithValue(_NoPasskeys()),
  ];
}

void main() {
  for (final entry in {'it': 'italian', 'pt': 'portuguese'}.entries) {
    final code = entry.key;
    final name = entry.value;
    final movements = _movements[code]!;
    final locale = Locale(code);

    testWidgets('it/pt parity: Movimenti, the list ($name, night)', (t) async {
      final fixture = ParityFixtures.load('home-home--transactions-$name');
      await parityGolden(
        t,
        'home-transactions-$name',
        _home(),
        theme: 'night',
        locale: locale,
        overrides: parityHomeOverrides(FixtureHomeRepository(fixture)),
        act: (t) async {
          await precacheLukitas(t);
          await t.tap(find.text(movements));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('it/pt parity: the add sheet, more options open, pending ticked ($name, night)', (
      t,
    ) async {
      final fixture = ParityFixtures.load('home-home--more-options-$name');
      await parityGolden(
        t,
        'add-sheet-more-options-$name',
        _home(),
        theme: 'night',
        locale: locale,
        overrides: parityHomeOverrides(
          FixtureHomeRepository(fixture),
          add: FixtureAddRepository(fixture),
        ),
        act: (t) async {
          await precacheLukitas(t);
          await t.tap(find.byKey(const Key('home.add')));
          await t.pumpAndSettle();
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

    testWidgets('it/pt parity: settings, every card from the top ($name, night)', (t) async {
      final fixture = ParityFixtures.load('manage-settings--app-sections-$name');
      await parityGolden(
        t,
        'settings-app-sections-$name',
        _settings(),
        theme: 'night',
        locale: locale,
        overrides: _settingsOverrides(fixture),
      );
    });
  }
}
