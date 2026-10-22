import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/auth_api.dart';
import 'package:lukitas/api/passkeys.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/widget_snapshot.dart';

import '../entry/fakes.dart';
import '../home/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionStore', () {
    setUp(mockStorage);

    test('is empty at first, keeps what is written, and forgets it on clear', () async {
      final store = SessionStore();
      expect(await store.read(), isNull);

      await store.write('abc', guest: true);
      final stored = await store.read();
      expect(stored?.token, 'abc');
      expect(stored?.guest, isTrue);

      await store.write('def', guest: false);
      expect((await store.read())?.guest, isFalse);

      await store.clear();
      expect(await store.read(), isNull);
    });

    test('a token stored without the guest flag reads as a guest (the safe side)', () async {
      FlutterSecureStorage.setMockInitialValues({SessionStore.tokenKey: 'abc'});
      expect((await SessionStore().read())?.guest, isTrue);
    });
  });

  group('SessionController', () {
    late FakeAuthApi auth;
    late FakePasskeys passkeys;
    late FakeWidgetStore widget;
    late FakeCacheStore homeCache;

    ProviderContainer containerWith() {
      final container = ProviderContainer(
        overrides: [
          authApiProvider.overrideWithValue(auth),
          passkeysProvider.overrideWithValue(passkeys),
          widgetStoreProvider.overrideWithValue(widget),
          homeCacheStoreProvider.overrideWithValue(homeCache),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<SessionController> ready(ProviderContainer container) async {
      final controller = container.read(sessionProvider.notifier);
      await controller.ready;
      return controller;
    }

    setUp(() {
      auth = FakeAuthApi();
      passkeys = FakePasskeys();
      widget = FakeWidgetStore();
      homeCache = FakeCacheStore();
      mockStorage();
    });

    test('starts signed out with nothing stored', () async {
      final container = containerWith();
      await ready(container);
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
    });

    test('startGuest stores a guest session', () async {
      final container = containerWith();
      final controller = await ready(container);
      await controller.startGuest();

      final state = container.read(sessionProvider);
      expect(state.status, SessionStatus.signedIn);
      expect(state.stored?.token, 'guest-token-1');
      expect(state.stored?.guest, isTrue);
      expect((await SessionStore().read())?.guest, isTrue);
    });

    test('sendCode and verifyCode sign in with an email', () async {
      final container = containerWith();
      final controller = await ready(container);
      await controller.sendCode('ana@correo.com');
      await controller.verifyCode('ana@correo.com', '123456');

      expect(auth.calls, ['sendCode ana@correo.com', 'verifyCode ana@correo.com 123456']);
      expect(container.read(sessionProvider).stored?.token, 'email-token-1');
      expect(container.read(sessionProvider).stored?.guest, isFalse);
    });

    group('never discards a guest token on an email sign-in', () {
      setUp(() => mockStorage(token: 'guest-token-0', guest: true));

      test('sendCode, verifyCode and the passkey stop with GuestInTheWay', () async {
        auth.guests['guest-token-0'] = true;
        final container = containerWith();
        final controller = await ready(container);

        await expectLater(controller.sendCode('ana@correo.com'), throwsA(isA<GuestInTheWay>()));
        await expectLater(
          controller.verifyCode('ana@correo.com', '123456'),
          throwsA(isA<GuestInTheWay>()),
        );
        await expectLater(controller.signInWithPasskey(), throwsA(isA<GuestInTheWay>()));

        expect(auth.calls.where((c) => !c.startsWith('isGuest')), isEmpty);
        expect(passkeys.calls, isEmpty);
        expect(container.read(sessionProvider).stored?.token, 'guest-token-0');
        expect((await SessionStore().read())?.token, 'guest-token-0');
      });

      test('claiming the email keeps the same token and user, no longer a guest', () async {
        auth.guests['guest-token-0'] = true;
        final container = containerWith();
        final controller = await ready(container);

        await controller.claimEmail('ana@correo.com');
        await controller.confirmClaim('ana@correo.com', '111222');

        expect(auth.calls.where((c) => !c.startsWith('isGuest')), [
          'claimSend guest-token-0 ana@correo.com',
          'claimVerify guest-token-0 ana@correo.com 111222',
        ]);
        final stored = await SessionStore().read();
        expect(stored?.token, 'guest-token-0');
        expect(stored?.guest, isFalse);
      });

      test('replaceGuest: true, once the person was warned, signs in as the email', () async {
        auth.guests['guest-token-0'] = true;
        final container = containerWith();
        final controller = await ready(container);

        await controller.sendCode('ana@correo.com', replaceGuest: true);
        await controller.verifyCode('ana@correo.com', '123456', replaceGuest: true);

        expect(container.read(sessionProvider).stored?.token, 'email-token-1');
      });

      test("a replaced guest's home cache and widget figures are cleared", () async {
        auth.guests['guest-token-0'] = true;
        homeCache.value = '{"v":1}';
        widget.saved[widgetSnapshotKey] = '{"v":1}';
        final container = containerWith();
        final controller = await ready(container);

        await controller.verifyCode('ana@correo.com', '123456', replaceGuest: true);

        expect(container.read(sessionProvider).stored?.token, 'email-token-1');
        expect(homeCache.value, isNull);
        expect(widget.saved, isEmpty);
      });

      test('claiming an email keeps the same token, so the cache stays', () async {
        homeCache.value = '{"v":1}';
        final container = containerWith();
        final controller = await ready(container);

        await controller.claimEmail('ana@correo.com');
        await controller.confirmClaim('ana@correo.com', '123456');

        expect(homeCache.value, '{"v":1}');
      });

      test('a guest whose stored flag is stale is still caught by /v1/me', () async {
        mockStorage(token: 'guest-token-0', guest: false);
        auth.guests['guest-token-0'] = true;
        final container = containerWith();
        final controller = await ready(container);
        await controller.refreshed;

        await expectLater(controller.sendCode('ana@correo.com'), throwsA(isA<GuestInTheWay>()));
      });
    });

    test('a claim needs a guest session', () async {
      mockStorage(token: 'email-token-0');
      final container = containerWith();
      final controller = await ready(container);
      await expectLater(controller.claimEmail('ana@correo.com'), throwsA(isA<StateError>()));
    });

    test('signInWithPasskey asks the phone with the server options and keeps the token', () async {
      final container = containerWith();
      final controller = await ready(container);
      await controller.signInWithPasskey();

      expect(passkeys.calls, ['get {"challenge":"sign-in"}']);
      expect(auth.calls, ['passkeySignInOptions', 'passkeySignIn {"assertion":true}']);
      expect(container.read(sessionProvider).stored?.token, 'passkey-token-1');
    });

    test('registerPasskey adds a passkey to the signed-in user, guest or not', () async {
      final container = containerWith();
      final controller = await ready(container);
      await controller.startGuest();
      await controller.registerPasskey();

      expect(passkeys.calls, ['create {"challenge":"register"}']);
      expect(auth.calls.skip(1), [
        'passkeyRegisterOptions guest-token-1',
        'passkeyRegister guest-token-1 {"attestation":true}',
      ]);
      // Still the same guest session.
      expect(container.read(sessionProvider).stored?.token, 'guest-token-1');
    });

    test('a cancelled passkey prompt changes nothing', () async {
      final container = containerWith();
      final controller = await ready(container);
      passkeys.failure = const AuthFailure(code: 'AUTH_CANCELLED', status: 400);

      await expectLater(controller.signInWithPasskey(), throwsA(isA<AuthFailure>()));
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
    });

    test('signOut forgets the session', () async {
      mockStorage(token: 'email-token-0');
      final container = containerWith();
      final controller = await ready(container);
      await controller.signOut();

      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(await SessionStore().read(), isNull);
      expect(auth.calls.last, 'signOut email-token-0');
    });

    test("signOut also wipes the widget's figures: they are the person's", () async {
      mockStorage(token: 'email-token-0');
      widget.saved[widgetSnapshotKey] = '{"v":1}';
      final container = containerWith();
      final controller = await ready(container);
      await controller.signOut();

      expect(widget.saved, isEmpty);
    });

    test('signOut also wipes the home cache: the next person must never see it', () async {
      mockStorage(token: 'email-token-0');
      homeCache.value = '{"v":1}';
      final container = containerWith();
      final controller = await ready(container);
      await controller.signOut();

      expect(homeCache.value, isNull);
    });

    test('a session the server no longer knows wipes the home cache too', () async {
      mockStorage(token: 'stale-token');
      homeCache.value = '{"v":1}';
      auth.failures['isGuest'] = const AuthFailure(status: 401);
      final container = containerWith();
      final controller = await ready(container);
      await controller.refreshed;

      expect(homeCache.value, isNull);
    });

    test("a session the server no longer knows wipes the widget's figures too", () async {
      mockStorage(token: 'stale-token');
      widget.saved[widgetSnapshotKey] = '{"v":1}';
      auth.failures['isGuest'] = const AuthFailure(status: 401);
      final container = containerWith();
      final controller = await ready(container);
      await controller.refreshed;

      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(widget.saved, isEmpty);
    });
  });

  test('passkeysSupported is false where the platform cannot answer', () async {
    expect(await const PlatformPasskeys().supported(), isFalse);
  });
}
