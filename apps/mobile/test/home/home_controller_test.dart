import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/lukas_line.dart';

import 'fakes.dart';
import 'fixtures.dart';

/// 2026-10-22 10:00 in Bogota (UTC-5).
final _now = DateTime.utc(2026, 10, 22, 15);

class Snapshot {
  Snapshot(this.summary, this.currency, this.locale);
  final Summary summary;
  final String currency;
  final String locale;
}

(ProviderContainer, FakeHomeRepository, List<Snapshot>) setup(
  FakeHomeRepository repo, {
  FakeCacheStore? cacheStore,
}) {
  final snapshots = <Snapshot>[];
  final container = ProviderContainer(
    overrides: [
      homeRepositoryProvider.overrideWithValue(repo),
      homeCacheProvider.overrideWithValue(HomeCache(cacheStore ?? FakeCacheStore(), token: 't1')),
      clockProvider.overrideWithValue(() => _now),
      widgetSnapshotWriterProvider.overrideWithValue(
        (summary, {required currency, required locale}) async =>
            snapshots.add(Snapshot(summary, currency, locale)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return (container, repo, snapshots);
}

class _FakeSession extends SessionController {
  int signOuts = 0;

  @override
  SessionState build() => SessionState.signedIn(const StoredSession(token: 't', guest: true));

  @override
  Future<void> signOut() async => signOuts++;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

/// Lets background work (a summary on its way) finish.
Future<void> settleAll() async {
  for (var i = 0; i < 5; i++) {
    await settle();
  }
}

void main() {
  test(
    'loads the profile, then the month in the profile zone: summary, categories, first page',
    () async {
      final (container, repo, snapshots) = setup(
        FakeHomeRepository(
          budgetTotal: 100000,
          items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)],
        ),
      );
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();

      final state = container.read(homeProvider);
      expect(state.loading, isFalse);
      expect(state.data!.month, '2026-10');
      expect(state.data!.todayAt(_now), '2026-10-22');
      expect(state.data!.items.map((t) => t.id), ['a', 'b']);
      expect(state.data!.categories.keys, ['cat-groceries']);
      expect(
        repo.calls,
        containsAll(['profile', 'summary 2026-10', 'categories', 'transactions 2026-10']),
      );
      // The widget is told about the figures: its currency and the phone's language.
      expect(snapshots, hasLength(1));
      expect(snapshots.single.currency, 'COP');
      expect(snapshots.single.locale, 'es');
    },
  );

  test('"today" is read in the profile time zone, not the phone UTC', () async {
    // 2026-10-23 02:00 UTC is still the 22nd in Bogota.
    final repo = FakeHomeRepository();
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repo),
        homeCacheProvider.overrideWithValue(HomeCache(FakeCacheStore(), token: 't1')),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 23, 2)),
        widgetSnapshotWriterProvider.overrideWithValue(
          (s, {required currency, required locale}) async {},
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeProvider, (_, _) {});
    await settle();
    await settle();
    expect(container.read(homeProvider).data!.todayAt(DateTime.utc(2026, 10, 23, 2)), '2026-10-22');
  });

  test('pages: loadMore appends the next page and clears the cursor on the last one', () async {
    final (container, repo, _) = setup(
      FakeHomeRepository(
        pageSize: 2,
        items: [for (var i = 5; i >= 1; i--) tx('t$i', '2026-10-0$i', -100 * i)],
      ),
    );
    container.listen(homeProvider, (_, _) {});
    await settle();
    await settle();
    expect(container.read(homeProvider).data!.items, hasLength(2));
    expect(container.read(homeProvider).data!.nextCursor, isNotNull);

    final controller = container.read(homeProvider.notifier);
    await controller.loadMore();
    await controller.loadMore();
    final data = container.read(homeProvider).data!;
    expect(data.items.map((t) => t.id), ['t5', 't4', 't3', 't2', 't1']);
    expect(data.nextCursor, isNull);
    // Nothing more to ask.
    await controller.loadMore();
    expect(repo.calls.where((c) => c.startsWith('transactions')), hasLength(3));
  });

  test('a failed page keeps the list and throws', () async {
    final (container, repo, _) = setup(
      FakeHomeRepository(
        pageSize: 1,
        items: [tx('a', '2026-10-02', -1), tx('b', '2026-10-01', -1)],
      ),
    );
    container.listen(homeProvider, (_, _) {});
    await settle();
    await settle();
    repo.failures['transactions'] = const HomeFailure(0);
    final controller = container.read(homeProvider.notifier);
    await expectLater(controller.loadMore(), throwsA(isA<HomeFailure>()));
    final state = container.read(homeProvider);
    expect(state.data!.items.map((t) => t.id), ['a']);
    expect(state.loadingMore, isFalse);
    await controller.loadMore();
    expect(container.read(homeProvider).data!.items.map((t) => t.id), ['a', 'b']);
  });

  test(
    'offline at the start shows the failure; offline later keeps what was loaded, stale',
    () async {
      final (container, repo, _) = setup(FakeHomeRepository(items: [tx('a', '2026-10-22', -1000)]));
      repo.failures['profile'] = const HomeFailure(0);
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();
      expect(container.read(homeProvider).data, isNull);
      expect(container.read(homeProvider).failure!.offline, isTrue);

      final controller = container.read(homeProvider.notifier);
      await controller.refresh();
      expect(container.read(homeProvider).data!.items, hasLength(1));
      expect(container.read(homeProvider).failure, isNull);
      expect(container.read(homeProvider).stale, isFalse);

      repo.failures['summary'] = const HomeFailure(0);
      await controller.refresh();
      final state = container.read(homeProvider);
      expect(state.data!.items, hasLength(1), reason: 'the last load stays');
      expect(state.stale, isTrue);
    },
  );

  test('a refused session found by the summary, not the profile, signs out too', () async {
    final session = _FakeSession();
    final repo = FakeHomeRepository()
      ..failures['summary'] = const HomeFailure(401)
      ..failures['categories'] = const HomeFailure(500);
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repo),
        homeCacheProvider.overrideWithValue(HomeCache(FakeCacheStore(), token: 't1')),
        sessionProvider.overrideWith(() => session),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeProvider, (_, _) {});
    await settleAll();
    expect(session.signOuts, 1, reason: 'the 401 wins over the 500 next to it');
    expect(container.read(homeProvider).failure!.unauthorized, isTrue);
  });

  test('the server not knowing the token signs the person out', () async {
    final session = _FakeSession();
    final repo = FakeHomeRepository()..failures['profile'] = const HomeFailure(401);
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repo),
        homeCacheProvider.overrideWithValue(HomeCache(FakeCacheStore(), token: 't1')),
        sessionProvider.overrideWith(() => session),
        clockProvider.overrideWithValue(() => _now),
        widgetSnapshotWriterProvider.overrideWithValue(
          (s, {required currency, required locale}) async {},
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeProvider, (_, _) {});
    await settle();
    await settle();
    expect(session.signOuts, 1);
    expect(container.read(homeProvider).failure!.unauthorized, isTrue);
  });

  test(
    'remove takes the row out at once and refreshes the summary; restore puts the same row back',
    () async {
      final (container, repo, _) = setup(
        FakeHomeRepository(items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)]),
      );
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();
      final controller = container.read(homeProvider.notifier);
      final a = container.read(homeProvider).data!.items.first;

      await controller.remove(a);
      expect(container.read(homeProvider).data!.items.map((t) => t.id), ['b']);
      expect(repo.deleted.map((t) => t.id), ['a']);
      await settleAll();
      expect(container.read(homeProvider).data!.summary.spent, 2000);

      await controller.restore(a);
      await settleAll();
      expect(container.read(homeProvider).data!.items.map((t) => t.id), ['a', 'b']);
      expect(container.read(homeProvider).restored, {'a'});
      expect(repo.calls, contains('restore a'));
      expect(container.read(homeProvider).data!.summary.spent, 3000);
      controller.settleRestored('a');
      expect(container.read(homeProvider).restored, isEmpty);
    },
  );

  test('a refused delete brings the row back and throws', () async {
    final (container, repo, _) = setup(FakeHomeRepository(items: [tx('a', '2026-10-22', -1000)]));
    container.listen(homeProvider, (_, _) {});
    await settle();
    await settle();
    repo.failures['delete'] = const HomeFailure(500);
    final controller = container.read(homeProvider.notifier);
    await expectLater(
      controller.remove(container.read(homeProvider).data!.items.first),
      throwsA(isA<HomeFailure>()),
    );
    expect(container.read(homeProvider).data!.items.map((t) => t.id), ['a']);
  });

  test(
    'markPaid pays once, refreshes the summary and starts the event Lukitas talks about',
    () async {
      final (container, repo, _) = setup(
        FakeHomeRepository(
          budgetTotal: 100000000,
          items: [tx('rent', '2026-10-25', -50000000, name: 'Arriendo', status: 'pending')],
        ),
      );
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();
      final controller = container.read(homeProvider.notifier);
      final rent = container.read(homeProvider).data!.items.first;
      expect(container.read(homeProvider).data!.summary.spent, 0);

      await controller.markPaid(rent);
      await controller.markPaid(rent); // a second quick swipe never pays it again
      final state = container.read(homeProvider);
      expect(repo.calls.where((c) => c.startsWith('markPaid')), ['markPaid rent']);
      expect(state.data!.items.first.status, TransactionStatusEnum.paid);
      expect(state.paidHere, {'rent'});
      expect(state.data!.summary.spent, 50000000);
      expect(state.event!.event.kind, LukasEventKind.paid);
      expect(state.event!.event.name, 'Arriendo');
    },
  );

  test('a refused payment puts the row back to pending', () async {
    final (container, repo, _) = setup(
      FakeHomeRepository(items: [tx('rent', '2026-10-25', -100, status: 'pending')]),
    );
    container.listen(homeProvider, (_, _) {});
    await settle();
    await settle();
    repo.failures['markPaid'] = const HomeFailure(500);
    final controller = container.read(homeProvider.notifier);
    await expectLater(
      controller.markPaid(container.read(homeProvider).data!.items.first),
      throwsA(isA<HomeFailure>()),
    );
    final state = container.read(homeProvider);
    expect(state.data!.items.first.status, TransactionStatusEnum.pending);
    expect(state.paidHere, isEmpty);
    expect(state.event, isNull);
  });

  testWidgets('an event lasts 10 s, a newer one restarts the clock', (tester) async {
    final (container, _, _) = setup(FakeHomeRepository());
    container.listen(homeProvider, (_, _) {});
    final controller = container.read(homeProvider.notifier);
    controller.report(
      const LukasEvent(kind: LukasEventKind.saved, categoryId: 'c', amount: -100, name: 'one'),
    );
    await tester.pump(const Duration(seconds: 6));
    controller.report(
      const LukasEvent(kind: LukasEventKind.saved, categoryId: 'c', amount: -100, name: 'two'),
    );
    await tester.pump(const Duration(seconds: 6));
    expect(container.read(homeProvider).event!.event.name, 'two');
    await tester.pump(const Duration(seconds: 4));
    expect(container.read(homeProvider).event, isNull);
  });

  group('the cache of the last good month', () {
    test('every good load saves it, bound to the user and the session', () async {
      final store = FakeCacheStore();
      final (container, _, _) = setup(
        FakeHomeRepository(items: [tx('a', '2026-10-22', -1000, name: 'Café')]),
        cacheStore: store,
      );
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();

      final cached = (await HomeCache(store, token: 't1').read())!;
      expect(cached.userId, 'user-1');
      expect(cached.month, '2026-10');
      expect(cached.items.map((t) => t.name), ['Café']);
      expect(await HomeCache(store, token: 't2').read(), isNull);
    });

    test('a delete and its undo keep it in step with the list', () async {
      final store = FakeCacheStore();
      final (container, _, _) = setup(
        FakeHomeRepository(items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)]),
        cacheStore: store,
      );
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();
      final controller = container.read(homeProvider.notifier);
      final a = container.read(homeProvider).data!.items.first;

      await controller.remove(a);
      await settle();
      await settle();
      expect((await HomeCache(store, token: 't1').read())!.items.map((t) => t.id), ['b']);
      expect((await HomeCache(store, token: 't1').read())!.summary.spent, 2000);

      await controller.restore(a);
      await settle();
      await settle();
      expect((await HomeCache(store, token: 't1').read())!.items.map((t) => t.id), ['a', 'b']);
    });

    test('a start with no answer shows the cache, stale, with today read again', () async {
      final store = FakeCacheStore();
      final (first, _, _) = setup(
        FakeHomeRepository(budgetTotal: 100000, items: [tx('a', '2026-10-22', -1000)]),
        cacheStore: store,
      );
      first.listen(homeProvider, (_, _) {});
      await settle();
      await settle();

      final offline = FakeHomeRepository()..failures['profile'] = const HomeFailure(0);
      final (container, _, _) = setup(offline, cacheStore: store);
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();
      final state = container.read(homeProvider);
      expect(state.stale, isTrue);
      expect(state.failure, isNull);
      expect(state.data!.items.map((t) => t.id), ['a']);
      expect(state.data!.summary.budgetTotal, 100000);
      expect(state.data!.currency, 'COP');
      expect(state.data!.todayAt(_now), '2026-10-22');
    });

    test('a delete and its undo reach the cache even when the summary fails', () async {
      final store = FakeCacheStore();
      final (container, repo, _) = setup(
        FakeHomeRepository(items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)]),
        cacheStore: store,
      );
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      final controller = container.read(homeProvider.notifier);
      final a = container.read(homeProvider).data!.items.first;

      repo.failures['summary'] = const HomeFailure(500);
      await controller.remove(a);
      await settleAll();
      expect((await HomeCache(store, token: 't1').read())!.items.map((t) => t.id), ['b']);

      repo.failures['summary'] = const HomeFailure(500);
      await controller.restore(a);
      await settleAll();
      expect((await HomeCache(store, token: 't1').read())!.items.map((t) => t.id), ['a', 'b']);
    });

    test('no cache: the failure shows as before; another session never sees the cache', () async {
      final store = FakeCacheStore();
      final (first, _, _) = setup(
        FakeHomeRepository(items: [tx('a', '2026-10-22', -1000)]),
        cacheStore: store,
      );
      first.listen(homeProvider, (_, _) {});
      await settle();
      await settle();

      // Another person on the same phone: their token is not the one the cache was written for.
      final repo = FakeHomeRepository()..failures['profile'] = const HomeFailure(0);
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repo),
          homeCacheProvider.overrideWithValue(HomeCache(store, token: 't2')),
          clockProvider.overrideWithValue(() => _now),
        ],
      );
      addTearDown(container.dispose);
      container.listen(homeProvider, (_, _) {});
      await settle();
      await settle();
      expect(container.read(homeProvider).data, isNull);
      expect(container.read(homeProvider).failure!.offline, isTrue);
    });
  });

  group('summaries that arrive out of order', () {
    test(
      'the latest request wins: the screen, the cache and the widget end with its figures',
      () async {
        final store = FakeCacheStore();
        final repo = FakeHomeRepository(
          items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)],
        );
        final (container, _, snapshots) = setup(repo, cacheStore: store);
        container.listen(homeProvider, (_, _) {});
        await settleAll();
        final controller = container.read(homeProvider.notifier);
        final a = container.read(homeProvider).data!.items.first;
        snapshots.clear();

        // The delete's summary is slow; the undo's is fast and lands first.
        final slow = Completer<void>();
        repo.summaryGates.add(slow);
        await controller.remove(a);
        await controller.restore(a);
        await settleAll();
        expect(container.read(homeProvider).data!.summary.spent, 3000);

        slow.complete();
        await settleAll();
        final state = container.read(homeProvider);
        expect(state.data!.items.map((t) => t.id), ['a', 'b']);
        expect(state.data!.summary.spent, 3000, reason: 'the old answer was dropped');
        expect((await HomeCache(store, token: 't1').read())!.summary.spent, 3000);
        expect(snapshots.map((s) => s.summary.spent), everyElement(3000));
        expect(snapshots, isNotEmpty);
      },
    );
  });

  group('errors', () {
    test('a 401 on an older summary that is dropped still signs the person out', () async {
      final session = _FakeSession();
      final repo = FakeHomeRepository(
        items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)],
      );
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repo),
          homeCacheProvider.overrideWithValue(HomeCache(FakeCacheStore(), token: 't1')),
          sessionProvider.overrideWith(() => session),
          clockProvider.overrideWithValue(() => _now),
          widgetSnapshotWriterProvider.overrideWithValue(
            (s, {required currency, required locale}) async {},
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      final controller = container.read(homeProvider.notifier);
      final a = container.read(homeProvider).data!.items.first;

      final slow = Completer<void>();
      repo.summaryGates.add(slow);
      await controller.remove(a);
      await controller.restore(a); // its fast summary makes the first one stale
      await settleAll();
      expect(session.signOuts, 0);

      slow.completeError(const HomeFailure(401));
      await settleAll();
      expect(session.signOuts, 1);
    });

    test(
      'the same unexpected error gives the same note in a load and in a delete refresh',
      () async {
        final (container, repo, _) = setup(
          FakeHomeRepository(items: [tx('a', '2026-10-22', -1000), tx('b', '2026-10-21', -2000)]),
        );
        container.listen(homeProvider, (_, _) {});
        await settleAll();
        final controller = container.read(homeProvider.notifier);

        repo.failures['summary'] = StateError('not an HTTP error');
        await controller.refresh();
        final fromLoad = container.read(homeProvider).staleOffline;

        await controller.refresh(); // good again
        expect(container.read(homeProvider).stale, isFalse);
        repo.failures['summary'] = StateError('not an HTTP error');
        await controller.remove(container.read(homeProvider).data!.items.first);
        await settleAll();
        final state = container.read(homeProvider);
        expect(state.stale, isTrue);
        expect(state.staleOffline, fromLoad);
      },
    );
  });

  group('after the screen is gone', () {
    test('a load that finishes later writes no snapshot and throws nothing', () async {
      final repo = FakeHomeRepository(items: [tx('a', '2026-10-22', -1000)]);
      final gate = Completer<void>();
      repo.holdSummary = gate;
      final (container, _, snapshots) = setup(repo);
      final errors = <Object>[];
      await runZonedGuarded(() async {
        container.listen(homeProvider, (_, _) {});
        await settle();
        await settle();
        container.dispose();
        gate.complete();
        await settle();
        await settle();
        await settle();
      }, (error, _) => errors.add(error));
      expect(errors, isEmpty);
      expect(snapshots, isEmpty);
    });

    test('a failed load that ends later throws nothing either', () async {
      final repo = FakeHomeRepository();
      final gate = Completer<void>();
      repo.holdSummary = gate;
      // Not a refused session (that skips the cache): the cache is read after home was left.
      repo.failures['categories'] = const HomeFailure(500);
      final store = FakeCacheStore();
      await HomeCache(store, token: 't1').write(
        CachedHome(
          userId: 'user-1',
          currency: 'COP',
          timezone: 'America/Bogota',
          month: '2026-10',
          summary: summary(),
          categories: const [],
          items: const [],
        ),
      );
      final (container, _, _) = setup(repo, cacheStore: store);
      final errors = <Object>[];
      await runZonedGuarded(() async {
        container.listen(homeProvider, (_, _) {});
        await settle();
        container.dispose();
        gate.complete();
        await settle();
        await settle();
        await settle();
      }, (error, _) => errors.add(error));
      expect(errors, isEmpty);
    });
  });
}
