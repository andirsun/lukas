import 'dart:async';
import 'dart:io';

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

/// What happened, in order, across the widget's store and the session's.
final _log = <String>[];

class _LoggedWidgetStore extends FakeWidgetStore {
  @override
  Future<void> save(String key, String value) async {
    await super.save(key, value);
    _log.add(value.contains('"signedIn":false') ? 'widget signed out' : 'widget figures');
  }

  @override
  Future<void> updateWidgets() async {
    await super.updateWidgets();
    _log.add('widgets redrawn');
  }
}

class _LoggedSessionStore extends SessionStore {
  @override
  Future<void> clear() async {
    _log.add('session cleared');
    await super.clear();
  }
}

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

      // Then, as the phone has passkeys, whether to offer one (test/entry/passkey_offer_flow_test.dart),
      // with the new session's token.
      expect(auth.calls, [
        'sendCode ana@correo.com',
        'verifyCode ana@correo.com 123456',
        'accountId email-token-1',
        'passkeyCount email-token-1',
        // And whether the account still has the welcome to do (test/api/onboarding_session_test.dart).
        'isGuest email-token-1',
      ]);
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
          // The guest's start was its welcome.
          'completeOnboarding guest-token-0',
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
        expect(widgetSignedOut(widget), isTrue);
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
      expect(auth.calls, [
        'passkeySignInOptions',
        'passkeySignIn {"assertion":true}',
        'isGuest passkey-token-1',
      ]);
      expect(container.read(sessionProvider).stored?.token, 'passkey-token-1');
      expect(container.read(sessionProvider).isGuest, isFalse);
    });

    test("a guest's passkey signs them back in as a guest", () async {
      auth.passkeyBelongsToGuest = true;
      final container = containerWith();
      final controller = await ready(container);
      await controller.signInWithPasskey();

      expect(container.read(sessionProvider).isGuest, isTrue);
      expect((await SessionStore().read())?.guest, isTrue);
      // So signing out warns first, as for any guest.
      await expectLater(controller.signOut(), throwsA(isA<GuestInTheWay>()));
    });

    test('a passkey sign-in whose guest check fails is kept as a guest (the safe side)', () async {
      final container = containerWith();
      final controller = await ready(container);
      auth.failures['isGuest'] = const AuthFailure(code: 'NETWORK', status: 0);
      await controller.signInWithPasskey();

      expect(container.read(sessionProvider).stored?.token, 'passkey-token-1');
      expect(container.read(sessionProvider).isGuest, isTrue);
    });

    group('signInWithAvailablePasskey (the email screen, on opening)', () {
      test('asks only for what the phone has at once, and signs in with it', () async {
        passkeys.hasPasskey = true;
        final container = containerWith();
        final controller = await ready(container);

        expect(await controller.signInWithAvailablePasskey(), isTrue);
        expect(passkeys.calls, ['getAvailable {"challenge":"sign-in"}']);
        expect(container.read(sessionProvider).stored?.token, 'passkey-token-1');
        expect(container.read(sessionProvider).isGuest, isFalse);
      });

      test('with none to offer, or the sheet closed, it is false and nothing changes', () async {
        final container = containerWith();
        final controller = await ready(container);

        expect(await controller.signInWithAvailablePasskey(), isFalse);
        passkeys.hasPasskey = true;
        passkeys.failure = const AuthFailure(code: 'AUTH_CANCELLED', status: 400);
        expect(await controller.signInWithAvailablePasskey(), isFalse);
        expect(container.read(sessionProvider).status, SessionStatus.signedOut);
        expect(auth.calls.where((c) => c.startsWith('passkeySignIn ')), isEmpty);
      });

      test('no connection for the challenge is as silent: the email is there', () async {
        passkeys.hasPasskey = true;
        final container = containerWith();
        final controller = await ready(container);
        auth.failures['passkeySignInOptions'] = const AuthFailure(code: 'NETWORK', status: 0);

        expect(await controller.signInWithAvailablePasskey(), isFalse);
        expect(passkeys.calls, isEmpty);
      });

      test('a passkey the person chose and the server refuses is an AuthFailure', () async {
        passkeys.hasPasskey = true;
        final container = containerWith();
        final controller = await ready(container);
        auth.failures['passkeySignIn'] = const AuthFailure(code: 'PASSKEY_NOT_FOUND', status: 401);

        await expectLater(controller.signInWithAvailablePasskey(), throwsA(isA<AuthFailure>()));
        expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      });

      test('never discards a guest token: GuestInTheWay, and the phone is not asked', () async {
        mockStorage(token: 'guest-token-0', guest: true);
        auth.guests['guest-token-0'] = true;
        passkeys.hasPasskey = true;
        final container = containerWith();
        final controller = await ready(container);

        await expectLater(controller.signInWithAvailablePasskey(), throwsA(isA<GuestInTheWay>()));
        expect(passkeys.calls, isEmpty);
        expect(container.read(sessionProvider).stored?.token, 'guest-token-0');
      });
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

    test(
      'signOut of a guest throws GuestInTheWay and keeps the session, the widget and the cache',
      () async {
        mockStorage(token: 'guest-token-0', guest: true);
        auth.guests['guest-token-0'] = true;
        widget.saved[widgetSnapshotKey] = '{"v":1}';
        homeCache.value = '{"v":1}';
        final container = containerWith();
        final controller = await ready(container);

        await expectLater(controller.signOut(), throwsA(isA<GuestInTheWay>()));

        expect(container.read(sessionProvider).status, SessionStatus.signedIn);
        expect((await SessionStore().read())?.token, 'guest-token-0');
        expect(
          auth.calls,
          isNot(contains('signOut guest-token-0')),
          reason: 'the server is not told',
        );
        expect(widget.saved, isNotEmpty);
        expect(homeCache.value, isNotNull);
      },
    );

    test('a guest who was warned signs out with discardGuest, and everything goes', () async {
      mockStorage(token: 'guest-token-0', guest: true);
      auth.guests['guest-token-0'] = true;
      widget.saved[widgetSnapshotKey] = '{"v":1}';
      homeCache.value = '{"v":1}';
      final container = containerWith();
      final controller = await ready(container);

      await controller.signOut(discardGuest: true);

      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(await SessionStore().read(), isNull);
      expect(auth.calls.last, 'signOut guest-token-0');
      expect(widgetSignedOut(widget), isTrue);
      expect(homeCache.value, isNull);
    });

    test(
      'the old server being down does not stop the sign-out: everything local still goes',
      () async {
        mockStorage(token: 'email-token-0');
        widget.saved[widgetSnapshotKey] = '{"v":1}';
        homeCache.value = '{"v":1}';
        auth.failures['signOut'] = const AuthFailure(status: 0);
        final container = containerWith();
        final controller = await ready(container);

        await controller.signOut();

        expect(auth.calls, contains('signOut email-token-0'));
        expect(container.read(sessionProvider).status, SessionStatus.signedOut);
        expect(await SessionStore().read(), isNull);
        expect(widgetSignedOut(widget), isTrue);
        expect(homeCache.value, isNull);
      },
    );

    test('any error from the server call still signs out locally, whatever it is', () async {
      final errors = <String, Object>{
        'socket': const SocketException('Connection refused'),
        'tls': const HandshakeException('bad certificate'),
        'http': const HttpException('closed'),
        'bug': StateError('unexpected'),
      };
      for (final entry in errors.entries) {
        mockStorage(token: 'email-token-0');
        widget.saved[widgetSnapshotKey] = '{"v":1}';
        homeCache.value = '{"v":1}';
        auth.failures['signOut'] = entry.value;
        final container = containerWith();
        final controller = await ready(container);

        await controller.signOut();

        expect(container.read(sessionProvider).status, SessionStatus.signedOut, reason: entry.key);
        expect(await SessionStore().read(), isNull, reason: entry.key);
        expect(widgetSignedOut(widget), isTrue, reason: entry.key);
        expect(homeCache.value, isNull, reason: entry.key);
      }
    });

    test('a 5xx from the server still signs out locally', () async {
      mockStorage(token: 'email-token-0');
      widget.saved[widgetSnapshotKey] = '{"v":1}';
      homeCache.value = '{"v":1}';
      auth.failures['signOut'] = const AuthFailure(status: 503);
      final container = containerWith();
      final controller = await ready(container);
      await controller.signOut();
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(widgetSignedOut(widget), isTrue);
      expect(homeCache.value, isNull);
    });

    testWidgets('a server that never answers is waited for 10 seconds at most', (tester) async {
      mockStorage(token: 'email-token-0');
      widget.saved[widgetSnapshotKey] = '{"v":1}';
      homeCache.value = '{"v":1}';
      auth.holdSignOut = Completer<void>();
      final container = containerWith();
      final controller = await ready(container);

      var done = false;
      unawaited(controller.signOut().then((_) => done = true));
      await tester.pump(const Duration(seconds: 9));
      expect(done, isFalse, reason: 'still waiting for the server');
      expect(container.read(sessionProvider).status, SessionStatus.signedIn);

      await tester.pump(const Duration(seconds: 2));
      expect(done, isTrue);
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(widgetSignedOut(widget), isTrue);
      expect(homeCache.value, isNull);
    });

    group('the widget is signed out before the session is forgotten', () {
      // If the process dies in between, the widget must not keep the figure: with the session
      // still there, the next start (or refresh) finds it and puts things right.
      ProviderContainer ordered() {
        _log.clear();
        final container = ProviderContainer(
          overrides: [
            authApiProvider.overrideWithValue(auth),
            passkeysProvider.overrideWithValue(passkeys),
            widgetStoreProvider.overrideWithValue(_LoggedWidgetStore()),
            sessionStoreProvider.overrideWithValue(_LoggedSessionStore()),
            homeCacheStoreProvider.overrideWithValue(homeCache),
          ],
        );
        addTearDown(container.dispose);
        return container;
      }

      test('on sign-out', () async {
        mockStorage(token: 'email-token-0');
        final container = ordered();
        await ready(container).then((c) => c.signOut());
        expect(_log, ['widget signed out', 'widgets redrawn', 'session cleared']);
      });

      test('when the server no longer knows the session', () async {
        mockStorage(token: 'stale-token');
        auth.failures['isGuest'] = const AuthFailure(status: 401);
        final container = ordered();
        await (await ready(container)).refreshed;
        expect(_log, ['widget signed out', 'widgets redrawn', 'session cleared']);
      });
    });

    test("signOut also wipes the widget's figures: they are the person's", () async {
      mockStorage(token: 'email-token-0');
      widget.saved[widgetSnapshotKey] = '{"v":1}';
      final container = containerWith();
      final controller = await ready(container);
      await controller.signOut();

      expect(widgetSignedOut(widget), isTrue);
      // And the widgets on the home screen are redrawn with it.
      await Future<void>.delayed(Duration.zero);
      expect(widget.updates, greaterThan(0));
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
      expect(widgetSignedOut(widget), isTrue);
    });
  });

  test('passkeysSupported is false where the platform cannot answer', () async {
    expect(await const PlatformPasskeys().supported(), isFalse);
  });
}
