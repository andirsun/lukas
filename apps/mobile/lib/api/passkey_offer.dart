// When the app offers a passkey, and what it keeps about the answer: the web's
// apps/web/app/auth/passkey.ts (`shouldOfferPasskey`, `offerDecided`, `rememberOfferDecided`,
// `passkeyOutcome`) on the phone.
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_store.dart';
import 'auth_api.dart';
import 'passkeys.dart';

/// The ids of the accounts that answered the offer ("Crear mi huella" or "Ahora no") on this phone,
/// kept as the web keeps them in `localStorage` (`lukas.passkey.offered`): the offer is made once per
/// account per device.
const passkeyOfferedKey = 'passkey.offered';

/// Whether to offer a passkey right after an email sign-in, and the answer once given.
///
/// The offer is due when this phone can use passkeys, the account has not answered on this phone,
/// and the account has no passkey yet (on any device). The cheap local checks come first; if the
/// list cannot be read, the offer is skipped, never waited on.
class PasskeyOffer {
  PasskeyOffer({required this.auth, required this.passkeys, required this.store});

  final AuthApi auth;
  final Passkeys passkeys;
  final SettingsStore store;

  Future<List<String>> _decided() async {
    try {
      final parsed = jsonDecode(await store.read(passkeyOfferedKey) ?? '[]');
      return parsed is List ? parsed.whereType<String>().toList() : [];
    } on Object {
      return [];
    }
  }

  /// The most the lookup is given: signing in never waits longer than this on the offer.
  static const lookupWait = Duration(seconds: 3);

  /// The id of the account behind [token] when it is to be offered a passkey, else null: also when
  /// the answers take longer than [lookupWait] (what comes late is dropped).
  Future<String?> dueFor(String token) async {
    try {
      return await _dueFor(token).timeout(lookupWait);
    } on Object {
      return null;
    }
  }

  Future<String?> _dueFor(String token) async {
    if (!await passkeys.supported()) return null;
    final id = await auth.accountId(token);
    if ((await _decided()).contains(id)) return null;
    return await auth.passkeyCount(token) == 0 ? id : null;
  }

  /// The account answered: it is not asked again on this phone.
  Future<void> decide(String accountId) async {
    final ids = await _decided();
    if (ids.contains(accountId)) return;
    try {
      await store.write(passkeyOfferedKey, jsonEncode([...ids, accountId]));
    } on Object {
      // Not kept: it may be asked again, and nothing breaks.
    }
  }
}

final passkeyOfferProvider = Provider<PasskeyOffer>(
  (ref) => PasskeyOffer(
    auth: ref.watch(authApiProvider),
    passkeys: ref.watch(passkeysProvider),
    store: ref.watch(settingsStoreProvider),
  ),
);
