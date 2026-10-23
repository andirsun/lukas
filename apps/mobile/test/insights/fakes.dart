import 'dart:async';

import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/insights/insights_repository.dart';
import 'package:lukitas/ui/month_picker.dart' show addMonths;

import '../home/fakes.dart';
import '../home/fixtures.dart';

/// The reports in memory, computed from [home]'s movements as the server does (apps/api/src/routes/
/// reports.ts): totals per category with their shares, income, expenses and budget per month, and
/// what a normal month costs. Records every call as a line (`byCategory 2026-10 2026-10 expense -`,
/// `trend 2026-10 2026-10`, `costOfLiving 6`), and fails or holds a call when told to.
class FakeInsightsRepository implements InsightsRepository {
  FakeInsightsRepository(
    this.home, {
    this.budgets = const {},
    this.fixed = const {},
    this.current = '2026-10',
  });

  final FakeHomeRepository home;

  /// The budget total of a month (`YYYY-MM`), in cents; absent: none.
  final Map<String, int> budgets;

  /// The categories with a recurrence, which count as fixed.
  final Set<String> fixed;

  /// The month "now" is in: the cost of living averages the complete months before it.
  final String current;

  final calls = <String>[];

  /// What the next call that starts with that name throws (then cleared).
  final failures = <String, Object>{};

  /// The next calls that start with that name each take (and wait for) one of these, in order.
  final gates = <String, List<Completer<void>>>{};

  Future<void> _call(String line) async {
    calls.add(line);
    final name = line.split(' ').first;
    final failure = failures.remove(name);
    if (failure != null) throw failure;
    final gate = gates[name]?.isNotEmpty ?? false ? gates[name]!.removeAt(0) : null;
    await gate?.future;
  }

  Iterable<String> _months(String from, String to) sync* {
    for (var m = from; m.compareTo(to) <= 0; m = addMonths(m, 1)) {
      yield m;
    }
  }

  Category? _category(String id) => home.categoryList.where((c) => c.id == id).firstOrNull;

  @override
  Future<CategoryReport> byCategory({
    required String from,
    required String to,
    required String kind,
    String? status,
  }) async {
    final line = 'byCategory $from $to $kind ${status ?? '-'}';
    final answer = _byCategory(from, to, kind, status);
    await _call(line);
    return answer;
  }

  CategoryReport _byCategory(String from, String to, String kind, String? status) {
    final months = _months(from, to).toSet();
    final sign = kind == 'expense' ? -1 : 1;
    final rows = <(Category, int)>[];
    for (final c in home.categoryList.where((c) => c.kind.name == kind)) {
      final total =
          sign *
          home.items
              .where(
                (t) =>
                    t.categoryId == c.id &&
                    months.contains(t.date.substring(0, 7)) &&
                    (status == null || t.status.name == status),
              )
              .fold<int>(0, (sum, t) => sum + t.amount);
      if (total != 0) rows.add((c, total));
    }
    rows.sort((a, b) => b.$2.compareTo(a.$2));
    final total = rows.fold<int>(0, (sum, r) => sum + r.$2);
    return CategoryReport(
      (b) => b
        ..total = total
        ..items.replace([
          for (final (c, t) in rows)
            CategoryReportItemsInner(
              (i) => i
                ..categoryId = c.id
                ..name = c.name
                ..icon = c.icon
                ..color = c.color
                ..total = t
                ..share = total == 0 ? 0 : (t / total * 10000).round() / 10000,
            ),
        ]),
    );
  }

  @override
  Future<TrendReport> trend({required String from, required String to}) async {
    final answer = TrendReport(
      (b) => b
        ..months.replace([
          for (final month in _months(from, to))
            () {
              var income = 0;
              var expenses = 0;
              for (final t in home.items.where((t) => t.date.startsWith(month))) {
                final kind = _category(t.categoryId)?.kind;
                if (kind == CategoryKindEnum.income) {
                  income += t.amount;
                } else {
                  expenses -= t.amount;
                }
              }
              return TrendReportMonthsInner(
                (m) => m
                  ..month = month
                  ..income = income
                  ..expenses = expenses
                  ..budget = budgets[month] ?? 0,
              );
            }(),
        ]),
    );
    await _call('trend $from $to');
    return answer;
  }

  @override
  Future<CostOfLivingReport> costOfLiving(int months) async {
    final to = addMonths(current, -1);
    final window = _months(addMonths(to, 1 - months), to).toSet();
    final rows = <(String, int, bool)>[];
    var fixedTotal = 0;
    var variableTotal = 0;
    for (final c in home.categoryList.where((c) => c.kind == CategoryKindEnum.expense)) {
      final spent = -home.items
          .where((t) => t.categoryId == c.id && window.contains(t.date.substring(0, 7)))
          .fold<int>(0, (sum, t) => sum + t.amount);
      final average = (spent / months).round();
      if (average == 0) continue;
      final isFixed = fixed.contains(c.id);
      isFixed ? fixedTotal += average : variableTotal += average;
      rows.add((c.id, average, isFixed));
    }
    rows.sort((a, b) => b.$2.compareTo(a.$2));
    final answer = CostOfLivingReport(
      (b) => b
        ..months = months
        ..total = fixedTotal + variableTotal
        ..fixed = fixedTotal
        ..variable = variableTotal
        ..categories.replace([
          for (final (id, average, isFixed) in rows)
            CostOfLivingReportCategoriesInner(
              (r) => r
                ..categoryId = id
                ..average = average
                ..type = isFixed
                    ? CostOfLivingReportCategoriesInnerTypeEnum.fixed
                    : CostOfLivingReportCategoriesInnerTypeEnum.variable,
            ),
        ]),
    );
    await _call('costOfLiving $months');
    return answer;
  }
}

/// October 2026 for the insights tests (the clock is 22 October, in Bogota), over three months:
/// rent in Hogar, Mercado in Supermercado, the salary in Nómina, and this month's Spotify still
/// pending. An archived category (Antiguo) has spending in August only. Amounts are cents of COP.
FakeHomeRepository insightsHome() {
  final items = [
    for (final (month, market) in [
      ('2026-08', 15000000),
      ('2026-09', 12000000),
      ('2026-10', 18000000),
    ]) ...[
      tx('rent-$month', '$month-01', -60000000, name: 'Arriendo', categoryId: 'cat-home'),
      tx('market-$month', '$month-05', -market, name: 'Mercado'),
      tx('salary-$month', '$month-01', 300000000, name: 'Nómina', categoryId: 'cat-salary'),
    ],
    tx('old-2026-08', '2026-08-10', -9000000, name: 'Lavadora', categoryId: 'cat-old'),
    tx(
      'spotify',
      '2026-10-25',
      -3000000,
      name: 'Spotify',
      status: 'pending',
      categoryId: 'cat-fun',
    ),
  ];
  return FakeHomeRepository(
    categoryList: [
      category('cat-home', 'Hogar', icon: '🏠', color: '#3fa7ff'),
      category('cat-groceries', 'Supermercado'),
      category('cat-fun', 'Ocio', icon: '⭐', color: '#a66bff'),
      category('cat-old', 'Antiguo', icon: '📦', color: 'gray', archived: true),
      category('cat-salary', 'Nómina', kind: 'income', icon: '💰'),
    ],
    items: items,
  );
}

FakeInsightsRepository insightsFor(FakeHomeRepository home) => FakeInsightsRepository(
  home,
  budgets: {'2026-09': 90000000, '2026-10': 90000000},
  fixed: {'cat-home'},
);
