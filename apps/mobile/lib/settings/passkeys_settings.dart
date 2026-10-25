// What Settings does with the person's passkeys: the web's apps/web/app/features/settings/passkeys.ts
// (`PasskeysApi`, `livePasskeys`) and `passkeyOutcome`/`addPasskey` of apps/web/app/auth/passkey.ts, on
// the phone: Better Auth's routes for the list and the delete, Credential Manager for the new one.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/auth_api.dart';
import '../api/session.dart';

export '../api/auth_api.dart' show PasskeyItem;

/// What adding a passkey came to; `cancelled` is the person closing the phone's prompt.
enum PasskeyOutcome { added, cancelled, failed }

/// What the settings card asks of passkeys, as an interface so tests can stand in for Better Auth
/// and Credential Manager (the web passes the same four as a prop).
abstract interface class SettingsPasskeys {
  /// Whether this phone can make one (Android 14 or newer with a passkey manager). Listing and
  /// deleting work anyway.
  Future<bool> supported();

  /// The signed-in account's passkeys, oldest first; throws when they cannot be read.
  Future<List<PasskeyItem>> list();

  /// Makes one: the phone asks for the fingerprint or face. Never throws.
  Future<PasskeyOutcome> add();

  /// Deletes one; throws when the server says no.
  Future<void> remove(String id);
}

/// How the phone's and the server's answers to an add come out: closing the prompt is not a failure
/// worth a message, and a passkey the phone already has counts as added (the web's `passkeyOutcome`).
PasskeyOutcome passkeyOutcome(Object? error) {
  if (error == null) return PasskeyOutcome.added;
  if (error is AuthFailure) {
    switch (error.code) {
      case 'AUTH_CANCELLED':
        return PasskeyOutcome.cancelled;
      case 'ERROR_AUTHENTICATOR_PREVIOUSLY_REGISTERED':
        return PasskeyOutcome.added;
    }
  }
  return PasskeyOutcome.failed;
}

/// [SettingsPasskeys] over the session's token, the auth server and the phone's Credential Manager.
class LiveSettingsPasskeys implements SettingsPasskeys {
  LiveSettingsPasskeys(this._ref);

  final Ref _ref;

  /// The session's token; none means the session is gone.
  String _token() {
    final token = _ref.read(sessionProvider).stored?.token;
    if (token == null) throw const AuthFailure(code: 'UNAUTHORIZED', status: 401);
    return token;
  }

  /// [call], ending the session when the server no longer knows it (as the other screens do).
  Future<T> _asked<T>(Future<T> Function(String token) call) async {
    try {
      return await call(_token());
    } on AuthFailure catch (failure) {
      if (failure.status == 401) {
        unawaited(_ref.read(sessionProvider.notifier).signOut(discardGuest: true));
      }
      rethrow;
    }
  }

  @override
  Future<bool> supported() => _ref.read(passkeysProvider).supported();

  @override
  Future<List<PasskeyItem>> list() =>
      _asked((token) => _ref.read(authApiProvider).listPasskeys(token));

  @override
  Future<PasskeyOutcome> add() async {
    try {
      await _ref.read(sessionProvider.notifier).registerPasskey();
      return PasskeyOutcome.added;
    } on Object catch (error) {
      return passkeyOutcome(error);
    }
  }

  @override
  Future<void> remove(String id) =>
      _asked((token) => _ref.read(authApiProvider).deletePasskey(token, id));
}

final settingsPasskeysProvider = Provider<SettingsPasskeys>(LiveSettingsPasskeys.new);
