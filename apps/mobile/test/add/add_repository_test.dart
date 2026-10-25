import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/add/add_repository.dart';
import 'package:lukitas/api/client.dart';
import 'package:lukitas/api/gen/lukitas_api.dart';
import 'package:lukitas/home/home_repository.dart';

const _transaction = {
  'id': 't1',
  'name': 'Almuerzo',
  'amount': -2800000,
  'currency': 'COP',
  'date': '2026-10-22',
  'status': 'paid',
  'note': null,
  'categoryId': 'c1',
  'recurrenceId': null,
  'importId': null,
  'source': 'app',
  'createdAt': '2026-10-22T10:00:00.000Z',
  'updatedAt': '2026-10-22T10:00:00.000Z',
};

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int? status;
  Map<String, Object?>? problem;
  bool noAnswer = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (noAnswer) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    }
    if (status != null) {
      return ResponseBody.fromString(
        jsonEncode(problem ?? {}),
        status!,
        headers: {
          Headers.contentTypeHeader: ['application/problem+json'],
        },
      );
    }
    final Object body = options.path == '/v1/transactions/suggestions'
        ? {
            'items': [
              {'name': 'Almuerzo', 'categoryId': 'c1'},
              {'name': 'Café', 'categoryId': 'c2'},
            ],
          }
        : _transaction;
    return ResponseBody.fromString(
      jsonEncode(body),
      options.method == 'POST' ? 201 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

CreateTransaction newTransaction() => CreateTransaction(
  (b) => b
    ..name = 'Almuerzo'
    ..amount = -2800000
    ..categoryId = 'c1'
    ..date = '2026-10-22'
    ..status = CreateTransactionStatusEnum.paid
    ..source_ = CreateTransactionSource_Enum.app,
);

void main() {
  late _Adapter adapter;
  late ApiAddRepository repo;
  setUp(() {
    final client = ApiClient.forServer(Uri.parse('https://example.test'), token: 'tok');
    adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
    repo = ApiAddRepository(client.api.getDefaultApi(), client.dio);
  });

  test('creating sends the Idempotency-Key and the movement as the app', () async {
    final created = await repo.create(newTransaction(), idempotencyKey: 'key-1');
    expect(created.id, 't1');
    final request = adapter.requests.single;
    expect('${request.method} ${request.path}', 'POST /v1/transactions');
    expect(request.headers['Idempotency-Key'], 'key-1');
    expect(jsonDecode(jsonEncode(request.data)), {
      'name': 'Almuerzo',
      'amount': -2800000,
      'categoryId': 'c1',
      'date': '2026-10-22',
      'status': 'paid',
      'source': 'app',
    });
  });

  test('editing sends only the fields that changed', () async {
    final saved = await repo.update(
      't1',
      const TransactionPatch(name: 'Cena', amount: -3000000, pending: true),
    );
    expect(saved.id, 't1');
    final request = adapter.requests.single;
    expect('${request.method} ${request.path}', 'PATCH /v1/transactions/t1');
    expect(jsonDecode(jsonEncode(request.data)), {
      'name': 'Cena',
      'amount': -3000000,
      'status': 'pending',
    });
  });

  test('editing can clear the note: the null is sent', () async {
    await repo.update('t1', const TransactionPatch(setNote: true, note: null));
    expect(jsonDecode(jsonEncode(adapter.requests.single.data)), {'note': null});
    await repo.update('t1', const TransactionPatch(setNote: true, note: 'con Ana'));
    expect(jsonDecode(jsonEncode(adapter.requests.last.data)), {'note': 'con Ana'});
  });

  test('a patch with nothing in it is empty', () {
    expect(const TransactionPatch().isEmpty, isTrue);
    expect(const TransactionPatch(setNote: true).isEmpty, isFalse);
    expect(const TransactionPatch(date: '2026-10-01').isEmpty, isFalse);
  });

  test('suggestions ask for the typed text, at most a few, most used first', () async {
    final found = await repo.suggestions('al');
    expect(found.map((s) => s.name), ['Almuerzo', 'Café']);
    expect(adapter.requests.single.queryParameters, {'q': 'al', 'limit': 8});
    await repo.suggestions('');
    expect(adapter.requests.last.queryParameters, {'limit': 8});
  });

  test('a refusal carries its status and its code; no answer at all is status 0', () async {
    adapter
      ..status = 422
      ..problem = {'status': 422, 'code': 'category_not_found'};
    await expectLater(
      repo.create(newTransaction(), idempotencyKey: 'k'),
      throwsA(
        isA<HomeFailure>()
            .having((f) => f.status, 'status', 422)
            .having((f) => f.code, 'code', 'category_not_found'),
      ),
    );
    adapter.status = 500;
    adapter.problem = null;
    await expectLater(
      repo.update('t1', const TransactionPatch(name: 'x')),
      throwsA(isA<HomeFailure>().having((f) => f.status, 'status', 500)),
    );
    adapter
      ..status = null
      ..noAnswer = true;
    await expectLater(
      repo.suggestions('a'),
      throwsA(isA<HomeFailure>().having((f) => f.offline, 'offline', true)),
    );
  });
}
