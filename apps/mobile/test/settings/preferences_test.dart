import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/settings/initial_settings.dart';
import 'package:lukitas/settings/preferences.dart';
import 'package:lukitas/settings/settings_store.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the on/off preferences', () {
    final flags = {
      'the due-today notice': (dueNoticeEnabledProvider, 'setting.notice.due', true),
      'the guest-warning notice': (guestNoticeEnabledProvider, 'setting.notice.guest', true),
      'hide the amount in the widget': (
        hideWidgetAmountProvider,
        'setting.widget.hideAmount',
        false,
      ),
    };

    for (final entry in flags.entries) {
      final (provider, key, initial) = entry.value;

      test('${entry.key}: ${initial ? 'on' : 'off'} until chosen, kept on its own key', () async {
        final store = FakeFlagStore();
        final container = ProviderContainer(
          overrides: [flagStoreProvider(key).overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        container.listen(provider, (_, _) {});
        await container.read(provider.notifier).ready;
        expect(container.read(provider), initial);

        await container.read(provider.notifier).set(!initial);
        expect(container.read(provider), !initial);
        expect(store.value, !initial);

        final again = ProviderContainer(
          overrides: [flagStoreProvider(key).overrideWithValue(store)],
        );
        addTearDown(again.dispose);
        again.listen(provider, (_, _) {});
        await again.read(provider.notifier).ready;
        expect(again.read(provider), !initial, reason: 'read back at the next start');
      });
    }

    test('their keys are all different from each other and from sound and vibration', () {
      final keys = [
        for (final (_, key, _) in flags.values) key,
        'setting.sound',
        'setting.vibration',
      ];
      expect(keys.toSet(), hasLength(keys.length));
    });
  });

  group('theme and language', () {
    ProviderContainer containerWith(SettingsStore store, {InitialSettings? initial}) {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          if (initial != null) initialSettingsProvider.overrideWithValue(initial),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('they follow the system by default', () async {
      final container = containerWith(FakeSettingsStore());
      expect(container.read(themeModeProvider), ThemeMode.system);
      expect(container.read(localeOverrideProvider), isNull);
      final initial = await InitialSettings.read(FakeSettingsStore());
      expect(initial.themeMode, ThemeMode.system);
      expect(initial.locale, isNull);
    });

    test('an override of the theme is kept and read back at the next start', () async {
      final store = FakeSettingsStore();
      final container = containerWith(store);
      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);
      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      expect((await InitialSettings.read(store)).themeMode, ThemeMode.dark);

      final next = containerWith(store, initial: await InitialSettings.read(store));
      expect(next.read(themeModeProvider), ThemeMode.dark);
    });

    test('going back to "follow the system" forgets the override', () async {
      final store = FakeSettingsStore();
      final container = containerWith(store);
      await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      await container.read(themeModeProvider.notifier).set(ThemeMode.system);
      expect(store.values, isEmpty);
      expect((await InitialSettings.read(store)).themeMode, ThemeMode.system);
    });

    test('an override of the language is kept; null follows the phone again', () async {
      final store = FakeSettingsStore();
      final container = containerWith(store);
      await container.read(localeOverrideProvider.notifier).set(const Locale('en'));
      expect(container.read(localeOverrideProvider), const Locale('en'));
      expect((await InitialSettings.read(store)).locale, const Locale('en'));

      await container.read(localeOverrideProvider.notifier).set(null);
      expect(container.read(localeOverrideProvider), isNull);
      expect(store.values, isEmpty);
    });

    test('a stored value nobody understands reads as "follow the system"', () async {
      final store = FakeSettingsStore({themeModeKey: 'sepia', localeKey: 'klingon'});
      final initial = await InitialSettings.read(store);
      expect(initial.themeMode, ThemeMode.system);
      expect(initial.locale, isNull);
    });

    test('a store that cannot be read starts with the defaults', () async {
      final initial = await InitialSettings.read(_BrokenSettingsStore());
      expect(initial.themeMode, ThemeMode.system);
      expect(initial.locale, isNull);
    });

    test('a store that cannot be written does not throw', () async {
      final container = containerWith(_BrokenSettingsStore());
      await container.read(themeModeProvider.notifier).set(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light, reason: 'for this run, at least');
    });
  });
}

class _BrokenSettingsStore implements SettingsStore {
  @override
  Future<String?> read(String key) async => throw StateError('keystore');

  @override
  Future<void> write(String key, String value) async => throw StateError('keystore');

  @override
  Future<void> delete(String key) async => throw StateError('keystore');
}
