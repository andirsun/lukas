import 'dart:async';
import 'dart:convert';

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
  Snapshot(this.summary, this.currency, this.locale, this.timezone);
  final Summary summary;
  final String currency;
  final String locale;
  final String timezone;
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
        (summary, {required currency, required locale, required timezone}) async =>
            snapshots.add(Snapshot(summary, currency, locale, timezone)),
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
  Future<void> signOut({bool discardGuest = false}) async => signOuts++;
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
      // The profile's zone: the widget reads "this month" and its midnight in it.
      expect(snapshots.single.timezone, 'America/Bogota');
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
          (s, {required currency, required locale, required timezone}) async {},
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
          (s, {required currency, required locale, required timezone}) async {},
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

  testWidgets('when an event line ends the quiet key changes, so going back is not announced', (
    tester,
  ) async {
    final (container, _, _) = setup(FakeHomeRepository());
    container.listen(homeProvider, (_, _) {});
    final controller = container.read(homeProvider.notifier);
    final before = container.read(homeProvider).quietKey;
    controller.report(
      const LukasEvent(kind: LukasEventKind.saved, categoryId: 'c', amount: -100, name: 'one'),
    );
    expect(container.read(homeProvider).quietKey, before, reason: 'the line itself is announced');
    await tester.pump(const Duration(seconds: 11));
    expect(container.read(homeProvider).event, isNull);
    expect(container.read(homeProvider).quietKey, isNot(before));
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

  group('months', () {
    FakeHomeRepository twoMonths() => FakeHomeRepository(
      budgetTotal: 100000,
      items: [
        tx('oct', '2026-10-22', -1000),
        tx('sep1', '2026-09-15', -5000, name: 'Septiembre'),
        tx('sep2', '2026-09-02', -2000),
        tx('aug', '2026-08-10', -9000),
      ],
    );

    Future<(ProviderContainer, FakeHomeRepository, List<Snapshot>, FakeCacheStore)> loaded() async {
      final store = FakeCacheStore();
      final (container, repo, snapshots) = setup(twoMonths(), cacheStore: store);
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      return (container, repo, snapshots, store);
    }

    Future<String> cachedMonth(FakeCacheStore store) async =>
        (jsonDecode(store.value!) as Map<String, Object?>)['month']! as String;

    test('showMonth moves to the month and loads its summary and movements', () async {
      final (container, repo, _, _) = await loaded();
      expect(container.read(homeProvider).month, '2026-10');

      await container.read(homeProvider.notifier).showMonth('2026-09');
      final state = container.read(homeProvider);
      expect(state.month, '2026-09');
      expect(state.shown!.month, '2026-09');
      expect(state.shown!.items.map((t) => t.id), ['sep1', 'sep2']);
      expect(state.shown!.summary.month, '2026-09');
      expect(state.shown!.summary.spent, 7000);
      expect(state.loading, isFalse);
      expect(repo.calls, containsAll(['summary 2026-09', 'transactions 2026-09']));
    });

    test('a month after the current one is the current one', () async {
      final (container, _, _, _) = await loaded();
      await container.read(homeProvider.notifier).showMonth('2026-12');
      expect(container.read(homeProvider).month, '2026-10');
      expect(container.read(homeProvider).shown!.items.map((t) => t.id), ['oct']);
    });

    test(
      'an earlier month never reaches the widget or the cache, which hold the current one',
      () async {
        final (container, _, snapshots, store) = await loaded();
        expect(snapshots, hasLength(1));
        await container.read(homeProvider.notifier).showMonth('2026-09');
        await settleAll();
        expect(snapshots, hasLength(1), reason: 'the widget keeps the current month');
        expect(snapshots.single.summary.month, '2026-10');
        expect(await cachedMonth(store), '2026-10');
      },
    );

    test('the latest month asked for wins, however late an older answer lands', () async {
      final (container, repo, _, _) = await loaded();
      final controller = container.read(homeProvider.notifier);
      final september = Completer<void>();
      final august = Completer<void>();
      repo.summaryGates.addAll([september, august]);

      final first = controller.showMonth('2026-09');
      final second = controller.showMonth('2026-08');
      expect(container.read(homeProvider).month, '2026-08');
      august.complete();
      await second;
      expect(container.read(homeProvider).shown!.month, '2026-08');

      september.complete();
      await first;
      await settleAll();
      final state = container.read(homeProvider);
      expect(state.month, '2026-08');
      expect(state.shown!.items.map((t) => t.id), ['aug'], reason: 'September was dropped');
    });

    test('while it loads, no other month is on screen as this one', () async {
      final (container, repo, _, _) = await loaded();
      final gate = Completer<void>();
      repo.summaryGates.add(gate);
      final moving = container.read(homeProvider.notifier).showMonth('2026-09');
      final state = container.read(homeProvider);
      expect(state.month, '2026-09');
      expect(state.loading, isTrue);
      expect(state.shown, isNull, reason: 'October is still in data, but it is not September');
      gate.complete();
      await moving;
      expect(container.read(homeProvider).shown!.month, '2026-09');
    });

    test('offline, another month says so and never shows the cache as that month', () async {
      final (container, repo, _, store) = await loaded();
      expect(await cachedMonth(store), '2026-10');
      repo.failures['summary'] = const HomeFailure(0);

      await container.read(homeProvider.notifier).showMonth('2026-09');
      final state = container.read(homeProvider);
      expect(state.month, '2026-09');
      expect(state.shown, isNull, reason: 'no figures: not October\'s, not a cache of September');
      expect(state.failure!.offline, isTrue);
      expect(state.loading, isFalse);

      // Back online, a retry brings the month.
      await container.read(homeProvider.notifier).refresh();
      expect(container.read(homeProvider).failure, isNull);
      expect(container.read(homeProvider).shown!.month, '2026-09');
    });

    test(
      'back to the current month with no network, the cache of the current month shows',
      () async {
        final (container, repo, _, _) = await loaded();
        final controller = container.read(homeProvider.notifier);
        await controller.showMonth('2026-09');
        repo.failures['summary'] = const HomeFailure(0);

        await controller.showMonth('2026-10');
        final state = container.read(homeProvider);
        expect(state.shown!.month, '2026-10');
        expect(state.stale, isTrue);
        expect(state.staleOffline, isTrue);
        expect(state.shown!.items.map((t) => t.id), ['oct']);
      },
    );

    test(
      'refreshing on an earlier month reloads it, and tells the widget the current one',
      () async {
        final (container, repo, snapshots, _) = await loaded();
        final controller = container.read(homeProvider.notifier);
        await controller.showMonth('2026-09');
        snapshots.clear();
        repo.calls.clear();

        await controller.refresh();
        await settleAll();
        expect(
          container.read(homeProvider).shown!.month,
          '2026-09',
          reason: 'it stays on September',
        );
        expect(repo.calls, contains('summary 2026-09'));
        expect(snapshots.map((s) => s.summary.month), ['2026-10']);
      },
    );

    test('a save while on an earlier month updates the widget with the current month', () async {
      final (container, repo, snapshots, store) = await loaded();
      final controller = container.read(homeProvider.notifier);
      await controller.showMonth('2026-09');
      snapshots.clear();

      final saved = tx('new', '2026-10-22', -500, name: 'Café');
      repo.items.add(saved);
      await controller.saved(saved);
      await settleAll();
      final state = container.read(homeProvider);
      expect(state.shown!.items.map((t) => t.id), ['sep1', 'sep2'], reason: 'not a September row');
      expect(snapshots, isNotEmpty);
      expect(snapshots.map((s) => s.summary.month), everyElement('2026-10'));
      expect(snapshots.last.summary.spent, 1500);
      expect(await cachedMonth(store), '2026-10');
      expect(state.event!.month, '2026-10', reason: 'Lukitas says it in October, not September');
    });

    test(
      'opening on an earlier month (a ?month= link) loads it, and the widget the current one',
      () async {
        final store = FakeCacheStore();
        final (container, repo, snapshots) = setup(twoMonths(), cacheStore: store);
        container.listen(homeProvider, (_, _) {});
        final moving = container.read(homeProvider.notifier).showMonth('2026-09');
        await moving;
        await settleAll();
        final state = container.read(homeProvider);
        expect(state.shown!.month, '2026-09');
        expect(repo.calls.where((c) => c.startsWith('transactions')), ['transactions 2026-09']);
        expect(snapshots.map((s) => s.summary.month), ['2026-10']);
        expect(store.value, isNull, reason: 'the cache keeps only the current month');
      },
    );

    test('the month follows the clock while it is the current one', () async {
      var now = DateTime.utc(2026, 10, 31, 20);
      final repo = twoMonths();
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repo),
          homeCacheProvider.overrideWithValue(HomeCache(FakeCacheStore(), token: 't1')),
          clockProvider.overrideWithValue(() => now),
          widgetSnapshotWriterProvider.overrideWithValue(
            (s, {required currency, required locale, required timezone}) async {},
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      expect(container.read(homeProvider).month, '2026-10');

      now = DateTime.utc(2026, 11, 1, 12);
      await container.read(homeProvider.notifier).refresh();
      expect(container.read(homeProvider).month, '2026-11');
    });

    test('an event knows its month', () async {
      final (container, _, _, _) = await loaded();
      final controller = container.read(homeProvider.notifier);
      controller.report(
        const LukasEvent(kind: LukasEventKind.saved, categoryId: 'c', amount: -100),
        month: '2026-09',
      );
      expect(container.read(homeProvider).event!.month, '2026-09');
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
            (s, {required currency, required locale, required timezone}) async {},
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

  group('a quick-capture batch', () {
    test('its rows show at once, and the summary is asked once', () async {
      final (container, repo, _) = setup(FakeHomeRepository(items: [tx('a', '2026-10-20', -1000)]));
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      final before = repo.calls.where((c) => c.startsWith('summary')).length;

      await container.read(homeProvider.notifier).savedBatch([
        tx('b1', '2026-10-22', -1500000),
        tx('b2', '2026-10-21', -300000),
      ]);
      final ids = container.read(homeProvider).data!.items.map((t) => t.id);
      expect(ids, ['b1', 'b2', 'a']);
      expect(repo.calls.where((c) => c.startsWith('summary')).length, before + 1);
    });

    test('forget takes its rows off together (Deshacer), and the summary follows', () async {
      final (container, repo, _) = setup(
        FakeHomeRepository(
          items: [
            tx('b1', '2026-10-22', -100),
            tx('b2', '2026-10-21', -200),
            tx('a', '2026-10-20', -1),
          ],
        ),
      );
      container.listen(homeProvider, (_, _) {});
      await settleAll();
      final before = repo.calls.where((c) => c.startsWith('summary')).length;

      await container.read(homeProvider.notifier).forget(['b1', 'b2']);
      expect(container.read(homeProvider).data!.items.map((t) => t.id), ['a']);
      expect(repo.calls.where((c) => c.startsWith('summary')).length, before + 1);
    });
  });
}
