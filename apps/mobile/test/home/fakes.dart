import 'dart:async';

import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/widget_snapshot.dart';

import 'fixtures.dart';

int _newestFirst(Transaction a, Transaction b) {
  final byDate = b.date.compareTo(a.date);
  return byDate != 0 ? byDate : b.id.compareTo(a.id);
}

/// The server in memory: a month's transactions and categories, paged like the API, and a summary
/// computed from them (a budget total and spending per category). Records every call, and fails a
/// call when told to.
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({
    this.currency = 'COP',
    this.timezone = 'America/Bogota',
    this.userId = 'user-1',
    this.budgetTotal = 0,
    List<Category>? categoryList,
    List<Transaction>? items,
    this.pageSize = 50,
  }) : categoryList = categoryList ?? [category('cat-groceries', 'Supermercado')],
       items = items ?? [] {
    // The API's order: date, then id, newest first.
    this.items.sort(_newestFirst);
  }

  final String currency;
  final String timezone;
  final String userId;

  /// Cents. Zero: no budgets.
  int budgetTotal;
  final List<Category> categoryList;

  /// Live transactions, newest first. Deleted ones move to [deleted].
  final List<Transaction> items;
  final deleted = <Transaction>[];
  int pageSize;

  final calls = <String>[];

  /// While set, [summary] waits for it (a slow connection).
  Completer<void>? holdSummary;

  /// What the next call of that name throws (then cleared).
  final failures = <String, Object>{};

  void _call(String name) {
    calls.add(name);
    final failure = failures.remove(name.split(' ').first);
    if (failure != null) throw failure;
  }

  @override
  Future<HomeProfile> profile() async {
    _call('profile');
    return HomeProfile(id: userId, currency: currency, timezone: timezone);
  }

  @override
  Future<Summary> summary(String month) async {
    _call('summary $month');
    await holdSummary?.future;
    final spent = items
        .where(
          (t) => t.date.startsWith(month) && t.amount < 0 && t.status == TransactionStatusEnum.paid,
        )
        .fold<int>(0, (sum, t) => sum - t.amount);
    return Summary(
      (b) => b
        ..month = month
        ..budgetTotal = budgetTotal
        ..spent = spent
        ..remaining = budgetTotal - spent
        ..income = 0
        ..balance = -spent
        ..categories.replace(categoryLines),
    );
  }

  /// The summary's per-category lines (budgets and states), as the test needs them.
  List<SummaryCategoriesInner> categoryLines = const [];

  @override
  Future<List<Category>> categories() async {
    _call('categories');
    return categoryList;
  }

  @override
  Future<TransactionsPage> transactions(String month, {String? cursor}) async {
    _call('transactions $month ${cursor ?? ''}'.trimRight());
    final live = items.where((t) => t.date.startsWith(month)).toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + pageSize).clamp(0, live.length);
    return TransactionsPage(live.sublist(start, end), end < live.length ? '$end' : null);
  }

  @override
  Future<void> delete(String id) async {
    _call('delete $id');
    final tx = items.firstWhere((t) => t.id == id);
    items.remove(tx);
    deleted.add(tx);
  }

  @override
  Future<Transaction> restore(String id) async {
    _call('restore $id');
    final tx = deleted.firstWhere((t) => t.id == id);
    deleted.remove(tx);
    items
      ..add(tx)
      ..sort(_newestFirst);
    return tx;
  }

  @override
  Future<Transaction> markPaid(String id) async {
    _call('markPaid $id');
    final index = items.indexWhere((t) => t.id == id);
    final paid = items[index].rebuild((b) => b.status = TransactionStatusEnum.paid);
    items[index] = paid;
    return paid;
  }
}

/// The widget's storage in memory.
class FakeWidgetStore implements WidgetStore {
  final saved = <String, String>{};
  Object? failure;

  @override
  Future<void> save(String key, String value) async {
    if (failure != null) throw failure!;
    saved[key] = value;
  }

  @override
  Future<void> clear(String key) async {
    if (failure != null) throw failure!;
    saved.remove(key);
  }
}

/// The home cache's storage in memory: one JSON string.
class FakeCacheStore implements HomeCacheStore {
  String? value;
  Object? failure;

  @override
  Future<String?> read() async {
    if (failure != null) throw failure!;
    return value;
  }

  @override
  Future<void> write(String json) async {
    if (failure != null) throw failure!;
    value = json;
  }

  @override
  Future<void> clear() async {
    if (failure != null) throw failure!;
    value = null;
  }
}
