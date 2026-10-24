// What home does when the add sheet saves or edits a movement: the row is there at once, the cache
// and the widget's snapshot follow, and the summary is the latest word.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/lukas_line.dart';

import '../home/fakes.dart';
import '../home/fixtures.dart';

/// 2026-10-22 10:00 in Bogota (UTC-5).
final _now = DateTime.utc(2026, 10, 22, 15);

class _Snapshot {
  _Snapshot(this.spent);
  final int spent;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

Future<void> settleAll() async {
  for (var i = 0; i < 6; i++) {
    await settle();
  }
}

(ProviderContainer, List<_Snapshot>) setup(FakeHomeRepository repo, FakeCacheStore store) {
  final snapshots = <_Snapshot>[];
  final container = ProviderContainer(
    overrides: [
      homeRepositoryProvider.overrideWithValue(repo),
      homeCacheProvider.overrideWithValue(HomeCache(store, token: 't1')),
      clockProvider.overrideWithValue(() => _now),
      widgetSnapshotWriterProvider.overrideWithValue(
        (summary, {required currency, required locale, required timezone}) async =>
            snapshots.add(_Snapshot(summary.spent)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return (container, snapshots);
}

void main() {
  test(
    'a saved movement is in the list at once, and the summary, cache and widget catch up',
    () async {
      final store = FakeCacheStore();
      final repo = FakeHomeRepository(items: [tx('a', '2026-10-21', -1000)]);
      final (container, snapshots) = setup(repo, store);
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      final controller = container.read(homeProvider.notifier);

      final created = tx('new', '2026-10-22', -2500, name: 'Café');
      repo.items.insert(0, created);
      final saving = controller.saved(created);
      expect(container.read(homeProvider).data!.items.map((t) => t.id), ['new', 'a']);
      await saving;
      await settleAll();

      final state = container.read(homeProvider);
      expect(state.data!.summary.spent, 3500);
      expect((await HomeCache(store, token: 't1').read())!.items.map((t) => t.id), ['new', 'a']);
      expect(snapshots.last.spent, 3500);
      // Lukitas talks about it once the figures are in.
      expect(state.event!.event.kind, LukasEventKind.saved);
      expect(state.event!.event.name, 'Café');
      expect(state.event!.event.amount, -2500);
      expect(state.event!.event.categoryId, 'cat-groceries');
      container.invalidate(homeProvider);
    },
  );

  test('a movement of another month is not listed, the summary is still asked again', () async {
    final repo = FakeHomeRepository(items: [tx('a', '2026-10-21', -1000)]);
    final (container, _) = setup(repo, FakeCacheStore());
    container.listen(homeProvider, (_, _) {});
    await settleAll();
    final controller = container.read(homeProvider.notifier);
    final before = repo.calls.where((c) => c.startsWith('summary')).length;

    await controller.saved(tx('old', '2026-09-30', -5000));
    await settleAll();
    expect(container.read(homeProvider).data!.items.map((t) => t.id), ['a']);
    expect(repo.calls.where((c) => c.startsWith('summary')).length, before + 1);
  });

  test('an edited movement is replaced in its place; one moved out of the month leaves', () async {
    final store = FakeCacheStore();
    final repo = FakeHomeRepository(
      items: [
        tx('a', '2026-10-22', -1000, name: 'Café'),
        tx('b', '2026-10-21', -2000),
      ],
    );
    final (container, _) = setup(repo, store);
    container.listen(homeProvider, (_, _) {});
    await settleAll();
    final controller = container.read(homeProvider.notifier);

    repo.items[0] = tx('a', '2026-10-22', -4000, name: 'Café con pan');
    await controller.updated(repo.items[0]);
    await settleAll();
    final state = container.read(homeProvider);
    expect(state.data!.items.map((t) => t.name), ['Café con pan', 'b']);
    expect(state.data!.summary.spent, 6000);
    expect((await HomeCache(store, token: 't1').read())!.items.first.name, 'Café con pan');
    // An edit is no celebration.
    expect(state.event, isNull);

    repo.items.removeAt(0);
    await controller.updated(tx('a', '2026-09-30', -4000));
    await settleAll();
    expect(container.read(homeProvider).data!.items.map((t) => t.id), ['b']);
  });

  test('an edit that moves the date reorders the list', () async {
    final repo = FakeHomeRepository(
      items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)],
    );
    final (container, _) = setup(repo, FakeCacheStore());
    container.listen(homeProvider, (_, _) {});
    await settleAll();
    await container.read(homeProvider.notifier).updated(tx('a', '2026-10-20', -1000));
    await settleAll();
    expect(container.read(homeProvider).data!.items.map((t) => t.id), ['b', 'a']);
  });

  test(
    'the latest summary wins: a slow answer to an earlier save cannot undo a later one',
    () async {
      final repo = FakeHomeRepository(items: [tx('a', '2026-10-21', -1000)]);
      final (container, snapshots) = setup(repo, FakeCacheStore());
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      final controller = container.read(homeProvider.notifier);

      // The first save's summary is slow; the second one's is quick.
      final slow = Completer<void>();
      repo.summaryGates.add(slow);
      final first = tx('one', '2026-10-22', -2000);
      repo.items.insert(0, first);
      final firstSaved = controller.saved(first);
      await settleAll();

      final second = tx('two', '2026-10-22', -3000);
      repo.items.insert(0, second);
      await controller.saved(second);
      await settleAll();
      expect(container.read(homeProvider).data!.summary.spent, 6000);

      slow.complete();
      await firstSaved;
      await settleAll();
      expect(container.read(homeProvider).data!.summary.spent, 6000);
      expect(snapshots.last.spent, 6000);
    },
  );
}
