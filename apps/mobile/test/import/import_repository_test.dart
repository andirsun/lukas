import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/client.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/import/import_repository.dart';

import 'fakes.dart';

/// What the import sends the API, as the API reads it (apps/api routes/imports.ts).
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <String>[];
  int status = 200;
  Object? error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      bodies.add(utf8.decode(bytes, allowMalformed: true));
    } else {
      bodies.add('');
    }
    final Object? body = options.method == 'DELETE'
        ? null
        : error ?? {'id': 'preview-1', 'status': 'preview', 'stats': sampleStats()};
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      options.method == 'POST' && options.path == '/v1/imports' && error == null ? 201 : status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late ApiImportRepository repo;

  setUp(() {
    final client = ApiClient.forServer(Uri.parse('https://example.test'), token: 'tok');
    adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
    repo = ApiImportRepository(client.api.getDefaultApi());
  });

  test('the file goes up as multipart with source=budge, whole, with its name', () async {
    final csv = budgeCsv(rows: 5);
    final preview = await repo.upload('budge.csv', csv);
    expect(preview.id, 'preview-1');
    expect(preview.stats.transactions, 22);
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v1/imports');
    expect(request.contentType, startsWith('multipart/form-data'));
    final body = adapter.bodies.single;
    expect(body, contains('name="source"'));
    expect(body, contains('budge'));
    expect(body, contains('name="file"; filename="budge.csv"'));
    expect(body, contains(utf8.decode(csv)));
  });

  test('confirming sends JSON the API can read, whether or not the currency is adopted', () async {
    await repo.confirm('preview-1');
    var request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, '/v1/imports/preview-1/confirm');
    // An empty body under a JSON content type is a 400 "Malformed JSON" at the API: never that.
    expect(jsonDecode(adapter.bodies.last), <String, Object?>{});

    await repo.confirm('preview-1', adoptFileCurrency: true);
    request = adapter.requests.last;
    expect(jsonDecode(adapter.bodies.last), {'adoptFileCurrency': true});
  });

  test('dropping a preview is a DELETE', () async {
    adapter.status = 204;
    await repo.discard('preview-1');
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/v1/imports/preview-1');
  });

  test('a refusal carries the API\'s code', () async {
    adapter
      ..status = 422
      ..error = {'code': 'import_unrecognized_format', 'status': 422};
    await expectLater(
      repo.upload('x.csv', Uint8List(3)),
      throwsA(
        isA<HomeFailure>()
            .having((f) => f.status, 'status', 422)
            .having((f) => f.code, 'code', 'import_unrecognized_format'),
      ),
    );
  });
}
