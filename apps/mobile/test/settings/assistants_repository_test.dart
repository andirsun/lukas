// What "Conecta tu asistente" asks of the server (spec §6.2): `GET /v1/me/assistants` and
// `DELETE /v1/me/assistants/{clientId}`, and the MCP's address next to the server's.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/client.dart';
import 'package:lukitas/home/home_repository.dart';
import 'package:lukitas/settings/assistants_repository.dart';

const _claude = 'https://claude.ai/oauth/mcp-oauth-client-metadata';

/// Answers the list with two assistants and a delete with 204, remembers every request.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int? status;
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
    final json = {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    };
    if (status != null) {
      return ResponseBody.fromString(
        jsonEncode({'code': status == 404 ? 'not_found' : 'internal_error'}),
        status!,
        headers: json,
      );
    }
    if (options.method == 'DELETE') return ResponseBody.fromString('', 204);
    return ResponseBody.fromString(
      jsonEncode({
        'items': [
          {
            'clientId': _claude,
            'name': 'Claude',
            'icon': 'https://claude.ai/favicon.ico',
            'uri': 'https://claude.ai',
            'domain': 'claude.ai',
            'scopes': ['finance:read', 'finance:write'],
            'connectedAt': '2026-10-30T14:00:00.000Z',
            'lastUsedAt': '2026-10-31T09:15:00.000Z',
          },
          {
            'clientId': 'abc123',
            'name': 'abc123',
            'icon': null,
            'uri': null,
            'domain': null,
            'scopes': ['finance:read'],
            'connectedAt': '2026-10-29T08:00:00.000Z',
            'lastUsedAt': null,
          },
        ],
      }),
      200,
      headers: json,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late ApiAssistantsRepository repo;
  setUp(() {
    final client = ApiClient.forServer(Uri.parse('https://example.test'), token: 'tok');
    adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
    repo = ApiAssistantsRepository(client.api.getDefaultApi());
  });

  test('lists them from GET /v1/me/assistants, with their dates read', () async {
    final items = await repo.list();
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.path, '/v1/me/assistants');
    expect(items, hasLength(2));
    final claude = items.first;
    expect(claude.clientId, _claude);
    expect(claude.name, 'Claude');
    expect(claude.domain, 'claude.ai');
    expect(claude.connectedAt, DateTime.utc(2026, 10, 30, 14));
    expect(claude.lastUsedAt, DateTime.utc(2026, 10, 31, 9, 15));
    final other = items.last;
    expect(other.domain, isNull);
    expect(other.lastUsedAt, isNull, reason: 'never used');
  });

  test('a failed list is a HomeFailure with the status, and no answer is offline', () async {
    adapter.status = 500;
    await expectLater(
      repo.list(),
      throwsA(isA<HomeFailure>().having((f) => f.status, 'status', 500)),
    );
    adapter.status = null;
    adapter.noAnswer = true;
    await expectLater(
      repo.list(),
      throwsA(isA<HomeFailure>().having((f) => f.offline, 'offline', isTrue)),
    );
  });

  test('revokes with DELETE /v1/me/assistants/{clientId}, a URL id as one segment', () async {
    await repo.revoke(_claude);
    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.uri.pathSegments, ['api', 'v1', 'me', 'assistants', _claude]);
  });

  test('one the server no longer knows (404) counts as revoked', () async {
    adapter.status = 404;
    await repo.revoke('abc123');
    expect(adapter.requests.single.method, 'DELETE');
  });

  test('a refused revoke is a HomeFailure, and no answer is offline', () async {
    adapter.status = 401;
    await expectLater(
      repo.revoke('abc123'),
      throwsA(isA<HomeFailure>().having((f) => f.unauthorized, 'unauthorized', isTrue)),
    );
    adapter.status = null;
    adapter.noAnswer = true;
    await expectLater(
      repo.revoke('abc123'),
      throwsA(isA<HomeFailure>().having((f) => f.offline, 'offline', isTrue)),
    );
  });

  group('the MCP\'s address', () {
    test('is the server\'s origin with /mcp', () {
      expect(
        mcpUrl(Uri.parse('https://app-lukas.andersonlaverde.com')).toString(),
        'https://app-lukas.andersonlaverde.com/mcp',
      );
      expect(
        mcpUrl(Uri.parse('https://app-lukas.andersonlaverde.com/')).toString(),
        'https://app-lukas.andersonlaverde.com/mcp',
      );
    });

    test('keeps a port and a sub-path, and drops a query or fragment', () {
      expect(
        mcpUrl(Uri.parse('http://10.0.2.2:8080/lukas/?x=1#y')).toString(),
        'http://10.0.2.2:8080/lukas/mcp',
      );
    });
  });
}
