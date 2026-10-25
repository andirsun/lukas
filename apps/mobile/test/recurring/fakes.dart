import 'dart:async';

import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/notices/notice_backend.dart';
import 'package:lukitas/recurring/recurring_model.dart';
import 'package:lukitas/recurring/recurring_repository.dart';

import '../budgets/fakes.dart';
import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../notices/fakes.dart';

/// A recurring payment as the API sends it.
Recurrence rule(
  String id,
  String categoryId, {
  String name = 'Spotify',
  int amount = -3500000,
  int day = 25,
  String start = '2026-01-01',
  String? end,
  RecurrenceFrequencyEnum frequency = RecurrenceFrequencyEnum.monthly,
  int? month,
}) => Recurrence(
  (b) => b
    ..id = id
    ..name = name
    ..amount = amount
    ..categoryId = categoryId
    ..frequency = frequency
    ..dayOfMonth = day
    ..monthOfYear = month
    ..startDate = start
    ..endDate = end,
);

/// The server's side of the recurring payments, in memory, over [home]'s: a payment makes a pending
/// transaction in the month on screen (the API adds them as it reads them), and an edit or a delete
/// drops the unpaid ones from this month on (`dropPendingOccurrences`), as the real server does.
/// Records every call, and fails the next one named when told to.
class FakeRecurringRepository implements RecurringRepository {
  FakeRecurringRepository(this.home, {List<Recurrence> rules = const [], this.budgets}) {
    this.rules.addAll(rules);
    for (final r in rules) {
      _materialize(r);
    }
    budgets?.publish();
  }

  final FakeHomeRepository home;
  final FakeBudgetsRepository? budgets;
  final rules = <Recurrence>[];
  final calls = <String>[];

  /// "Today": 22 October 2026, in Bogota.
  static const today = '2026-10-22';
  static const month = '2026-10';

  /// What the next call of that name throws (then cleared): `list`, `create`, `update`, `delete`.
  final failures = <String, Object>{};

  /// Calls named here are made on the server, and then their answer is lost (offline): the next
  /// call of that name throws after it has done its work.
  final lostAnswers = <String>{};

  /// While set, [create], [update] and [delete] wait for it.
  Completer<void>? hold;

  /// The values of every create and update, as sent.
  final created = <NewRecurrence>[];
  final updated = <(String, NewRecurrence, bool)>[];

  var _next = 1;

  Future<void> _enter(String name, String line) async {
    calls.add(line);
    await hold?.future;
    final failure = failures.remove(name);
    if (failure != null) throw failure;
  }

  void _materialize(Recurrence r) {
    for (final date in occurrences(r, month)) {
      home.items.add(
        tx(
          'pending-${r.id}',
          date,
          r.amount,
          name: r.name,
          status: 'pending',
          categoryId: r.categoryId,
        ).rebuild((b) => b.recurrenceId = r.id),
      );
    }
  }

  void _dropPending(String id) => home.items.removeWhere(
    (t) => t.recurrenceId == id && t.status == TransactionStatusEnum.pending,
  );

  /// What "Hoy vence…" would announce on [day]: the names of the pending rows of a recurring
  /// payment on that day, which is what the Kotlin job reads (`NoticeApi.dueToday`).
  List<String> dueOn(String day) => [
    for (final t in home.items)
      if (t.date == day && t.status == TransactionStatusEnum.pending && t.recurrenceId != null)
        t.name,
  ];

  @override
  Future<List<Recurrence>> list() async {
    await _enter('list', 'list');
    return List.of(rules);
  }

  @override
  Future<Recurrence> create(NewRecurrence values) async {
    await _enter('create', 'create ${values.name}');
    created.add(values);
    final made = Recurrence(
      (b) => b
        ..id = 'rec-new-${_next++}'
        ..name = values.name
        ..amount = values.amount
        ..categoryId = values.categoryId
        ..frequency = values.frequency
        ..dayOfMonth = values.dayOfMonth
        ..monthOfYear = values.monthOfYear
        ..startDate = values.startDate
        ..endDate = values.endDate,
    );
    rules.add(made);
    _materialize(made);
    budgets?.publish();
    if (lostAnswers.remove('create')) throw const HomeFailure(0);
    return made;
  }

  @override
  Future<Recurrence> update(
    String id,
    NewRecurrence values, {
    required bool categoryChanged,
  }) async {
    await _enter('update', 'update $id');
    updated.add((id, values, categoryChanged));
    final index = rules.indexWhere((r) => r.id == id);
    if (index < 0) throw const HomeFailure(404, code: 'not_found');
    final saved = rules[index].rebuild(
      (b) => b
        ..name = values.name
        ..amount = values.amount
        ..frequency = values.frequency
        ..dayOfMonth = values.dayOfMonth
        ..monthOfYear = values.monthOfYear
        ..startDate = values.startDate
        ..endDate = values.endDate,
    );
    final withCategory = categoryChanged
        ? saved.rebuild((b) => b.categoryId = values.categoryId)
        : saved;
    rules[index] = withCategory;
    _dropPending(id);
    _materialize(withCategory);
    budgets?.publish();
    return withCategory;
  }

  @override
  Future<void> delete(String id) async {
    await _enter('delete', 'delete $id');
    if (!rules.any((r) => r.id == id)) throw const HomeFailure(404, code: 'not_found');
    _dropPending(id);
    rules.removeWhere((r) => r.id == id);
    budgets?.publish();
    if (lostAnswers.remove('delete')) throw const HomeFailure(0);
  }
}

/// The notices' view of the same server: a recurring payment still running makes "Hoy vence…" due.
class RulesNoticeBackend extends FakeNoticeBackend {
  RulesNoticeBackend(this.server) : super(hasRecurring: true);

  final FakeRecurringRepository server;

  @override
  Future<NoticeFacts> facts() async {
    final facts = await super.facts();
    return NoticeFacts(
      timezone: facts.timezone,
      hasRecurring: hasActiveRecurrence(server.rules, FakeRecurringRepository.today),
    );
  }
}
