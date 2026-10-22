import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/auth_api.dart';
import 'package:lukitas/api/passkeys.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/app.dart';

/// An auth server in memory: records every call, answers with made-up tokens, and fails a call
/// when told to.
class FakeAuthApi implements AuthApi {
  final calls = <String>[];

  /// The failure the next call of that name throws (then cleared).
  final failures = <String, AuthFailure>{};

  /// What `GET /v1/me` says about `isAnonymous`, per token.
  final guests = <String, bool>{};

  var _tokens = 0;
  String _newToken(String kind) => '$kind-token-${++_tokens}';

  void _fail(String name) {
    final failure = failures.remove(name);
    if (failure != null) throw failure;
  }

  @override
  Future<String> signInAsGuest() async {
    calls.add('signInAsGuest');
    _fail('signInAsGuest');
    final token = _newToken('guest');
    guests[token] = true;
    return token;
  }

  @override
  Future<void> sendCode(String email) async {
    calls.add('sendCode $email');
    _fail('sendCode');
  }

  @override
  Future<String> verifyCode(String email, String code) async {
    calls.add('verifyCode $email $code');
    _fail('verifyCode');
    final token = _newToken('email');
    guests[token] = false;
    return token;
  }

  @override
  Future<bool> isGuest(String token) async {
    calls.add('isGuest $token');
    _fail('isGuest');
    return guests[token] ?? false;
  }

  @override
  Future<void> claimSend(String token, String email) async {
    calls.add('claimSend $token $email');
    _fail('claimSend');
  }

  @override
  Future<void> claimVerify(String token, String email, String code) async {
    calls.add('claimVerify $token $email $code');
    _fail('claimVerify');
    guests[token] = false;
  }

  @override
  Future<PasskeyChallenge> passkeySignInOptions() async {
    calls.add('passkeySignInOptions');
    _fail('passkeySignInOptions');
    return const PasskeyChallenge(optionsJson: '{"challenge":"sign-in"}', cookie: 'c=1');
  }

  @override
  Future<String> passkeySignIn(PasskeyChallenge challenge, String responseJson) async {
    calls.add('passkeySignIn $responseJson');
    _fail('passkeySignIn');
    final token = _newToken('passkey');
    guests[token] = false;
    return token;
  }

  @override
  Future<PasskeyChallenge> passkeyRegisterOptions(String token) async {
    calls.add('passkeyRegisterOptions $token');
    _fail('passkeyRegisterOptions');
    return const PasskeyChallenge(optionsJson: '{"challenge":"register"}', cookie: 'c=2');
  }

  @override
  Future<void> passkeyRegister(
    String token,
    PasskeyChallenge challenge,
    String responseJson,
  ) async {
    calls.add('passkeyRegister $token $responseJson');
    _fail('passkeyRegister');
  }

  @override
  Future<void> signOut(String token) async {
    calls.add('signOut $token');
  }
}

/// The phone's passkey prompt, answered at once.
class FakePasskeys implements Passkeys {
  FakePasskeys({this.isSupported = true});

  bool isSupported;
  final calls = <String>[];

  /// Thrown by the next `get` or `create` instead of answering (then cleared).
  AuthFailure? failure;

  @override
  Future<bool> supported() async => isSupported;

  @override
  Future<String> get(String optionsJson) async {
    calls.add('get $optionsJson');
    final error = failure;
    failure = null;
    if (error != null) throw error;
    return '{"assertion":true}';
  }

  @override
  Future<String> create(String optionsJson) async {
    calls.add('create $optionsJson');
    final error = failure;
    failure = null;
    if (error != null) throw error;
    return '{"attestation":true}';
  }
}

/// Secure storage in memory, holding [token] already when given (a returning person).
void mockStorage({String? token, bool guest = false}) {
  FlutterSecureStorage.setMockInitialValues({
    if (token != null) ...{
      SessionStore.tokenKey: token,
      SessionStore.guestKey: guest ? 'true' : 'false',
    },
  });
}

/// The app in Spanish with [auth] and [passkeys] in place of the real server and phone.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  required FakeAuthApi auth,
  FakePasskeys? passkeys,
  Locale locale = const Locale('es'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final container = ProviderContainer(
    overrides: [
      authApiProvider.overrideWithValue(auth),
      passkeysProvider.overrideWithValue(passkeys ?? FakePasskeys(isSupported: false)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const LukitasApp()),
  );
  await tester.pumpAndSettle();
  return container;
}
