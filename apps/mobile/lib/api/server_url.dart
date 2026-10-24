import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/initial_settings.dart';
import '../settings/settings_store.dart';
import 'server_address.dart';
import 'session.dart';

export 'server_address.dart';

/// The server the app talks to (spec section 6.1): the Lukitas one until the person changes it in
/// Settings. Everything that calls the API watches this, so a change points every call at the new
/// server at once.
class ServerUrl extends Notifier<Uri> {
  @override
  Uri build() => ref.watch(initialSettingsProvider).serverUrl;

  /// Points the app at [raw]. Another server is another set of accounts, so the session is ended
  /// first (and the old server told, as well as it can): the caller has already warned a guest.
  /// Returns false, changing nothing, when [raw] is not an address the app may talk to.
  Future<bool> change(String raw) async {
    final next = parseServerUrl(raw);
    if (next == null) return false;
    if (next == state) return true;
    await ref.read(sessionProvider.notifier).signOut(discardGuest: true);
    try {
      await ref.read(settingsStoreProvider).write(serverUrlKey, next.toString());
    } on Object {
      // Not kept: the next start goes back to the old server.
    }
    state = next;
    return true;
  }
}

final serverUrlProvider = NotifierProvider<ServerUrl, Uri>(ServerUrl.new);
