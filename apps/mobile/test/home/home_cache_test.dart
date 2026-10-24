import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_cache.dart';

import 'fakes.dart';
import 'fixtures.dart';

CachedHome sample({String userId = 'user-1'}) => CachedHome(
  userId: userId,
  currency: 'COP',
  timezone: 'America/Bogota',
  month: '2026-10',
  summary: summary(budgetTotal: 1000, spent: 400),
  categories: [category('cat-groceries', 'Supermercado')],
  items: [
    tx('a', '2026-10-22', -1000, name: 'Café'),
    tx('b', '2026-10-21', -500, status: 'pending'),
  ],
);

void main() {
  test('what was written comes back whole, for the same session', () async {
    final store = FakeCacheStore();
    await HomeCache(store, token: 't1').write(sample());

    final back = (await HomeCache(store, token: 't1').read())!;
    expect(back.userId, 'user-1');
    expect((back.currency, back.timezone, back.month), ('COP', 'America/Bogota', '2026-10'));
    expect(back.summary.spent, 400);
    expect(back.categories.single.name, 'Supermercado');
    expect(back.items.map((t) => (t.id, t.name, t.amount, t.status.name)), [
      ('a', 'Café', -1000, 'paid'),
      ('b', 'b', -500, 'pending'),
    ]);
  });

  test('the session token is never stored, only its SHA-256', () async {
    final store = FakeCacheStore();
    await HomeCache(store, token: 'secret-bearer-token').write(sample());

    expect(store.value, isNot(contains('secret-bearer-token')));
    expect(store.value, contains(sha256.convert(utf8.encode('secret-bearer-token')).toString()));
    expect(await HomeCache(store, token: 'secret-bearer-token').read(), isNotNull);
    expect(await HomeCache(store, token: 'other-bearer-token').read(), isNull);
  });

  test('nothing stored reads as nothing', () async {
    expect(await HomeCache(FakeCacheStore(), token: 't1').read(), isNull);
  });

  test('another session never reads it: not another user, not a signed-out phone', () async {
    final store = FakeCacheStore();
    await HomeCache(store, token: 't1').write(sample());

    expect(await HomeCache(store, token: 't2').read(), isNull);
    expect(await HomeCache(store, token: null).read(), isNull);
  });

  test('a signed-out phone writes nothing', () async {
    final store = FakeCacheStore();
    await HomeCache(store, token: null).write(sample());
    expect(store.value, isNull);
  });

  test('an unknown version, broken JSON or a store that fails read as nothing', () async {
    final store = FakeCacheStore();
    await HomeCache(store, token: 't1').write(sample());
    final doc = jsonDecode(store.value!) as Map<String, Object?>;

    store.value = jsonEncode({...doc, 'v': 99});
    expect(await HomeCache(store, token: 't1').read(), isNull);
    store.value = '{not json';
    expect(await HomeCache(store, token: 't1').read(), isNull);
    store.value = jsonEncode({'v': 1, 'owner': 'x'});
    expect(await HomeCache(store, token: 't1').read(), isNull);
    store.failure = Exception('keystore gone');
    expect(await HomeCache(store, token: 't1').read(), isNull);
  });

  test('a write that fails never throws', () async {
    final store = FakeCacheStore()..failure = Exception('disk full');
    await HomeCache(store, token: 't1').write(sample());
  });
}
