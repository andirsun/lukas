import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../add/add_repository.dart';
import '../add/save_outcome.dart' show canRetrySave;
import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../capture/capture_repository.dart';
import '../home/home_cache.dart' show sessionOwnerOf;
import '../home/home_controller.dart';
import '../home/home_repository.dart';

/// Where the queue is kept: one string. The app uses `flutter_secure_storage`, like the home
/// cache; tests use memory.
abstract interface class PendingSavesStore {
  Future<String?> read();
  Future<void> write(String json);
  Future<void> clear();
}

/// [PendingSavesStore] over `flutter_secure_storage`.
class SecurePendingSavesStore implements PendingSavesStore {
  const SecurePendingSavesStore([this._storage = const FlutterSecureStorage()]);

  static const key = 'saves.pending';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: key);

  @override
  Future<void> write(String json) => _storage.write(key: key, value: json);

  @override
  Future<void> clear() => _storage.delete(key: key);
}

final pendingSavesStoreProvider = Provider<PendingSavesStore>(
  (ref) => const SecurePendingSavesStore(),
);

/// Forgets the queue when the session ends: what it holds is the person's, and the next person on
/// this phone must never send it. Ignored when it cannot happen.
Future<void> clearPendingSaves(PendingSavesStore store) async {
  try {
    await store.clear();
  } catch (_) {
    // Nothing more to do.
  }
}

/// One save waiting for the network: the movement of the add sheet, or a quick capture's batch.
class PendingSave {
  const PendingSave({required this.key, required this.items, required this.batch});

  /// The Idempotency-Key of the first try: every retry sends it again.
  final String key;

  /// What the save makes, in order.
  final List<CreateTransaction> items;

  /// A quick capture's batch (`POST /v1/transactions/batch`), or one movement.
  final bool batch;

  /// The id of the row that stands for item [index] on home until the server has it.
  String rowId(int index) => '$unsentPrefix$key-$index';

  /// The rows home shows for this save: what was typed, with no id from the server yet.
  List<Transaction> rows(String currency) => [
    for (final (i, item) in items.indexed)
      Transaction(
        (b) => b
          ..id = rowId(i)
          ..name = item.name
          ..amount = item.amount
          ..currency = currency
          ..date = item.date
          ..status = item.status == CreateTransactionStatusEnum.pending
              ? TransactionStatusEnum.pending
              : TransactionStatusEnum.paid
          ..note = item.note
          ..categoryId = item.categoryId
          ..source_ = TransactionSource_Enum.app
          ..createdAt = ''
          ..updatedAt = '',
      ),
  ];

  Map<String, Object?> toJson() => {
    'key': key,
    'batch': batch,
    'items': [
      for (final item in items)
        standardSerializers.serializeWith(CreateTransaction.serializer, item),
    ],
  };

  static PendingSave fromJson(Map<String, Object?> json) => PendingSave(
    key: json['key']! as String,
    batch: json['batch']! as bool,
    items: [
      for (final item in json['items']! as List<Object?>)
        standardSerializers.deserializeWith(CreateTransaction.serializer, item)!,
    ],
  );
}

/// What starts the id of a row that is not on the server yet.
const unsentPrefix = 'unsent-';

/// Whether [tx] is a row of a save still waiting for the network.
bool isUnsent(Transaction tx) => tx.id.startsWith(unsentPrefix);

/// What home tells the person about the queue: saves that got through, or one the server refused.
class PendingNotice {
  const PendingNotice(this.id, {this.sent = 0, this.refused});

  /// Grows with each notice, so the same notice twice still counts as new.
  final int id;

  /// How many movements the server has now.
  final int sent;

  /// The name (or, unnamed, nothing) of the movement the server refused and that was dropped.
  final CreateTransaction? refused;
}

class PendingSavesState {
  const PendingSavesState({this.saves = const [], this.notice});

  /// The saves waiting, oldest first.
  final List<PendingSave> saves;
  final PendingNotice? notice;

  PendingSavesState copyWith({List<PendingSave>? saves, PendingNotice? notice}) =>
      PendingSavesState(saves: saves ?? this.saves, notice: notice ?? this.notice);
}

/// The token of the signed-in session, which the queue is bound to; null when signed out (nothing
/// is read or written then). Replaced in tests.
final pendingSavesTokenProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider.select((s) => s.stored?.token)),
);

/// How long the queue waits before trying again after the [attempt]th failure in a row (1 is the
/// first): soon at first, then once a minute.
Duration pendingRetryDelay(int attempt) => switch (attempt) {
  <= 1 => const Duration(seconds: 5),
  2 => const Duration(seconds: 15),
  3 => const Duration(seconds: 30),
  _ => const Duration(minutes: 1),
};

/// The wait before each retry (replaced in tests).
final pendingRetryDelayProvider = Provider<Duration Function(int attempt)>(
  (ref) => pendingRetryDelay,
);

/// New movements saved with no network, kept on the phone until the server has them.
///
/// A save that gets no answer at all (offline, a timeout, a lost connection) is not lost: the add
/// sheet and quick capture hand it here ([PendingSaves.add]) and close, and home shows its rows
/// marked as not uploaded yet. The queue sends them in order, each with the Idempotency-Key of its
/// first try, so a save that did reach the server the first time gets that answer back instead of
/// a second row. It tries again when the app starts, whenever home loads, and on a timer while
/// anything is waiting. A save the server refuses (an archived category, say) is dropped, and home
/// says which one. Only new movements wait here: an edit, a delete or a payment still needs the
/// network.
///
/// The queue of the signed-in session. The document kept on the phone is version 1:
///
/// ```json
/// {"v": 1, "owner": "<sha-256 of the session token>", "saves": [{"key": "...", "batch": false, "items": [...]}]}
/// ```
///
/// with the API's own JSON for each movement. Like the home cache it is bound to the session that
/// wrote it, and signing out deletes it.
class PendingSaves extends Notifier<PendingSavesState> {
  static const version = 1;

  var _alive = true;
  Future<void>? _loaded;
  Future<void>? _sending;
  Timer? _retry;
  var _failures = 0;
  var _noticeId = 0;

  /// Changes whenever the queue on screen changes, so a write that lands late never overwrites a
  /// newer one.
  var _writeSeq = 0;

  String? get _token => ref.read(pendingSavesTokenProvider);

  @override
  PendingSavesState build() {
    // Another session starts from its own queue (none, for another person).
    ref.watch(pendingSavesTokenProvider);
    _alive = true;
    _sending = null;
    _failures = 0;
    _retry?.cancel();
    ref.onDispose(() {
      _alive = false;
      _retry?.cancel();
    });
    _loaded = _load();
    return const PendingSavesState();
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null) return;
    final saves = <PendingSave>[];
    try {
      final raw = await ref.read(pendingSavesStoreProvider).read();
      if (raw != null) {
        final doc = jsonDecode(raw) as Map<String, Object?>;
        if (doc['v'] == version && doc['owner'] == sessionOwnerOf(token)) {
          for (final save in doc['saves']! as List<Object?>) {
            saves.add(PendingSave.fromJson(save! as Map<String, Object?>));
          }
        }
      }
    } catch (_) {
      // Unreadable: nothing to send.
    }
    if (!_alive || saves.isEmpty) return;
    state = state.copyWith(saves: [...saves, ...state.saves]);
    unawaited(send());
  }

  Future<void> _persist() async {
    final token = _token;
    if (token == null) return;
    final seq = ++_writeSeq;
    final store = ref.read(pendingSavesStoreProvider);
    try {
      if (state.saves.isEmpty) {
        await store.clear();
      } else {
        final json = jsonEncode({
          'v': version,
          'owner': sessionOwnerOf(token),
          'saves': [for (final save in state.saves) save.toJson()],
        });
        if (seq != _writeSeq) return;
        await store.write(json);
      }
    } catch (_) {
      // The rows still show until the app is closed; nothing better to do.
    }
  }

  /// Keeps [save] for when the network is back, and tries it again soon.
  Future<void> add(PendingSave save) async {
    await _loaded;
    if (!_alive) return;
    state = state.copyWith(saves: [...state.saves, save]);
    await _persist();
    _schedule();
  }

  /// Sends what is waiting, oldest first, until it is all on the server or the network fails
  /// again. One sending at a time: a call while one is under way waits for it.
  Future<void> send() => _sending ??= _send().whenComplete(() => _sending = null);

  Future<void> _send() async {
    await _loaded;
    _retry?.cancel();
    var sent = 0;
    while (_alive && state.saves.isNotEmpty) {
      final save = state.saves.first;
      final List<Transaction> saved;
      try {
        saved = save.batch
            ? await ref
                  .read(captureRepositoryProvider)
                  .createBatch(save.items, idempotencyKey: save.key)
            : [
                await ref
                    .read(addRepositoryProvider)
                    .create(save.items.single, idempotencyKey: save.key),
              ];
      } on HomeFailure catch (failure) {
        if (!_alive) return;
        // A refused session ends it (home signs out); signing out forgets the queue.
        if (failure.unauthorized) return;
        if (canRetrySave(failure)) {
          _failures++;
          _schedule();
          _tell(sent);
          return;
        }
        // Refused for good (the category is gone, say): sending it again says the same.
        _drop(save);
        _tell(sent, refused: save.items.first);
        sent = 0;
        continue;
      } on Object {
        if (!_alive) return;
        _failures++;
        _schedule();
        _tell(sent);
        return;
      }
      if (!_alive) return;
      _failures = 0;
      // Home puts the server's rows in before the ones that stood for them go.
      if (ref.exists(homeProvider)) unawaited(ref.read(homeProvider.notifier).savedBatch(saved));
      _drop(save);
      sent += saved.length;
    }
    _tell(sent);
  }

  void _drop(PendingSave save) {
    state = state.copyWith(
      saves: [
        for (final s in state.saves)
          if (s.key != save.key) s,
      ],
    );
    unawaited(_persist());
  }

  void _tell(int sent, {CreateTransaction? refused}) {
    if (sent == 0 && refused == null) return;
    state = state.copyWith(
      notice: PendingNotice(++_noticeId, sent: sent, refused: refused),
    );
  }

  /// Tries again after a while, while anything is waiting.
  void _schedule() {
    _retry?.cancel();
    if (!_alive || state.saves.isEmpty) return;
    final delay = ref.read(pendingRetryDelayProvider)(_failures);
    _retry = Timer(delay, () => unawaited(send()));
  }
}

final pendingSavesProvider = NotifierProvider<PendingSaves, PendingSavesState>(PendingSaves.new);
