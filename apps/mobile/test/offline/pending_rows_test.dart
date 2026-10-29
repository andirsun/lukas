import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_cache.dart' show sessionOwnerOf;
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/offline/pending_saves.dart';

import '../add/fakes.dart';
import '../home/fakes.dart';
import '../home/fixtures.dart';
import '../home/home_harness.dart';

/// A queue left on the phone by an earlier run: one movement, "Pan", saved with no network.
FakePendingSavesStore _leftOver() => FakePendingSavesStore()
  ..value = jsonEncode({
    'v': 1,
    'owner': sessionOwnerOf('t1'),
    'saves': [
      PendingSave(
        key: 'k1',
        batch: false,
        items: [
          CreateTransaction(
            (b) => b
              ..name = 'Pan'
              ..amount = -300000
              ..categoryId = 'cat-groceries'
              ..date = '2026-10-22'
              ..status = CreateTransactionStatusEnum.paid
              ..source_ = CreateTransactionSource_Enum.app,
          ),
        ],
      ).toJson(),
    ],
  });

FakeHomeRepository _server() => FakeHomeRepository(
  categoryList: [category('cat-groceries', 'Supermercado', icon: '🛒')],
  items: [tx('coffee', '2026-10-21', -450000, name: 'Café', categoryId: 'cat-groceries')],
);

/// Retries late enough that settling the first frames never reaches one.
final _retryIn30s = pendingRetryDelayProvider.overrideWithValue((_) => const Duration(seconds: 30));

void main() {
  testWidgets(
    'a save left from before shows with the cloud, and goes up when the network answers',
    (tester) async {
      final server = _server();
      // The first try finds no network; the next one hangs until the test lets it through.
      final add = FakeAddRepository(server)
        ..failures['create'] = const HomeFailure(0)
        ..hold = Completer<void>();
      await pumpHome(
        tester,
        server,
        addRepo: add,
        pendingStore: _leftOver(),
        overrides: [_retryIn30s],
      );

      // Still no answer: the row is there, marked as not uploaded, and nothing else changed.
      expect(find.text('Pan'), findsOneWidget);
      expect(find.byKey(const Key('row.unsent')), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Pan')).dy,
        lessThan(tester.getTopLeft(find.text('Café')).dy),
        reason: 'the newest first',
      );

      // The network answers: the retry gets through, with the same key.
      add.hold!.complete();
      await tester.pumpAndSettle();
      expect(add.keys, ['k1', 'k1']);
      expect(server.items.where((t) => t.name == 'Pan'), hasLength(1));
      expect(find.text('Pan'), findsOneWidget);
      expect(find.byKey(const Key('row.unsent')), findsNothing);
      expect(find.text('Ya subimos el movimiento que anotaste sin conexión.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('a save the server refuses is dropped, and home names it', (tester) async {
    final server = _server();
    final add = FakeAddRepository(server)
      ..failures['create'] = const HomeFailure(422, code: 'category_not_found');
    await pumpHome(tester, server, addRepo: add, pendingStore: _leftOver());

    expect(find.text('Pan'), findsNothing);
    expect(find.byKey(const Key('row.unsent')), findsNothing);
    expect(find.text('No pudimos guardar «Pan». Anótalo otra vez.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();
  });

  testWidgets('a row not uploaded is read out as such', (tester) async {
    final server = _server();
    final add = FakeAddRepository(server)
      ..failures['create'] = const HomeFailure(0)
      ..hold = Completer<void>();
    final handle = tester.ensureSemantics();
    await pumpHome(
      tester,
      server,
      addRepo: add,
      pendingStore: _leftOver(),
      overrides: [_retryIn30s],
    );
    expect(find.bySemanticsLabel(RegExp('^Pan .* Sin subir\$')), findsOneWidget);
    handle.dispose();
    // Lets the retry find the network.
    add.hold!.complete();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();
  });
}
