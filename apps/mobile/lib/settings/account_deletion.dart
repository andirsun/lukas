// Deleting the account: the web's DeleteAccount.tsx (`DELETE /v1/me`, sign out, and the landing) and
// Review Focus 5 of Stage 3c. The web has a cookie and a query cache to forget; the phone keeps
// more, and none of it may outlive the account: the session, the home cache, the widget's figures,
// the notices (their jobs and any already posted), the voice models, the welcome's draft, the
// answers to the passkey offer and the cards put away on home.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/passkey_offer.dart';
import '../api/session.dart';
import '../capture/models_download.dart';
import '../feedback/stored_flag.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../home/nudges.dart';
import '../notices/notice_platform.dart';
import '../welcome/welcome_controller.dart';
import 'account_repository.dart';
import 'profile_settings.dart';

/// Deletes the signed-in account and clears everything of it on the phone.
///
/// It is owned by the app, not by the sheet that asked: a sheet closed in the middle of the call does
/// not stop it, and the phone is cleared whether or not anything is still on screen to see it.
class AccountDeletion {
  AccountDeletion(this._ref);

  final Ref _ref;
  var _running = false;

  /// Whether a deletion is under way (a second call while it is, does nothing).
  bool get running => _running;

  /// `DELETE /v1/me` and then the phone. A failure that is the server's refusal or no answer is
  /// thrown as a [HomeFailure] and changes nothing, here or there. A 401 is the server saying it no
  /// longer knows the session: the account is gone already (an earlier answer was lost) or the
  /// session is, and either way there is nothing left on the server for this phone to delete, so it
  /// is cleared as after a delete.
  Future<void> delete() async {
    if (_running) return;
    _running = true;
    try {
      // Before the account is gone: who it is, for what is kept under its id.
      final id = await _accountId();
      try {
        await _ref.read(accountRepositoryProvider).deleteAccount();
      } on HomeFailure catch (failure) {
        if (!failure.unauthorized) rethrow;
      }
      await _clearPhone(id);
    } finally {
      _running = false;
    }
  }

  Future<String?> _accountId() async {
    try {
      final profile = _ref.read(settingsProfileProvider).value;
      if (profile != null) return profile.id;
      final token = _ref.read(sessionProvider).stored?.token;
      if (token != null) return await _ref.read(authApiProvider).accountId(token);
    } on Object {
      // Offline and never read: what is kept under the id stays, and is of no use to anyone else.
    }
    return _ref.read(homeProvider).data?.userId;
  }

  /// One step at a time, each on its own: a step that cannot be done (a store that will not answer)
  /// never stops the ones after it, nor the end of the session, which is last.
  Future<void> _clearPhone(String? id) async {
    final platform = _ref.read(noticePlatformProvider);
    await _step(platform.cancelDue);
    await _step(platform.cancelGuest);
    if (id != null) {
      await _step(() => _ref.read(passkeyOfferProvider).forget(id));
      await _step(() => _ref.read(onboardingDraftStoreProvider).clear(id));
      for (final nudge in Nudge.values) {
        await _step(() => _ref.read(flagStoreProvider('home.dismissed.$id.${nudge.id}')).clear());
      }
    }
    await _step(_ref.read(modelStoreProvider).deleteModels);
    // The home cache, the widget and the token.
    await _ref.read(sessionProvider.notifier).accountDeleted();
  }

  Future<void> _step(Future<void> Function() clear) async {
    try {
      await clear();
    } on Object {
      // See [_clearPhone].
    }
  }
}

final accountDeletionProvider = Provider<AccountDeletion>(AccountDeletion.new);
