import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/budgets/budgets_repository.dart';
import 'package:lukitas/budgets/category_detail_controller.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';

import '../home/fakes.dart';
import 'fakes.dart';

/// 2026-10-22 10:00 in Bogota (UTC-5).
final _now = DateTime.utc(2026, 10, 22, 15);

class Snapshot {
  Snapshot(this.summary);
  final Summary summary;
}

typedef World = (
  ProviderContainer container,
  FakeHomeRepository home,
  FakeBudgetsRepository budgets,
  List<Snapshot> snapshots,
  FakeCacheStore store,
);

Future<void> settle() => Future<void>.delayed(Duration.zero);

Future<void> settleAll() async {
  for (var i = 0; i < 6; i++) {
    await settle();
  }
}

Future<World> loaded() async {
  final home = budgetsMonth();
  final budgets = budgetsFor(home);
  final snapshots = <Snapshot>[];
  final store = FakeCacheStore();
  final container = ProviderContainer(
    overrides: [
      homeRepositoryProvider.overrideWithValue(home),
      budgetsRepositoryProvider.overrideWithValue(budgets),
      homeCacheProvider.overrideWithValue(HomeCache(store, token: 't1')),
      clockProvider.overrideWithValue(() => _now),
      widgetSnapshotWriterProvider.overrideWithValue(
        (summary, {required currency, required locale, required timezone}) async =>
            snapshots.add(Snapshot(summary)),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(homeProvider, (_, _) {});
  await settleAll();
  return (container, home, budgets, snapshots, store);
}

void main() {
  group('home after a budget is saved', () {
    test(
      'the summary and the categories are asked again, and the widget and the cache follow',
      () async {
        final (container, _, budgets, snapshots, store) = await loaded();
        final controller = container.read(homeProvider.notifier);
        expect(container.read(homeProvider).data!.summary.budgetTotal, 85000000);
        snapshots.clear();

        await budgets.setBudget('cat-groceries', 30000000, month: '2026-10');
        await controller.budgetChanged();
        await settleAll();

        final data = container.read(homeProvider).data!;
        expect(data.summary.budgetTotal, 90000000);
        expect(
          data.summary.categories.firstWhere((c) => c.categoryId == 'cat-groceries').budget,
          30000000,
        );
        expect(data.categories['cat-groceries']!.currentBudget, 30000000);
        expect(snapshots.last.summary.budgetTotal, 90000000, reason: 'the widget follows');
        final cached = await HomeCache(store, token: 't1').read();
        expect(cached!.summary.budgetTotal, 90000000);
        expect(
          cached.categories.firstWhere((c) => c.id == 'cat-groceries').currentBudget,
          30000000,
        );
      },
    );

    test(
      'the latest summary wins: a slow answer to an earlier save cannot undo a later one',
      () async {
        final (container, home, budgets, snapshots, _) = await loaded();
        final controller = container.read(homeProvider.notifier);
        snapshots.clear();

        // The first save's summary is slow; the second save's is fast and lands first.
        await budgets.setBudget('cat-groceries', 30000000, month: '2026-10');
        final slow = Completer<void>();
        home.summaryGates.add(slow);
        final first = controller.budgetChanged();
        await settle();
        await budgets.setBudget('cat-groceries', 40000000, month: '2026-10');
        final second = controller.budgetChanged();
        await second;
        expect(container.read(homeProvider).data!.summary.budgetTotal, 100000000);

        slow.complete();
        await first;
        await settleAll();
        expect(
          container.read(homeProvider).data!.summary.budgetTotal,
          100000000,
          reason: 'the old answer was dropped',
        );
        expect(snapshots.map((s) => s.summary.budgetTotal), everyElement(100000000));
      },
    );

    test('on an earlier month the widget is told the current month, not that one', () async {
      final (container, home, budgets, snapshots, _) = await loaded();
      final controller = container.read(homeProvider.notifier);
      await controller.showMonth('2026-09');
      await settleAll();
      snapshots.clear();
      home.calls.clear();

      await budgets.setBudget('cat-groceries', 30000000, month: '2026-09');
      await controller.budgetChanged();
      await settleAll();

      expect(container.read(homeProvider).data!.month, '2026-09');
      expect(home.calls, contains('summary 2026-09'));
      expect(home.calls, contains('summary 2026-10'), reason: 'the widget reads the current month');
      expect(snapshots, isNotEmpty);
      expect(snapshots.every((s) => s.summary.month == '2026-10'), isTrue);
    });

    test('a refresh that fails keeps the figures on screen and says they may be old', () async {
      final (container, home, budgets, _, _) = await loaded();
      final controller = container.read(homeProvider.notifier);
      await budgets.setBudget('cat-groceries', 30000000, month: '2026-10');
      home.failures['summary'] = const HomeFailure(0);
      await controller.budgetChanged();
      await settleAll();
      final state = container.read(homeProvider);
      expect(state.data!.summary.budgetTotal, 85000000, reason: 'the last figures stay');
      expect(state.stale, isTrue);
      expect(state.staleOffline, isTrue);
    });
  });

  group('a category\'s detail', () {
    Future<(ProviderContainer, FakeBudgetsRepository, FakeHomeRepository)> detail() async {
      final (container, home, budgets, _, _) = await loaded();
      container.listen(categoryDetailProvider('cat-groceries'), (_, _) {});
      return (container, budgets, home);
    }

    test('it loads the month\'s summary and the category\'s movements', () async {
      final (container, budgets, _) = await detail();
      final controller = container.read(categoryDetailProvider('cat-groceries').notifier);
      await controller.showMonth('2026-10');
      final state = container.read(categoryDetailProvider('cat-groceries'));
      expect(state.month, '2026-10');
      expect(state.items!.map((t) => t.id), ['market', 'fruit']);
      expect(state.summary!.month, '2026-10');
      expect(state.failure, isNull);
      expect(budgets.calls, contains('transactions 2026-10 cat-groceries'));
    });

    test('while another month loads, the old month\'s figures are not on screen', () async {
      final (container, _, home) = await detail();
      final controller = container.read(categoryDetailProvider('cat-groceries').notifier);
      await controller.showMonth('2026-10');
      final gate = Completer<void>();
      home.summaryGates.add(gate);
      final moving = controller.showMonth('2026-09');
      final state = container.read(categoryDetailProvider('cat-groceries'));
      expect(state.month, '2026-09');
      expect(state.summary, isNull);
      expect(state.items, isNull);
      gate.complete();
      await moving;
      expect(container.read(categoryDetailProvider('cat-groceries')).items, isEmpty);
    });

    test('the latest month asked for wins, however late an older answer lands', () async {
      final (container, _, home) = await detail();
      final controller = container.read(categoryDetailProvider('cat-groceries').notifier);
      final september = Completer<void>();
      final august = Completer<void>();
      home.summaryGates.addAll([september, august]);
      final first = controller.showMonth('2026-09');
      final second = controller.showMonth('2026-08');
      august.complete();
      await second;
      september.complete();
      await first;
      await settleAll();
      final state = container.read(categoryDetailProvider('cat-groceries'));
      expect(state.month, '2026-08');
      expect(state.summary!.month, '2026-08');
    });

    test(
      'a failed load with nothing to show is a failure to retry; a refresh keeps what is there',
      () async {
        final (container, budgets, _) = await detail();
        final controller = container.read(categoryDetailProvider('cat-groceries').notifier);
        budgets.listFailure = const HomeFailure(0);
        await controller.showMonth('2026-10');
        var state = container.read(categoryDetailProvider('cat-groceries'));
        expect(state.failure!.offline, isTrue);
        expect(state.items, isNull);

        await controller.refresh();
        state = container.read(categoryDetailProvider('cat-groceries'));
        expect(state.failure, isNull);
        expect(state.items, isNotEmpty);

        budgets.listFailure = const HomeFailure(0);
        await controller.refresh();
        state = container.read(categoryDetailProvider('cat-groceries'));
        expect(state.items, isNotEmpty, reason: 'the last list stays');
        expect(state.failure, isNull);
      },
    );

    test(
      'setting a budget refreshes the detail and tells home; a failure changes nothing',
      () async {
        final (container, budgets, home) = await detail();
        final controller = container.read(categoryDetailProvider('cat-groceries').notifier);
        await controller.showMonth('2026-10');

        budgets.saveFailure = const HomeFailure(500);
        await expectLater(controller.setBudget(30000000), throwsA(isA<HomeFailure>()));
        var line = container
            .read(categoryDetailProvider('cat-groceries'))
            .summary!
            .categories
            .firstWhere((c) => c.categoryId == 'cat-groceries');
        expect(line.budget, 25000000);
        expect(container.read(homeProvider).data!.summary.budgetTotal, 85000000);

        await controller.setBudget(30000000);
        await settleAll();
        line = container
            .read(categoryDetailProvider('cat-groceries'))
            .summary!
            .categories
            .firstWhere((c) => c.categoryId == 'cat-groceries');
        expect(line.budget, 30000000);
        expect(budgets.calls, contains('setBudget cat-groceries 30000000 2026-10'));
        expect(container.read(homeProvider).data!.summary.budgetTotal, 90000000);
        expect(home.calls.where((c) => c == 'summary 2026-10').length, greaterThan(1));
      },
    );
  });
}
