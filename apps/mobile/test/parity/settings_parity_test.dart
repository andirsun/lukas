@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/settings/preferences.dart';
import 'package:lukitas/settings/settings_screen.dart';
import 'package:lukitas/ui/app_shell.dart';

import '../entry/fakes.dart';
import '../support/parity.dart';
import '../support/parity_home.dart';

/// Settings against the stories that show it, `manage-settings--app-sections`,
/// `--app-sections-day-english` and `--app-sections-sound-off`
/// (apps/web/app/features/settings/Settings.stories.tsx), each as Storybook shows it after its
/// `play` function.
///
/// The web's page has five cards; the app has Preferencias as the web draws it, and the web's other
/// four (time and currency, passkeys, data, deleting the account) stay on the web, behind a link.
/// The stories leave only Preferencias on the page, and the pairs draw only that
/// (`SettingsScreen.webSectionsOnly`: no "Automático" language, which the web has not, and none of
/// the app's own cards). The app's own cards have goldens of their own in `test/settings/goldens`,
/// to review by eye.
///
/// The app reads who is signed in from what the story's fake API answered (test/parity/fixtures).
///
/// Update the goldens with `flutter test --update-goldens test/parity`, then compare with
/// `dart run tool/parity/compose.dart` (docs/mobile/parity.md).

/// The page in the story's frame: Storybook's 16px of padding, the bar under it, no 🎤.
Widget _page() => ShellFrame(
  padding: const EdgeInsets.all(16),
  showMic: false,
  child: const SettingsScreen(webSectionsOnly: true),
);

/// What the page needs besides the story's API: someone signed in with an email, on a fake server.
List<Override> _overrides(ParityFixture fixture, String theme) {
  mockStorage(token: 'email-token-0');
  final auth = FakeAuthApi()..guests['email-token-0'] = false;
  return [
    authApiProvider.overrideWithValue(auth),
    // The story's toolbar sets the theme, and Settings' own choice follows it.
    themeModeProvider.overrideWith(() => _Theme(theme == 'day' ? ThemeMode.light : ThemeMode.dark)),
    ...parityHomeOverrides(FixtureHomeRepository(fixture)),
  ];
}

class _Theme extends ThemeModeSetting {
  _Theme(this.mode);

  final ThemeMode mode;

  @override
  ThemeMode build() => mode;
}

Future<void> _tab(WidgetTester t, int times) async {
  for (var i = 0; i < times; i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
  }
}

void main() {
  for (final theme in ['night', 'day']) {
    testWidgets('settings parity: Preferencias ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-settings--app-sections');
      await parityGolden(
        t,
        'settings-app-sections',
        _page(),
        theme: theme,
        overrides: _overrides(fixture, theme),
      );
    });

    testWidgets('settings parity: sounds turned off, the keyboard on them ($theme)', (t) async {
      final fixture = ParityFixtures.load('manage-settings--app-sections-sound-off');
      await parityGolden(
        t,
        'settings-app-sections-sound-off',
        _page(),
        theme: theme,
        overrides: _overrides(fixture, theme),
        act: (t) async {
          await t.tap(find.byKey(const Key('settings.sound')));
          await t.pumpAndSettle();
          // The click leaves the focus on the switch, and Chrome rings it: Tab, back, the language,
          // the theme, the switch.
          await _tab(t, 4);
        },
      );
    });
  }

  testWidgets('settings parity: by day, in English (day)', (t) async {
    final fixture = ParityFixtures.load('manage-settings--app-sections-day-english');
    await parityGolden(
      t,
      'settings-app-sections-day-english',
      _page(),
      theme: 'day',
      locale: const Locale('en'),
      overrides: _overrides(fixture, 'day'),
    );
  });
}
