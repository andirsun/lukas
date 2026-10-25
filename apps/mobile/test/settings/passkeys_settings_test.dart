// What Settings does with passkeys, as the web's `livePasskeys` and `addPasskey` do
// (apps/web/app/features/settings/passkeys.ts, apps/web/app/auth/passkey.ts): list, add, delete.
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/auth_api.dart';
import 'package:lukitas/settings/passkeys_settings.dart';

import '../entry/fakes.dart';
import 'harness.dart';

void main() {
  testWidgets('lists the account\'s passkeys with the session\'s token, oldest first', (t) async {
    final auth = FakeAuthApi()
      ..passkeyItems.addAll([
        PasskeyItem(id: 'a', createdAt: DateTime.utc(2026, 10, 2, 9), synced: true),
        PasskeyItem(id: 'b', name: 'Pixel', createdAt: DateTime.utc(2026, 10, 5, 10)),
      ]);
    final env = await pumpSettingsApp(t, auth: auth);
    final passkeys = env.container.read(settingsPasskeysProvider);
    final items = await passkeys.list();
    expect(items.map((p) => p.id), ['a', 'b']);
    expect(auth.calls, contains('listPasskeys email-token-0'));
  });

  testWidgets('says whether this phone can make one', (t) async {
    final env = await pumpSettingsApp(t, passkeysSupported: true);
    expect(await env.container.read(settingsPasskeysProvider).supported(), isTrue);
    env.passkeys.isSupported = false;
    expect(await env.container.read(settingsPasskeysProvider).supported(), isFalse);
  });

  group('adding one', () {
    testWidgets('asks the phone and tells the server: it is added', (t) async {
      final env = await pumpSettingsApp(t, passkeysSupported: true);
      final outcome = await env.container.read(settingsPasskeysProvider).add();
      expect(outcome, PasskeyOutcome.added);
      expect(env.auth.calls, contains('passkeyRegisterOptions email-token-0'));
      expect(env.auth.calls.any((c) => c.startsWith('passkeyRegister email-token-0')), isTrue);
      expect(env.auth.passkeyItems, hasLength(1));
    });

    testWidgets('closing the phone\'s prompt is silent: cancelled, nothing sent', (t) async {
      final env = await pumpSettingsApp(t, passkeysSupported: true);
      env.passkeys.failure = const AuthFailure(code: 'AUTH_CANCELLED', status: 400);
      final outcome = await env.container.read(settingsPasskeysProvider).add();
      expect(outcome, PasskeyOutcome.cancelled);
      expect(env.auth.passkeyItems, isEmpty);
    });

    testWidgets('a passkey this phone already has counts as added', (t) async {
      final env = await pumpSettingsApp(t, passkeysSupported: true);
      env.passkeys.failure = const AuthFailure(
        code: 'ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED',
        status: 400,
      );
      expect(await env.container.read(settingsPasskeysProvider).add(), PasskeyOutcome.added);
    });

    testWidgets('anything else that goes wrong is a failure, never a crash', (t) async {
      final env = await pumpSettingsApp(t, passkeysSupported: true);
      final passkeys = env.container.read(settingsPasskeysProvider);
      env.passkeys.failure = const AuthFailure(code: 'PASSKEY_FAILED', status: 400);
      expect(await passkeys.add(), PasskeyOutcome.failed);
      env.auth.failures['passkeyRegister'] = const AuthFailure(status: 0);
      expect(await passkeys.add(), PasskeyOutcome.failed);
      env.auth.failures['passkeyRegisterOptions'] = StateError('a bug');
      expect(await passkeys.add(), PasskeyOutcome.failed);
    });
  });

  testWidgets('deletes one by its id', (t) async {
    final auth = FakeAuthApi()
      ..passkeyItems.add(PasskeyItem(id: 'a', createdAt: DateTime.utc(2026, 10, 2)));
    final env = await pumpSettingsApp(t, auth: auth);
    await env.container.read(settingsPasskeysProvider).remove('a');
    expect(auth.calls, contains('deletePasskey a'));
    expect(auth.passkeyItems, isEmpty);
  });
}
