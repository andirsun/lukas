import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_api.dart';

/// The phone's passkeys: Android's Credential Manager through `androidx.credentials` only, never
/// Play Services (android/.../passkeys/PasskeyChannel.kt).
abstract interface class Passkeys {
  /// True only on Android 14 (API 34) or newer with a passkey provider installed: below that,
  /// `androidx.credentials` needs Play Services, which this app never ships.
  Future<bool> supported();

  /// Shows the phone's passkey prompt for these WebAuthn request options; returns the assertion as
  /// JSON. Throws [AuthFailure] with `AUTH_CANCELLED` when the person closes the prompt,
  /// `NO_CREDENTIAL` when there is no passkey for this server, `PASSKEY_FAILED` otherwise.
  Future<String> get(String optionsJson);

  /// Like [get], but only for a passkey the phone can offer at once (Credential Manager's
  /// "prefer immediately available credentials"): when there is none, nothing is shown and it
  /// throws `NO_CREDENTIAL` at once. A provider such as Proton Pass that holds a Lukitas passkey
  /// (made on the web, say) has its sheet appear; closing it throws `AUTH_CANCELLED`.
  Future<String> getAvailable(String optionsJson);

  /// Creates a passkey for these WebAuthn creation options; returns the attestation as JSON.
  /// Throws as [get] does.
  Future<String> create(String optionsJson);
}

/// [Passkeys] over the `lukitas/passkeys` platform channel.
class PlatformPasskeys implements Passkeys {
  const PlatformPasskeys();

  static const _channel = MethodChannel('lukitas/passkeys');

  static const _codes = {'cancelled': 'AUTH_CANCELLED', 'no_credential': 'NO_CREDENTIAL'};

  @override
  Future<bool> supported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> _call(String method, String optionsJson) async {
    try {
      final json = await _channel.invokeMethod<String>(method, optionsJson);
      if (json == null) throw const AuthFailure(code: 'PASSKEY_FAILED', status: 400);
      return json;
    } on PlatformException catch (error) {
      throw AuthFailure(code: _codes[error.code] ?? 'PASSKEY_FAILED', status: 400);
    } on MissingPluginException {
      throw const AuthFailure(code: 'PASSKEY_FAILED', status: 400);
    }
  }

  @override
  Future<String> get(String optionsJson) => _call('get', optionsJson);

  @override
  Future<String> getAvailable(String optionsJson) => _call('getAvailable', optionsJson);

  @override
  Future<String> create(String optionsJson) => _call('create', optionsJson);
}

final passkeysProvider = Provider<Passkeys>((ref) => const PlatformPasskeys());

/// Whether to offer "Entrar con huella": [Passkeys.supported], asked once.
final passkeysSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(passkeysProvider).supported(),
);

/// Whether this phone can use passkeys (Android 14+ with a provider), for code outside widgets.
Future<bool> passkeysSupported([Passkeys passkeys = const PlatformPasskeys()]) =>
    passkeys.supported();
