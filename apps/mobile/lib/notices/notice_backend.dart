import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../capture/parser/dates.dart';
import '../home/home_controller.dart';

/// What the notices need to know of the account: the zone "today" is read in, and whether there is
/// a recurring payment still running.
class NoticeFacts {
  const NoticeFacts({required this.timezone, required this.hasRecurring});

  /// The profile's IANA time zone, never the phone's.
  final String timezone;

  /// At least one recurring rule that has not ended (see [hasActiveRecurrence]).
  final bool hasRecurring;
}

/// Whether any of [rules] is still running on [today] (`YYYY-MM-DD`, in the profile's zone): not
/// ended. One that has not started yet counts: it will fall due. A recurrence has no "paused"
/// state, only an `endDate`.
bool hasActiveRecurrence(Iterable<Recurrence> rules, String today) =>
    rules.any((rule) => rule.endDate == null || rule.endDate!.compareTo(today) >= 0);

/// Asks the server for [NoticeFacts]. Throws when it cannot (offline, a 5xx): the notices then keep
/// what they have.
abstract interface class NoticeBackend {
  Future<NoticeFacts> facts();
}

/// [NoticeBackend] over the generated client: `GET /v1/me` and `GET /v1/recurrences`.
class ApiNoticeBackend implements NoticeBackend {
  ApiNoticeBackend(this._api, this._clock);

  final DefaultApi _api;
  final DateTime Function() _clock;

  @override
  Future<NoticeFacts> facts() async {
    final (me, recurrences) = await (_api.getMe(), _api.listRecurrences()).wait;
    final timezone = me.data!.timezone;
    return NoticeFacts(
      timezone: timezone,
      hasRecurring: hasActiveRecurrence(
        recurrences.data ?? const [],
        todayIn(timezone, _clock().toUtc()),
      ),
    );
  }
}

final noticeBackendProvider = Provider<NoticeBackend>(
  (ref) => ApiNoticeBackend(
    ref.watch(apiClientProvider).api.getDefaultApi(),
    ref.read(clockProvider),
  ),
);
