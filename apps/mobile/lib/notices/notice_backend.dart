import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';

/// What the notices need to know of the account: the zone "today" is read in, and whether there is
/// a recurring payment at all.
class NoticeFacts {
  const NoticeFacts({required this.timezone, required this.hasRecurring});

  /// The profile's IANA time zone, never the phone's.
  final String timezone;
  final bool hasRecurring;
}

/// Asks the server for [NoticeFacts]. Throws when it cannot (offline, a 5xx): the notices then keep
/// what they have.
abstract interface class NoticeBackend {
  Future<NoticeFacts> facts();
}

/// [NoticeBackend] over the generated client: `GET /v1/me` and `GET /v1/recurrences`.
class ApiNoticeBackend implements NoticeBackend {
  ApiNoticeBackend(this._api);

  final DefaultApi _api;

  @override
  Future<NoticeFacts> facts() async {
    final (me, recurrences) = await (_api.getMe(), _api.listRecurrences()).wait;
    return NoticeFacts(
      timezone: me.data!.timezone,
      hasRecurring: recurrences.data?.isNotEmpty ?? false,
    );
  }
}

final noticeBackendProvider = Provider<NoticeBackend>(
  (ref) => ApiNoticeBackend(ref.watch(apiClientProvider).api.getDefaultApi()),
);
