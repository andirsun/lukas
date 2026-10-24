// What Settings reads of the profile and changes in it: the web's apps/web/app/features/settings/
// use-profile.ts (`useSaveProfile`, `refreshAllButProfile`, `failureMessage`) on the phone.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/session.dart';
import '../home/home_controller.dart';
import '../home/home_repository.dart';
import '../l10n/app_localizations.dart';
import '../notices/notice_sync.dart';
import '../welcome/onboarding_repository.dart';

/// The profile as Settings shows it (time zone, currency, email): read from the server each time
/// Settings opens. Offline it is what home last loaded, if anything; null when nothing is known.
final settingsProfileProvider = FutureProvider.autoDispose<HomeProfile?>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  try {
    return await repo.profile();
  } on Object {
    final data = ref.read(homeProvider).data;
    if (data == null) return null;
    return HomeProfile(id: data.userId, currency: data.currency, timezone: data.timezone);
  }
});

/// The words for a failed save: the API's code in the catalogue's words, or the generic line (the
/// web's `failureMessage` over `problemMessage`).
String profileFailureMessage(AppLocalizations l10n, HomeFailure failure) {
  if (failure.offline) return l10n.errorNetwork;
  return switch (failure.code) {
    'validation_failed' => l10n.addErrorInvalid,
    'currency_locked' => l10n.errorCurrencyLocked,
    _ => failure.status >= 500 ? l10n.errorInternal : l10n.errorGeneric,
  };
}

/// Saving the time zone and the currency, and telling everything that reads them (the web's
/// `useSaveProfile` and `refreshAllButProfile`).
///
/// A new time zone moves "today" and the edges of every month, and a new currency is what every
/// amount is written in, so a save reaches home before it returns: the profile is read again, the
/// month is loaded again (its figures, the saved month and the widget's snapshot, which carries the
/// zone) and the notices look again (the 9:00 "Hoy vence…" is scheduled in the profile's zone). A
/// failure is thrown as a [HomeFailure] and changes nothing, unless the request may have reached
/// the server (no answer at all, or a 5xx): then everything is read again all the same, so what the
/// server did shows.
class ProfileActions {
  ProfileActions(this._ref);

  final Ref _ref;

  OnboardingRepository get _repo => _ref.read(onboardingRepositoryProvider);

  /// `PATCH /v1/me` with a new time zone.
  Future<void> setTimezone(String zone) => _patch(timezone: zone);

  /// `PATCH /v1/me` with a new currency. The API refuses it with 409 `currency_locked` once the
  /// account has a movement or a recurring payment.
  Future<void> setCurrency(String code) => _patch(currency: code);

  Future<void> _patch({String? timezone, String? currency}) async {
    try {
      await _repo.patchMe(timezone: timezone, currency: currency);
    } on Object catch (error) {
      final failure = error is HomeFailure ? error : const HomeFailure(0);
      if (failure.unauthorized) {
        unawaited(_ref.read(sessionProvider.notifier).signOut(discardGuest: true));
      } else if (failure.offline || failure.status >= 500) {
        unawaited(_settleAfterFailure());
      }
      throw failure;
    }
    await _settle();
  }

  Future<void> _settleAfterFailure() async {
    try {
      await _settle();
    } on Object {
      // Still offline: what is on screen stays, and nothing breaks.
    }
  }

  Future<void> _settle() async {
    _ref.invalidate(settingsProfileProvider);
    await _ref.read(homeProvider.notifier).profileChanged();
    _ref.read(noticeSyncProvider).request();
  }
}

final profileActionsProvider = Provider<ProfileActions>(ProfileActions.new);
