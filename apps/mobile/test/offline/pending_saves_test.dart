import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_repository.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/capture/capture_repository.dart';
import 'package:lukitas/home/home_cache.dart' show sessionOwnerOf;
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/offline/pending_saves.dart';

import '../add/fakes.dart';
import '../capture/fakes.dart';
import '../home/fakes.dart';

CreateTransaction _input(String name, int amount, {String date = '2026-10-22'}) =>
    CreateTransaction(
      (b) => b
        ..name = name
        ..amount = amount
        ..categoryId = 'cat-groceries'
        ..date = date
        ..status = CreateTransactionStatusEnum.paid
        ..source_ = CreateTransactionSource_Enum.app,
    );

class _Env {
  _Env(this.container, this.server, this.add, this.capture, this.store);

  final ProviderContainer container;
  final FakeHomeRepository server;
  final FakeAddRepository add;
  final FakeCaptureRepository capture;
  final FakePendingSavesStore store;

  PendingSaves get queue => container.read(pendingSavesProvider.notifier);
  PendingSavesState get state => container.read(pendingSavesProvider);
}

_Env _env({FakePendingSavesStore? store, String? token = 't1'}) {
  final server = FakeHomeRepository(items: []);
  final add = FakeAddRepository(server);
  final capture = FakeCaptureRepository(server);
  final kept = store ?? FakePendingSavesStore();
  final container = ProviderContainer(
    overrides: [
      addRepositoryProvider.overrideWithValue(add),
      captureRepositoryProvider.overrideWithValue(capture),
      pendingSavesStoreProvider.overrideWithValue(kept),
      pendingSavesTokenProvider.overrideWithValue(token),
      // Long enough that no test sees a retry it did not ask for.
      pendingRetryDelayProvider.overrideWithValue((_) => const Duration(hours: 1)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(pendingSavesProvider, (_, _) {});
  return _Env(container, server, add, capture, kept);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('a save waits on the phone, bound to the session, and goes up with its own key', () async {
    final env = _env();
    env.add.failures['create'] = const HomeFailure(0);
    await env.queue.add(PendingSave(key: 'k1', items: [_input('Pan', -300000)], batch: false));

    final doc = jsonDecode(env.store.value!) as Map<String, Object?>;
    expect(doc['v'], 1);
    expect(doc['owner'], sessionOwnerOf('t1'));
    expect((doc['saves']! as List).single, containsPair('key', 'k1'));

    // Still no network: it stays.
    await env.queue.send();
    expect(env.state.saves, hasLength(1));
    expect(env.state.notice, isNull);

    // The network is back.
    await env.queue.send();
    expect(env.add.keys, ['k1', 'k1']);
    expect(env.server.items.single.name, 'Pan');
    expect(env.state.saves, isEmpty);
    expect(env.state.notice!.sent, 1);
    await _settle();
    expect(env.store.value, isNull, reason: 'nothing left to keep');
  });

  test('saves go up oldest first; a batch goes up as one batch', () async {
    final env = _env();
    await env.queue.add(PendingSave(key: 'k1', items: [_input('Pan', -300000)], batch: false));
    await env.queue.add(
      PendingSave(
        key: 'k2',
        items: [_input('Almuerzo', -1500000), _input('Uber', -300000)],
        batch: true,
      ),
    );
    await env.queue.send();
    expect(env.add.calls.where((c) => c.startsWith('create')), ['create k1 Pan -300000']);
    expect(env.capture.calls, ['save k2 Almuerzo:1500000,Uber:300000']);
    expect(env.server.items, hasLength(3));
    expect(env.state.notice!.sent, 3);
  });

  test('a save the server refuses is dropped and named; the rest still go up', () async {
    final env = _env();
    env.add.failures['create'] = const HomeFailure(422, code: 'category_not_found');
    await env.queue.add(PendingSave(key: 'k1', items: [_input('Pan', -300000)], batch: false));
    await env.queue.add(PendingSave(key: 'k2', items: [_input('Leche', -500000)], batch: false));
    final notices = <PendingNotice>[];
    env.container.listen(pendingSavesProvider.select((s) => s.notice), (_, next) {
      if (next != null) notices.add(next);
    });
    await env.queue.send();
    expect(env.state.saves, isEmpty);
    expect(env.server.items.map((t) => t.name), ['Leche']);
    expect(notices.first.refused!.name, 'Pan');
    expect(notices.last.sent, 1);
  });

  test('a refused save alone says which it was', () async {
    final env = _env();
    env.add.failures['create'] = const HomeFailure(422, code: 'category_not_found');
    await env.queue.add(PendingSave(key: 'k1', items: [_input('Pan', -300000)], batch: false));
    await env.queue.send();
    expect(env.state.saves, isEmpty);
    expect(env.state.notice!.refused!.name, 'Pan');
  });

  test('a start finds what was waiting and sends it', () async {
    final store = FakePendingSavesStore()
      ..value = jsonEncode({
        'v': 1,
        'owner': sessionOwnerOf('t1'),
        'saves': [
          PendingSave(key: 'k1', items: [_input('Pan', -300000)], batch: false).toJson(),
        ],
      });
    final env = _env(store: store);
    await _settle();
    await env.queue.send();
    expect(env.add.keys, ['k1']);
    expect(env.server.items.single.name, 'Pan');
    expect(env.state.saves, isEmpty);
  });

  test('another session reads nothing of what this one left', () async {
    final store = FakePendingSavesStore()
      ..value = jsonEncode({
        'v': 1,
        'owner': sessionOwnerOf('someone-else'),
        'saves': [
          PendingSave(key: 'k1', items: [_input('Pan', -300000)], batch: false).toJson(),
        ],
      });
    final env = _env(store: store);
    await _settle();
    await env.queue.send();
    expect(env.add.keys, isEmpty);
    expect(env.state.saves, isEmpty);
  });

  test('the rows stand for the movements, marked as not uploaded', () {
    const save = PendingSave(key: 'k1', items: [], batch: false);
    expect(
      isUnsent(
        Transaction(
          (b) => b
            ..id = save.rowId(0)
            ..name = ''
            ..amount = 0
            ..currency = 'COP'
            ..date = '2026-10-22'
            ..status = TransactionStatusEnum.paid
            ..categoryId = 'c'
            ..source_ = TransactionSource_Enum.app
            ..createdAt = ''
            ..updatedAt = '',
        ),
      ),
      isTrue,
    );
    final rows = PendingSave(key: 'k2', items: [_input('Pan', -300000)], batch: false).rows('COP');
    expect(rows.single.id, 'unsent-k2-0');
    expect(rows.single.amount, -300000);
    expect(rows.single.status, TransactionStatusEnum.paid);
  });
}
