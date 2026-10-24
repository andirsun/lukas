import 'dart:async';

import 'package:lukitas/add/add_repository.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_repository.dart';

import '../home/fakes.dart';

/// The server's create/update/suggestions in memory, on top of the same movements the fake home
/// repository serves. Like the real API, a create with a key it has already seen answers with the
/// first movement instead of making a second one.
class FakeAddRepository implements AddRepository {
  FakeAddRepository(this.server);

  final FakeHomeRepository server;

  /// Every call, in order: `create <key> <name> <amount>`, `update <id> <json>`, `suggestions <q>`.
  final calls = <String>[];

  /// The Idempotency-Key of every create.
  final keys = <String>[];

  final _byKey = <String, Transaction>{};
  var _next = 0;

  /// What the next call of that name throws (then cleared), before anything is saved.
  final failures = <String, Object>{};

  /// The next create reaches the server and is saved, but its answer never comes back: a timeout.
  var loseNextAnswer = false;

  /// While set, a create waits for it before answering.
  Completer<void>? hold;

  /// What `suggestions` answers when set; otherwise it is computed from the movements.
  List<TransactionSuggestion>? suggestionList;

  @override
  Future<Transaction> create(CreateTransaction input, {required String idempotencyKey}) async {
    calls.add('create $idempotencyKey ${input.name} ${input.amount}');
    keys.add(idempotencyKey);
    final failure = failures.remove('create');
    if (failure != null) throw failure;
    final known = _byKey[idempotencyKey];
    final Transaction saved;
    if (known != null) {
      saved = known;
    } else {
      saved = Transaction(
        (b) => b
          ..id = 'new-${++_next}'
          ..name = input.name
          ..amount = input.amount
          ..currency = server.currency
          ..date = input.date
          ..status = input.status == CreateTransactionStatusEnum.pending
              ? TransactionStatusEnum.pending
              : TransactionStatusEnum.paid
          ..note = input.note
          ..categoryId = input.categoryId
          ..source_ = TransactionSource_Enum.app
          ..createdAt = '2026-10-22T10:00:00.000Z'
          ..updatedAt = '2026-10-22T10:00:00.000Z',
      );
      _byKey[idempotencyKey] = saved;
      server.items
        ..add(saved)
        ..sort((a, b) {
          final byDate = b.date.compareTo(a.date);
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        });
    }
    await hold?.future;
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw const HomeFailure(0);
    }
    return saved;
  }

  @override
  Future<Transaction> update(String id, TransactionPatch patch) async {
    calls.add('update $id ${patch.toJson()}');
    final failure = failures.remove('update');
    if (failure != null) throw failure;
    final index = server.items.indexWhere((t) => t.id == id);
    if (index < 0) throw const HomeFailure(404, code: 'not_found');
    final old = server.items[index];
    final updated = old.rebuild((b) {
      if (patch.name != null) b.name = patch.name;
      if (patch.amount != null) b.amount = patch.amount;
      if (patch.categoryId != null) b.categoryId = patch.categoryId;
      if (patch.date != null) b.date = patch.date;
      if (patch.pending != null) {
        b.status = patch.pending! ? TransactionStatusEnum.pending : TransactionStatusEnum.paid;
      }
      if (patch.setNote) b.note = patch.note;
    });
    server.items[index] = updated;
    await hold?.future;
    return updated;
  }

  @override
  Future<List<TransactionSuggestion>> suggestions(String query) async {
    calls.add('suggestions $query');
    final failure = failures.remove('suggestions');
    if (failure != null) throw failure;
    final fixed = suggestionList;
    if (fixed != null) return fixed;
    // Names used, most used first (ties: most recent), but not a category's own name.
    final names = {for (final c in server.categoryList) c.name.toLowerCase()};
    final uses = <String, List<Transaction>>{};
    for (final t in server.items) {
      if (names.contains(t.name.toLowerCase())) continue;
      uses.putIfAbsent(t.name.toLowerCase(), () => []).add(t);
    }
    final needle = query.toLowerCase();
    final found = uses.values.where((l) => l.first.name.toLowerCase().contains(needle)).toList()
      ..sort((a, b) => b.length - a.length);
    return [
      for (final list in found)
        TransactionSuggestion(
          (b) => b
            ..name = list.first.name
            ..categoryId = list.first.categoryId,
        ),
    ].take(suggestionsAsked).toList();
  }
}
