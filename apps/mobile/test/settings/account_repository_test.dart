// What the export and the account's deletion ask of the server: apps/web/app/features/settings/
// use-export.ts (`GET /v1/me/export`) and DeleteAccount.tsx (`DELETE /v1/me`).
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/client.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/settings/account_repository.dart';

/// Answers the export with a file and a `content-disposition`, remembers every request.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int? status;
  bool noAnswer = false;
  String? disposition = 'attachment; filename="lukas-export-2026-10-21.json"';

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
        jsonEncode({'code': 'internal_error'}),
        status!,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.method == 'DELETE') return ResponseBody.fromString('', 204);
    final csv = options.queryParameters['format'] == 'csv';
    return ResponseBody.fromBytes(
      utf8.encode(csv ? 'date,name,amount\n' : '{"user":{"id":"u1"}}'),
      200,
      headers: {
        Headers.contentTypeHeader: [csv ? 'text/csv; charset=utf-8' : 'application/json'],
        if (disposition != null) 'content-disposition': [disposition!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late ApiAccountRepository repo;
  setUp(() {
    final client = ApiClient.forServer(Uri.parse('https://example.test'), token: 'tok');
    adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
    repo = ApiAccountRepository(client.dio);
  });

  test(
    'exports as JSON: the format asked for, the bytes as they came, the server\'s name',
    () async {
      final file = await repo.export(ExportFormat.json);
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/v1/me/export');
      expect(adapter.requests.single.queryParameters, {'format': 'json'});
      expect(file.name, 'lukas-export-2026-10-21.json');
      expect(file.mime, 'application/json');
      expect(utf8.decode(file.bytes), '{"user":{"id":"u1"}}');
    },
  );

  test('exports as CSV', () async {
    adapter.disposition = 'attachment; filename="lukas-export-2026-10-21.csv"';
    final file = await repo.export(ExportFormat.csv);
    expect(adapter.requests.single.queryParameters, {'format': 'csv'});
    expect(file.name, 'lukas-export-2026-10-21.csv');
    expect(file.mime, 'text/csv');
    expect(utf8.decode(file.bytes), startsWith('date,name,amount'));
  });

  test('a missing name, or one with a path in it, is lukas-export.<format>', () async {
    adapter.disposition = null;
    expect((await repo.export(ExportFormat.json)).name, 'lukas-export.json');
    adapter.disposition = 'attachment; filename="../../x.csv"';
    expect((await repo.export(ExportFormat.csv)).name, 'lukas-export.csv');
  });

  test('a failed export is a HomeFailure with the status, and no answer is offline', () async {
    adapter.status = 500;
    await expectLater(
      repo.export(ExportFormat.json),
      throwsA(isA<HomeFailure>().having((f) => f.status, 'status', 500)),
    );
    adapter.status = null;
    adapter.noAnswer = true;
    await expectLater(
      repo.export(ExportFormat.csv),
      throwsA(isA<HomeFailure>().having((f) => f.offline, 'offline', isTrue)),
    );
  });

  test('deletes the account with DELETE /v1/me', () async {
    await repo.deleteAccount();
    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/v1/me');
  });

  test('a refused delete is a HomeFailure', () async {
    adapter.status = 503;
    await expectLater(
      repo.deleteAccount(),
      throwsA(isA<HomeFailure>().having((f) => f.status, 'status', 503)),
    );
    adapter.status = 401;
    await expectLater(
      repo.deleteAccount(),
      throwsA(isA<HomeFailure>().having((f) => f.unauthorized, 'unauthorized', isTrue)),
    );
  });
}
