import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/welcome/onboarding_repository.dart';
import 'package:lukitas/settings/settings_store.dart';

import '../home/fakes.dart';
import '../notices/fakes.dart';

/// Keyed settings in memory.
class FakeSettingsStore implements SettingsStore {
  FakeSettingsStore([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

/// One on/off setting in memory.
class FakeFlagStore implements FlagStore {
  FakeFlagStore([this.value]);

  bool? value;

  @override
  Future<bool?> read() async => value;

  @override
  Future<void> write(bool on) async => value = on;

  @override
  Future<void> clear() async => value = null;
}

/// `PATCH /v1/me` on the server in memory: it changes the profile [home] answers with (and the zone
/// the notices read), refuses a new currency once there is a movement (409 `currency_locked`) and
/// fails when told to. Everything but the patch is the welcome's, which Settings never calls.
class FakeProfileServer implements OnboardingRepository {
  FakeProfileServer(this.home, {this.notices});

  final FakeHomeRepository home;
  final FakeNoticeBackend? notices;

  /// Every patch, as sent: `{timezone: Europe/Madrid}`, `{currency: USD}`.
  final patches = <Map<String, String>>[];

  /// The next patch throws this (then cleared).
  Object? failure;

  /// The patch is made on the server, and then its answer is lost (offline): the next one throws
  /// this after it did its work.
  Object? lostAnswer;

  /// The server counts a movement the list does not show (a deleted one): 409 whatever the list says.
  bool lockedByServer = false;

  /// Runs as a patch arrives, before it is answered (holds it up).
  Future<void> Function()? onPatch;

  @override
  Future<void> patchMe({String? currency, String? timezone, bool? onboardingCompleted}) async {
    patches.add({'currency': ?currency, 'timezone': ?timezone});
    await onPatch?.call();
    final failing = failure;
    if (failing != null) {
      failure = null;
      throw failing;
    }
    if (currency != null && currency != home.currency) {
      if (lockedByServer || home.items.isNotEmpty) {
        throw const HomeFailure(409, code: 'currency_locked');
      }
      home.currency = currency;
    }
    if (timezone != null) {
      home.timezone = timezone;
      notices?.timezone = timezone;
    }
    final lost = lostAnswer;
    if (lost != null) {
      lostAnswer = null;
      throw lost;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Settings never calls ${invocation.memberName}');
}
