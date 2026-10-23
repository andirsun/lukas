import 'dart:async';

import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/budgets/budgets_repository.dart';
import 'package:lukitas/home/home_repository.dart';

import '../home/fakes.dart';
import '../home/fixtures.dart';

/// The budgets endpoints in memory, over [home]'s server: a category's movements, what came in to an
/// income category, and the budgets. Setting a budget changes what [home] answers next (its summary
/// and its categories), as the real server does. Records every call, and fails the next save when
/// told to.
class FakeBudgetsRepository implements BudgetsRepository {
  FakeBudgetsRepository(this.home, {Map<String, int> budgets = const {}}) {
    this.budgets.addAll(budgets);
    publish();
  }

  final FakeHomeRepository home;

  /// Budget in force now, by category, in cents.
  final budgets = <String, int>{};
  final calls = <String>[];

  /// While set, [setBudget] waits for it.
  Completer<void>? holdSave;

  /// What the next [setBudget] throws (then cleared).
  Object? saveFailure;

  /// What the next [categoryTransactions] throws (then cleared).
  Object? listFailure;

  int _spent(String categoryId) => home.items
      .where(
        (t) =>
            t.categoryId == categoryId &&
            t.date.startsWith('2026-10') &&
            t.amount < 0 &&
            t.status == TransactionStatusEnum.paid,
      )
      .fold<int>(0, (sum, t) => sum - t.amount);

  /// Makes [home]'s summary and categories follow [budgets], as the server computes them.
  void publish() {
    final expense = [
      for (final c in home.categoryList)
        if (c.kind == CategoryKindEnum.expense) c,
    ];
    home.budgetTotal = [for (final c in expense) budgets[c.id] ?? 0].fold(0, (a, b) => a + b);
    home.categoryLines = [
      for (final c in expense)
        () {
          final budget = budgets[c.id];
          final spent = _spent(c.id);
          final ratio = budget == null || budget == 0 ? null : spent / budget;
          final state = budget == null
              ? 'ok'
              : budget == 0
              ? (spent > 0 ? 'over' : 'ok')
              : ratio! > 1
              ? 'over'
              : ratio >= 0.8
              ? 'near'
              : 'ok';
          return categorySummary(c.id, budget: budget, spent: spent, state: state);
        }(),
    ];
    for (var i = 0; i < home.categoryList.length; i++) {
      final c = home.categoryList[i];
      if (c.kind == CategoryKindEnum.expense) {
        home.categoryList[i] = c.rebuild((b) => b.currentBudget = budgets[c.id]);
      }
    }
  }

  @override
  Future<TransactionsPage> categoryTransactions(
    String month,
    String categoryId, {
    String? cursor,
  }) async {
    calls.add('transactions $month $categoryId ${cursor ?? ''}'.trimRight());
    final failure = listFailure;
    if (failure != null) {
      listFailure = null;
      throw failure;
    }
    final live = home.items
        .where((t) => t.date.startsWith(month) && t.categoryId == categoryId)
        .toList();
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + home.pageSize).clamp(0, live.length);
    return TransactionsPage(live.sublist(start, end), end < live.length ? '$end' : null);
  }

  @override
  Future<int> incomeTotal(String month, String categoryId) async {
    calls.add('income $month $categoryId');
    return home.items
        .where((t) => t.date.startsWith(month) && t.categoryId == categoryId && t.amount > 0)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  @override
  Future<void> setBudget(String categoryId, int cents, {required String month}) async {
    calls.add('setBudget $categoryId $cents $month');
    await holdSave?.future;
    final failure = saveFailure;
    if (failure != null) {
      saveFailure = null;
      throw failure;
    }
    budgets[categoryId] = cents;
    publish();
  }
}

/// October 2026 for the budgets tests (the clock is 22 October, in Bogota): two spending categories
/// with budgets, Supermercado nearly out of it, an income category, and an archived one that still
/// has spending. Amounts are cents of COP.
///
/// - Supermercado: 250.000 pesos, 180.000 spent (72 %).
/// - Hogar: 600.000 pesos, nothing spent yet (its rent is pending).
FakeHomeRepository budgetsMonth() {
  final home = FakeHomeRepository(
    categoryList: [
      category('cat-groceries', 'Supermercado', icon: '🛒').rebuild((b) => b.sortOrder = 1),
      category('cat-home', 'Hogar', icon: '🏠', color: '#ff9f1c').rebuild((b) => b.sortOrder = 0),
      category('cat-salary', 'Nómina', kind: 'income', icon: '💰').rebuild((b) => b.sortOrder = 2),
    ],
    items: [
      tx(
        'rent',
        '2026-10-25',
        -50000000,
        name: 'Arriendo',
        status: 'pending',
        categoryId: 'cat-home',
      ),
      tx('market', '2026-10-21', -18000000, name: 'Mercado'),
      tx('fruit', '2026-10-05', -300000, name: 'Frutas'),
      tx('salary', '2026-10-01', 300000000, name: 'Nómina', categoryId: 'cat-salary'),
    ],
  );
  return home;
}

FakeBudgetsRepository budgetsFor(FakeHomeRepository home) =>
    FakeBudgetsRepository(home, budgets: {'cat-groceries': 25000000, 'cat-home': 60000000});
