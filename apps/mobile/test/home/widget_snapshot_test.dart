import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/widget_snapshot.dart';

import 'fakes.dart';
import 'fixtures.dart';

Map<String, Object?> written(FakeWidgetStore store) =>
    jsonDecode(store.saved[widgetSnapshotKey]!) as Map<String, Object?>;

void main() {
  final now = DateTime.utc(2026, 10, 22, 15, 30);

  test('with budgets it keeps what is left, formatted, with the month and its progress', () async {
    final store = FakeWidgetStore();
    await writeWidgetSnapshot(
      summary(budgetTotal: 200000000, spent: 50000000),
      currency: 'COP',
      locale: 'es',
      store: store,
      now: now,
    );
    expect(written(store), {
      'v': 1,
      'kind': 'remaining',
      'amount': r'$1.500.000',
      'currency': 'COP',
      'month': '2026-10',
      'progress': 0.25,
      'mood': 'happy',
      'updatedAt': '2026-10-22T15:30:00.000Z',
    });
  });

  test(
    'over the budgets it keeps the overspend, and a category near its limit is worried',
    () async {
      final store = FakeWidgetStore();
      await writeWidgetSnapshot(
        summary(
          budgetTotal: 100000,
          spent: 150000,
          categories: [categorySummary('c', budget: 100000, spent: 150000, state: 'over')],
        ),
        currency: 'EUR',
        locale: 'en',
        store: store,
        now: now,
      );
      expect(written(store)['kind'], 'over');
      expect(written(store)['amount'], '€500.00');
      expect(written(store)['progress'], 1.0);
      expect(written(store)['mood'], 'worried');
    },
  );

  test('without budgets it keeps what was spent and no progress', () async {
    final store = FakeWidgetStore();
    await writeWidgetSnapshot(
      summary(spent: 4200000),
      currency: 'COP',
      locale: 'es',
      store: store,
      now: now,
    );
    expect(written(store)['kind'], 'spent');
    expect(written(store)['amount'], r'$42.000');
    expect(written(store)['progress'], isNull);
  });

  test('is one JSON document under one key, nothing else', () async {
    final store = FakeWidgetStore();
    await writeWidgetSnapshot(summary(), currency: 'COP', locale: 'es', store: store, now: now);
    expect(store.saved.keys, ['lukitas.widget.snapshot']);
  });

  test('a store that cannot be reached never breaks home', () async {
    final store = FakeWidgetStore()..failure = MissingPluginException();
    await writeWidgetSnapshot(summary(), currency: 'COP', locale: 'es', store: store, now: now);
    store.failure = PlatformException(code: 'x');
    await writeWidgetSnapshot(summary(), currency: 'COP', locale: 'es', store: store, now: now);
  });

  test(
    'clearing forgets it, and a store that cannot be reached never breaks that either',
    () async {
      final store = FakeWidgetStore();
      await writeWidgetSnapshot(summary(), currency: 'COP', locale: 'es', store: store, now: now);
      await clearWidgetSnapshot(store: store);
      expect(store.saved, isEmpty);

      store.failure = MissingPluginException();
      await clearWidgetSnapshot(store: store);
      store.failure = PlatformException(code: 'x');
      await clearWidgetSnapshot(store: store);
    },
  );
}
