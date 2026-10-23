import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/client.dart';
import 'package:lukitas/capture/capture_repository.dart';
import 'package:lukitas/capture/parser/parse.dart';
import 'package:lukitas/home/home_repository.dart';

Map<String, Object?> _row(String id, Map<String, dynamic> item) => {
  'id': id,
  'name': item['name'],
  'amount': item['amount'],
  'currency': 'COP',
  'date': item['date'],
  'status': 'paid',
  'note': null,
  'categoryId': item['categoryId'],
  'recurrenceId': null,
  'importId': null,
  'source': 'app',
  'createdAt': '2026-10-22T10:00:00.000Z',
  'updatedAt': '2026-10-22T10:00:00.000Z',
};

class _Adapter implements HttpClientAdapter {
  final requests = <({RequestOptions options, Object? body})>[];
  var noAnswer = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : (await requestStream.toList()).expand((c) => c).toList();
    final body = bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes));
    requests.add((options: options, body: body));
    if (noAnswer) throw DioException.connectionError(requestOptions: options, reason: 'offline');
    if (options.path == '/v1/transactions/batch-delete') return ResponseBody.fromString('', 204);
    final items = ((body as Map)['items'] as List).cast<Map<String, dynamic>>();
    return ResponseBody.fromString(
      jsonEncode({
        'items': [for (var i = 0; i < items.length; i++) _row('t$i', items[i])],
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late CaptureRepository repo;

  setUp(() {
    adapter = _Adapter();
    final client = ApiClient.forServer(Uri.parse('https://example.test'));
    client.dio.httpClientAdapter = adapter;
    repo = ApiCaptureRepository(client.api.getDefaultApi());
  });

  const drafts = [
    Draft(
      amount: 1500000,
      kind: Kind.expense,
      name: 'Almuerzo',
      categoryId: 'c1',
      date: '2026-10-22',
    ),
    Draft(amount: 300000, kind: Kind.income, name: 'Uber', categoryId: 'c2', date: '2026-10-21'),
  ];

  test(
    'saveBatch sends one batch with the key, expenses negative, and gives the rows back',
    () async {
      final saved = await repo.saveBatch(drafts, idempotencyKey: 'key-1');
      final request = adapter.requests.single;
      expect(request.options.method, 'POST');
      expect(request.options.path, '/v1/transactions/batch');
      expect(request.options.headers['Idempotency-Key'], 'key-1');
      final items = ((request.body as Map)['items'] as List).cast<Map<String, dynamic>>();
      expect(items, [
        {
          'name': 'Almuerzo',
          'amount': -1500000,
          'categoryId': 'c1',
          'date': '2026-10-22',
          'status': 'paid',
          'source': 'app',
        },
        {
          'name': 'Uber',
          'amount': 300000,
          'categoryId': 'c2',
          'date': '2026-10-21',
          'status': 'paid',
          'source': 'app',
        },
      ]);
      expect(saved.map((t) => t.id), ['t0', 't1']);
    },
  );

  test('a draft without a category is never sent', () async {
    await expectLater(
      repo.saveBatch(const [
        Draft(amount: 100, kind: Kind.expense, name: 'x', categoryId: null, date: '2026-10-22'),
      ], idempotencyKey: 'k'),
      throwsArgumentError,
    );
    expect(adapter.requests, isEmpty);
  });

  test('undoBatch soft-deletes the ids together', () async {
    await repo.undoBatch(['t0', 't1']);
    final request = adapter.requests.single;
    expect(request.options.path, '/v1/transactions/batch-delete');
    expect(request.body, {
      'ids': ['t0', 't1'],
    });
  });

  test('no answer is an offline HomeFailure', () async {
    adapter.noAnswer = true;
    await expectLater(
      repo.saveBatch(drafts, idempotencyKey: 'k'),
      throwsA(isA<HomeFailure>().having((f) => f.offline, 'offline', isTrue)),
    );
    await expectLater(
      repo.undoBatch(['t0']),
      throwsA(isA<HomeFailure>().having((f) => f.offline, 'offline', isTrue)),
    );
  });
}
