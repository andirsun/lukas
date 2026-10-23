import 'package:built_value/serializer.dart' show Serializer;
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/feedback/stored_flag.dart';
import 'package:lukitas/home/home_cache.dart';
import 'package:lukitas/home/home_controller.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/home/home_screen.dart';
import 'package:lukitas/home/lukitas_face.dart';

import '../settings/fakes.dart' show FakeFlagStore;
import 'parity.dart';

/// What the parity pairs of home, the categories and the budget sheet share: the story's API as a
/// [HomeRepository], and the providers a screen needs under the golden.

Object? fixtureJson(ParityFixture fixture, String path) => fixture.get(path).body;

T readBuilt<T>(Serializer<T> serializer, Object? json) =>
    standardSerializers.deserializeWith(serializer, json) as T;

/// The story's API as a [HomeRepository]: it answers what the fixture holds. [pending] is a
/// movement the story's `play` function paid (the fixture was saved afterwards): it starts pending
/// here, so the app does what the story did.
class FixtureHomeRepository implements HomeRepository {
  FixtureHomeRepository(this.fixture, {this.pending}) {
    for (final item
        in (fixtureJson(fixture, '/v1/transactions?limit=50&month=2026-10')! as Map)['items']
            as List) {
      final tx = readBuilt(Transaction.serializer, item);
      items.add(
        tx.name == pending ? tx.rebuild((b) => b.status = TransactionStatusEnum.pending) : tx,
      );
    }
  }

  final ParityFixture fixture;
  final String? pending;
  final items = <Transaction>[];

  @override
  Future<HomeProfile> profile() async {
    final me = fixtureJson(fixture, '/v1/me')! as Map;
    return HomeProfile(
      id: me['id']! as String,
      currency: me['currency']! as String,
      timezone: me['timezone']! as String,
    );
  }

  @override
  Future<Summary> summary(String month) async =>
      readBuilt(Summary.serializer, fixtureJson(fixture, '/v1/summary?month=$month'));

  @override
  Future<List<Category>> categories() async => [
    for (final c in fixtureJson(fixture, '/v1/categories?includeArchived=true')! as List)
      readBuilt(Category.serializer, c),
  ];

  @override
  Future<TransactionsPage> transactions(String month, {String? cursor}) async =>
      TransactionsPage(List.of(items), null);

  @override
  Future<Transaction> markPaid(String id) async {
    final index = items.indexWhere((t) => t.id == id);
    return items[index] = items[index].rebuild((b) => b.status = TransactionStatusEnum.paid);
  }

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<Transaction> restore(String id) async => throw UnimplementedError();
}

class NoCacheStore implements HomeCacheStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String json) async {}

  @override
  Future<void> clear() async {}
}

List<Override> parityHomeOverrides(HomeRepository repo) => [
  homeRepositoryProvider.overrideWithValue(repo),
  // Signed out as far as the cache goes: nothing is read or kept.
  homeCacheProvider.overrideWithValue(HomeCache(NoCacheStore(), token: null)),
  widgetSnapshotWriterProvider.overrideWithValue(
    (summary, {required currency, required locale, required timezone}) async {},
  ),
  // The web's shots pin `Math.random` to 0: Lukitas says the first phrasing of every line.
  lukasVariantProvider.overrideWithValue(() => 1),
  flagStoreProvider.overrideWith((ref, key) => FakeFlagStore()),
];

/// Lukitas' sprite sheets decode in real time, which `pumpAndSettle` does not wait for: decode them
/// first, so the picture is taken with him in it.
Future<void> precacheLukitas(WidgetTester t) async {
  await t.runAsync(() async {
    final context = t.element(find.byType(Scaffold).first);
    for (final mood in LukitasMood.values) {
      await precacheImage(AssetImage(mood.sheet), context);
    }
  });
  await t.pumpAndSettle();
}
