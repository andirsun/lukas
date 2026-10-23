import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/session.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/insights/insights_controller.dart';
import 'package:lukitas/insights/insights_model.dart';
import 'package:lukitas/insights/insights_repository.dart';

import '../home/fakes.dart';
import '../home/fixtures.dart';
import 'fakes.dart';

/// 2026-10-22 10:00 in Bogota (UTC-5).
final _now = DateTime.utc(2026, 10, 22, 15);

Future<void> settle() => Future<void>.delayed(Duration.zero);

Future<void> settleAll() async {
  for (var i = 0; i < 8; i++) {
    await settle();
  }
}

class _FakeSession extends SessionController {
  int signOuts = 0;

  @override
  SessionState build() => SessionState.signedIn(const StoredSession(token: 't', guest: true));

  @override
  Future<void> signOut({bool discardGuest = false}) async => signOuts++;
}

typedef World = (ProviderContainer container, FakeHomeRepository home, FakeInsightsRepository repo);

/// Home loaded (the profile and the categories are home's) and Análisis not started yet.
Future<World> world({
  FakeHomeRepository? home,
  FakeInsightsRepository? repo,
  SessionController? session,
}) async {
  final server = home ?? insightsHome();
  final reports = repo ?? insightsFor(server);
  final container = ProviderContainer(
    overrides: [
      homeRepositoryProvider.overrideWithValue(server),
      insightsRepositoryProvider.overrideWithValue(reports),
      homeCacheProvider.overrideWithValue(HomeCache(FakeCacheStore(), token: 't1')),
      if (session != null) sessionProvider.overrideWith(() => session),
      clockProvider.overrideWithValue(() => _now),
      widgetSnapshotWriterProvider.overrideWithValue(
        (summary, {required currency, required locale, required timezone}) async {},
      ),
    ],
  );
  addTearDown(container.dispose);
  container.listen(homeProvider, (_, _) {});
  container.listen(insightsProvider, (_, _) {});
  await settleAll();
  return (container, server, reports);
}

void main() {
  group('opening', () {
    test(
      'asks for the month, its trend and what living costs, with the web\'s parameters',
      () async {
        final (container, _, repo) = await world();
        await container.read(insightsProvider.notifier).start(null);
        await settleAll();

        expect(repo.calls, [
          'byCategory 2026-10 2026-10 expense -',
          'trend 2026-10 2026-10',
          'trend 2026-04 2026-09',
          'costOfLiving 2',
        ]);
        final state = container.read(insightsProvider);
        expect(state.end, '2026-10');
        expect(state.span, 1);
        expect(state.byCategory.data!.items.first.name, 'Hogar');
        // Lukitas' spending is the donut's own answer: one request, not two.
        expect(state.spending.data, same(state.byCategory.data));
        expect(state.trend.data!.months.single.month, '2026-10');
        expect(state.livingMonths, 2, reason: 'August is the first month with anything');
        expect(state.living.data!.months, 2);
      },
    );

    test('opens on the month it is given, and never after the current one', () async {
      final (container, _, repo) = await world();
      await container.read(insightsProvider.notifier).start('2026-09');
      await settleAll();
      expect(container.read(insightsProvider).end, '2026-09');
      expect(repo.calls.first, 'byCategory 2026-09 2026-09 expense -');

      await container.read(insightsProvider.notifier).showMonth('2027-03');
      await settleAll();
      expect(container.read(insightsProvider).end, '2026-10', reason: 'no looking ahead');
    });

    test('without a complete month with movements there is no average to ask for', () async {
      final (container, _, repo) = await world(
        home: FakeHomeRepository(
          timezone: 'America/Bogota',
          items: [tx('now', '2026-10-05', -100000)],
        ),
      );
      await container.read(insightsProvider.notifier).start(null);
      await settleAll();
      expect(repo.calls.where((c) => c.startsWith('costOfLiving')), isEmpty);
      expect(container.read(insightsProvider).livingMonths, 0);
      expect(container.read(insightsProvider).failure, isNull);
    });
  });

  group('changing what is shown', () {
    test(
      'a span asks for that many months, and the old answer stays, as what it answers',
      () async {
        final (container, _, repo) = await world();
        final controller = container.read(insightsProvider.notifier);
        await controller.start(null);
        await settleAll();
        repo.calls.clear();
        final gate = Completer<void>();
        repo.gates['byCategory'] = [gate];

        final done = controller.setSpan(3);
        await settle();
        var state = container.read(insightsProvider);
        expect(state.period, const Period('2026-08', '2026-10'));
        // The figures on screen are still October's, and say so (the web's isPlaceholderData).
        expect(state.byCategory.stale, isTrue);
        expect(state.byCategory.loading, isTrue);
        expect(state.byCategory.dataKey, (
          period: const Period('2026-10', '2026-10'),
          kind: InsightsKind.expense,
          status: InsightsStatus.all,
        ));
        expect(state.byCategory.data, isNotNull);

        gate.complete();
        await done;
        state = container.read(insightsProvider);
        expect(state.byCategory.stale, isFalse);
        expect(
          repo.calls,
          containsAll(['byCategory 2026-08 2026-10 expense -', 'trend 2026-08 2026-10']),
        );
        expect(
          repo.calls.where((c) => c.startsWith('trend 2026-04')),
          isEmpty,
          reason: 'what living costs does not depend on the span',
        );
      },
    );

    test(
      'income and a status are asked as the web asks them, and Lukitas still talks about spending',
      () async {
        final (container, _, repo) = await world();
        final controller = container.read(insightsProvider.notifier);
        await controller.start(null);
        await settleAll();
        repo.calls.clear();

        await controller.setKind(InsightsKind.income);
        await settleAll();
        await controller.setStatus(InsightsStatus.paid);
        await settleAll();

        expect(repo.calls, [
          'byCategory 2026-10 2026-10 income -',
          'byCategory 2026-10 2026-10 income paid',
        ], reason: 'the spending Lukitas talks about was kept from the first answer');
        final state = container.read(insightsProvider);
        expect(state.byCategory.data!.items.map((i) => i.name), ['Nómina']);
        expect(state.spending.data!.items.first.name, 'Hogar');
        expect(state.spending.stale, isFalse);
      },
    );

    test('moving the month moves the period, and asks for the new one only', () async {
      final (container, _, repo) = await world();
      final controller = container.read(insightsProvider.notifier);
      await controller.start(null);
      await controller.setSpan(3);
      await settleAll();
      repo.calls.clear();

      await controller.showMonth('2026-09');
      await settleAll();

      expect(container.read(insightsProvider).period, const Period('2026-07', '2026-09'));
      expect(repo.calls, ['byCategory 2026-07 2026-09 expense -', 'trend 2026-07 2026-09']);
    });
  });

  group('the latest request wins', () {
    test('an older answer that lands late does not replace a newer one', () async {
      final (container, _, repo) = await world();
      final controller = container.read(insightsProvider.notifier);
      await controller.start(null);
      await settleAll();

      // Income first (slow), then back to spending (fast).
      final slow = Completer<void>();
      repo.gates['byCategory'] = [slow];
      final first = controller.setKind(InsightsKind.income);
      await settle();
      await controller.setKind(InsightsKind.expense);
      await settleAll();
      expect(container.read(insightsProvider).byCategory.data!.items.first.name, 'Hogar');

      slow.complete();
      await first;
      await settleAll();
      final state = container.read(insightsProvider);
      expect(
        state.byCategory.data!.items.first.name,
        'Hogar',
        reason: 'the old answer was dropped',
      );
      expect(state.byCategory.loading, isFalse);
      expect(state.byCategory.stale, isFalse);
    });

    test('an earlier month\'s trend never lands under a later month', () async {
      final (container, _, repo) = await world();
      final controller = container.read(insightsProvider.notifier);
      await controller.start(null);
      await settleAll();

      final slow = Completer<void>();
      repo.gates['trend'] = [slow];
      final first = controller.showMonth('2026-09');
      await settle();
      await controller.showMonth('2026-08');
      await settleAll();
      slow.complete();
      await first;
      await settleAll();

      final state = container.read(insightsProvider);
      expect(state.end, '2026-08');
      expect(state.trend.data!.months.single.month, '2026-08');
      expect(state.trend.dataKey, const Period('2026-08', '2026-08'));
    });
  });

  group('when a report cannot load', () {
    test('with nothing on screen yet it is a failure to retry, offline or not', () async {
      final (container, _, repo) = await world();
      repo.failures['byCategory'] = const HomeFailure(0);
      final controller = container.read(insightsProvider.notifier);
      await controller.start(null);
      await settleAll();

      var state = container.read(insightsProvider);
      expect(state.failure!.offline, isTrue);
      expect(state.byCategory.failed, isTrue);

      // Reintentar: it asks again, and the figures come.
      await controller.refresh();
      await settleAll();
      state = container.read(insightsProvider);
      expect(state.failure, isNull);
      expect(state.byCategory.data, isNotNull);
    });

    test('a server error is not "offline"', () async {
      final (container, _, repo) = await world();
      repo.failures['trend'] = const HomeFailure(500);
      await container.read(insightsProvider.notifier).start(null);
      await settleAll();
      expect(container.read(insightsProvider).failure!.offline, isFalse);
      expect(container.read(insightsProvider).failure!.status, 500);
    });

    test('a refresh that fails keeps the last figures, and says they may be old', () async {
      final (container, _, repo) = await world();
      final controller = container.read(insightsProvider.notifier);
      await controller.start(null);
      await settleAll();
      repo.failures['byCategory'] = const HomeFailure(0);

      await controller.refresh();
      await settleAll();

      final state = container.read(insightsProvider);
      expect(state.failure, isNull, reason: 'there is something to show');
      expect(state.byCategory.data!.items.first.name, 'Hogar');
      expect(state.staleFailure!.offline, isTrue);
    });

    test(
      'another month that cannot load keeps the month before on screen, as what it is',
      () async {
        final (container, _, repo) = await world();
        final controller = container.read(insightsProvider.notifier);
        await controller.start(null);
        await settleAll();
        repo.failures['byCategory'] = const HomeFailure(0);

        await controller.showMonth('2026-09');
        await settleAll();

        final state = container.read(insightsProvider);
        expect(state.end, '2026-09');
        expect(state.byCategory.stale, isTrue, reason: 'October\'s figures are not September\'s');
        expect(state.byCategory.dataKey, isNot(state.byCategory.wanted));
        expect(state.staleFailure, isNotNull);
      },
    );

    test('a session the server refuses ends the session', () async {
      final session = _FakeSession();
      final (container, _, repo) = await world(session: session);
      repo.failures['byCategory'] = const HomeFailure(401);
      await container.read(insightsProvider.notifier).start(null);
      await settleAll();
      expect(session.signOuts, 1);
      expect(container.read(insightsProvider).failure!.unauthorized, isTrue);
    });
  });

  group('the screen that is left', () {
    test('an answer that lands after it was dropped changes nothing and throws nothing', () async {
      final (container, _, repo) = await world();
      final gate = Completer<void>();
      repo.gates['byCategory'] = [gate];
      final sub = container.listen(insightsProvider, (_, _) {});
      unawaited(container.read(insightsProvider.notifier).start(null));
      await settle();
      sub.close();
      container.invalidate(insightsProvider);
      gate.complete();
      await settleAll();
      expect(container.read(insightsProvider).byCategory.data, isNull);
    });
  });
}
