import 'dart:async';

import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/categories/categories_repository.dart';
import 'package:lukitas/categories/category_model.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/notices/notice_backend.dart';

import '../budgets/fakes.dart';
import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../notices/fakes.dart';

/// A recurring payment as the API sends it.
Recurrence recurrence(
  String id,
  String categoryId, {
  String name = 'Spotify',
  int amount = -3500000,
  String? endDate,
}) => Recurrence(
  (b) => b
    ..id = id
    ..name = name
    ..amount = amount
    ..categoryId = categoryId
    ..frequency = RecurrenceFrequencyEnum.monthly
    ..dayOfMonth = 25
    ..startDate = '2026-01-01'
    ..endDate = endDate,
);

/// The server's side of managing categories, in memory, over [home]'s: creating, changing,
/// archiving and restoring change what [home] answers next (its categories, and through [budgets]
/// its summary), as the real server does. Archiving ends the category's active recurring payments
/// today and drops their unpaid rows from today on (`stopCategoryRecurrences`). Records every call,
/// and fails the next one named when told to.
class FakeCategoriesRepository implements CategoriesRepository {
  FakeCategoriesRepository(this.home, this.budgets, {List<Recurrence> rules = const []}) {
    this.rules.addAll(rules);
  }

  final FakeHomeRepository home;
  final FakeBudgetsRepository budgets;
  final rules = <Recurrence>[];
  final calls = <String>[];

  /// "Today" for the recurring payments archiving ends: 22 October 2026, in Bogota.
  static const today = '2026-10-22';

  /// What the next call of that name throws (then cleared): `create`, `update`, `hasTransactions`,
  /// `recurrences`.
  final failures = <String, Object>{};

  /// Calls named here are made on the server, and then their answer is lost (offline): the next
  /// call of that name throws after it has done its work.
  final lostAnswers = <String>{};

  /// While set, [create] and [update] wait for it.
  Completer<void>? hold;

  var _next = 1;

  Future<void> _enter(String name, String line) async {
    calls.add(line);
    await hold?.future;
    final failure = failures.remove(name);
    if (failure != null) throw failure;
  }

  @override
  Future<Category> create(NewCategory values) async {
    await _enter(
      'create',
      'create ${values.name} ${values.kind.name} ${values.glyph} ${values.tint}',
    );
    if (home.categoryList.any((c) => c.name.toLowerCase() == values.name.toLowerCase())) {
      throw const HomeFailure(409, code: 'category_name_taken');
    }
    final made = category(
      'cat-new-${_next++}',
      values.name,
      kind: values.kind.name,
      icon: values.glyph,
      color: values.tint,
    ).rebuild((b) => b.sortOrder = home.categoryList.length);
    home.categoryList.add(made);
    budgets.publish();
    if (lostAnswers.remove('create')) throw const HomeFailure(0);
    return made;
  }

  @override
  Future<Category> update(
    String id, {
    String? name,
    String? icon,
    String? color,
    CategoryKindEnum? kind,
    bool? archived,
  }) async {
    final changes = [
      if (name != null) 'name=$name',
      if (icon != null) 'icon=$icon',
      if (color != null) 'color=$color',
      if (kind != null) 'kind=${kind.name}',
      if (archived != null) 'archived=$archived',
    ];
    await _enter('update', 'update $id ${changes.join(' ')}');
    final index = home.categoryList.indexWhere((c) => c.id == id);
    if (index < 0) throw const HomeFailure(404, code: 'not_found');
    final existing = home.categoryList[index];
    if (name != null &&
        home.categoryList.any((c) => c.id != id && c.name.toLowerCase() == name.toLowerCase())) {
      throw const HomeFailure(409, code: 'category_name_taken');
    }
    if (kind != null && kind != existing.kind && home.items.any((t) => t.categoryId == id)) {
      throw const HomeFailure(409, code: 'category_has_transactions');
    }
    final updated = existing.rebuild((b) {
      if (name != null) b.name = name;
      if (icon != null) b.icon = icon;
      if (color != null) b.color = color;
      if (kind != null) b.kind = kind;
      if (archived != null) b.archived = archived;
    });
    home.categoryList[index] = updated;
    if (archived == true && !existing.archived) {
      final stopped = <String>{};
      for (var i = 0; i < rules.length; i++) {
        final rule = rules[i];
        if (rule.categoryId == id &&
            (rule.endDate == null || rule.endDate!.compareTo(today) >= 0)) {
          rules[i] = rule.rebuild((b) => b.endDate = today);
          stopped.add(rule.name);
        }
      }
      // Their unpaid rows from today on go; paid ones stay.
      home.items.removeWhere(
        (t) =>
            t.categoryId == id &&
            t.status == TransactionStatusEnum.pending &&
            t.date.compareTo(today) >= 0 &&
            stopped.contains(t.name),
      );
    }
    budgets.publish();
    return updated;
  }

  @override
  Future<bool> hasTransactions(String categoryId) async {
    await _enter('hasTransactions', 'hasTransactions $categoryId');
    return home.items.any((t) => t.categoryId == categoryId);
  }

  @override
  Future<List<Recurrence>> recurrences() async {
    await _enter('recurrences', 'recurrences');
    return List.of(rules);
  }
}

/// The notices' view of the same server: a recurring payment still running makes "Hoy vence…" due.
class RecurringNoticeBackend extends FakeNoticeBackend {
  RecurringNoticeBackend(this.categories) : super(hasRecurring: true);

  final FakeCategoriesRepository categories;

  @override
  Future<NoticeFacts> facts() async {
    final facts = await super.facts();
    return NoticeFacts(
      timezone: facts.timezone,
      hasRecurring: hasActiveRecurrence(categories.rules, FakeCategoriesRepository.today),
    );
  }
}
