import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/auth_api.dart';
import 'package:lukitas/api/server_url.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/widget_snapshot.dart';
import 'package:lukitas/settings/initial_settings.dart';
import 'package:lukitas/settings/settings_store.dart';

import '../entry/fakes.dart';
import '../home/fakes.dart';
import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('which server URLs are accepted', () {
    test('https, with a port or a sub-path, and a trailing slash dropped', () {
      expect(parseServerUrl('https://app-lukas.andersonlaverde.com'), isNotNull);
      expect(parseServerUrl('https://app.example.com/')?.toString(), 'https://app.example.com');
      expect(
        parseServerUrl('https://app.example.com:8443/lukitas//')?.toString(),
        'https://app.example.com:8443/lukitas',
      );
      expect(parseServerUrl('  https://app.example.com  ')?.toString(), 'https://app.example.com');
      expect(parseServerUrl('HTTPS://App.Example.com')?.host, 'app.example.com');
    });

    test('plain http only for localhost and the emulator\'s 10.0.2.2, for development', () {
      expect(parseServerUrl('http://localhost:3000')?.toString(), 'http://localhost:3000');
      expect(parseServerUrl('http://10.0.2.2:3000')?.toString(), 'http://10.0.2.2:3000');
      expect(parseServerUrl('http://localhost')?.toString(), 'http://localhost');
    });

    test('everything else is refused', () {
      const refused = [
        '',
        '   ',
        'example.com',
        'app.example.com:3000',
        'ftp://example.com',
        'javascript:alert(1)',
        'http://example.com',
        'http://192.168.1.5:3000',
        'http://127.0.0.1:3000',
        'http://localhost.evil.com',
        'http://10.0.2.20',
        'https://',
        'https:///path',
        'https://user:secret@example.com',
        'https://example.com?next=1',
        'https://example.com/#frag',
        'https://exa mple.com',
        'https://example.com:99999',
      ];
      for (final raw in refused) {
        expect(parseServerUrl(raw), isNull, reason: '"$raw"');
      }
    });
  });

  group('the server the app talks to', () {
    late FakeAuthApi auth;
    late FakeSettingsStore settings;
    late FakeWidgetStore widget;
    late FakeCacheStore homeCache;

    setUp(() {
      auth = FakeAuthApi();
      settings = FakeSettingsStore();
      widget = FakeWidgetStore();
      homeCache = FakeCacheStore();
    });

    ProviderContainer containerWith({bool fakeAuth = true, InitialSettings? initial}) {
      final container = ProviderContainer(
        overrides: [
          if (fakeAuth) authApiProvider.overrideWithValue(auth),
          settingsStoreProvider.overrideWithValue(settings),
          widgetStoreProvider.overrideWithValue(widget),
          homeCacheStoreProvider.overrideWithValue(homeCache),
          if (initial != null) initialSettingsProvider.overrideWithValue(initial),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('it defaults to the Lukitas server', () {
      final container = containerWith();
      expect(container.read(serverUrlProvider), defaultServerUrl);
      expect(defaultServerUrl.toString(), 'https://app-lukas.andersonlaverde.com');
    });

    test('changing it signs out and points every call there', () async {
      mockStorage(token: 'email-token-0');
      widget.saved[widgetSnapshotKey] = '{"v":1}';
      homeCache.value = '{"v":1}';
      final container = containerWith(fakeAuth: false);
      container.read(sessionProvider);
      await container.read(sessionProvider.notifier).ready;
      expect(
        container.read(apiClientProvider).baseUrl,
        'https://app-lukas.andersonlaverde.com/api',
      );

      final changed = await container
          .read(serverUrlProvider.notifier)
          .change('https://my.server.org');

      expect(changed, isTrue);
      expect(container.read(serverUrlProvider).toString(), 'https://my.server.org');
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(await SessionStore().read(), isNull);
      expect(widget.saved, isEmpty);
      expect(homeCache.value, isNull);
      // The API client, and the auth calls, now go to the new server.
      expect(container.read(apiClientProvider).baseUrl, 'https://my.server.org/api');
      final authApi = container.read(authApiProvider) as HttpAuthApi;
      expect(authApi.dio.options.baseUrl, 'https://my.server.org/api');
    });

    test('the old server is told about the sign-out, before the new one is used', () async {
      mockStorage(token: 'email-token-0');
      final container = containerWith();
      await container.read(sessionProvider.notifier).ready;
      await container.read(serverUrlProvider.notifier).change('https://my.server.org');
      expect(auth.calls.where((c) => c.startsWith('signOut')), ['signOut email-token-0']);
    });

    test('a guest who was warned is signed out too (the screen asks first)', () async {
      mockStorage(token: 'guest-token-0', guest: true);
      auth.guests['guest-token-0'] = true;
      final container = containerWith();
      await container.read(sessionProvider.notifier).ready;
      await container.read(serverUrlProvider.notifier).change('https://my.server.org');
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
    });

    test('the choice is kept, and the next start uses it', () async {
      final container = containerWith();
      await container.read(serverUrlProvider.notifier).change('https://my.server.org/');
      expect(settings.values[serverUrlKey], 'https://my.server.org');

      final initial = await InitialSettings.read(settings);
      expect(initial.serverUrl.toString(), 'https://my.server.org');
      final next = containerWith(initial: initial);
      expect(next.read(serverUrlProvider).toString(), 'https://my.server.org');
    });

    test('an invalid URL is refused: nothing is signed out and nothing changes', () async {
      mockStorage(token: 'email-token-0');
      final container = containerWith();
      await container.read(sessionProvider.notifier).ready;

      for (final raw in ['', 'http://example.com', 'nonsense']) {
        expect(await container.read(serverUrlProvider.notifier).change(raw), isFalse, reason: raw);
      }

      expect(container.read(serverUrlProvider), defaultServerUrl);
      expect(container.read(sessionProvider).status, SessionStatus.signedIn);
      expect(auth.calls.where((c) => c.startsWith('signOut')), isEmpty);
      expect(settings.values, isEmpty);
    });

    test('the same server again changes nothing and keeps the session', () async {
      mockStorage(token: 'email-token-0');
      final container = containerWith();
      await container.read(sessionProvider.notifier).ready;
      final changed = await container
          .read(serverUrlProvider.notifier)
          .change('https://app-lukas.andersonlaverde.com/');
      expect(changed, isTrue);
      expect(container.read(sessionProvider).status, SessionStatus.signedIn);
    });

    test('a stored URL that is no longer valid falls back to the default', () async {
      settings.values[serverUrlKey] = 'http://evil.example.com';
      final initial = await InitialSettings.read(settings);
      expect(initial.serverUrl, defaultServerUrl);
    });
  });
}
