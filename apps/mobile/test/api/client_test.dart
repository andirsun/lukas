import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/client.dart';

/// Answers every request with `{}` and remembers the last one.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(<String, Object>{}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('forServer sends API calls to <server>/api', () {
    expect(
      ApiClient.forServer(Uri.parse('https://app-lukas.andersonlaverde.com')).baseUrl,
      'https://app-lukas.andersonlaverde.com/api',
    );
    expect(
      ApiClient.forServer(Uri.parse('https://example.test/lukas/')).baseUrl,
      'https://example.test/lukas/api',
    );
    expect(
      ApiClient.forServer(Uri.parse('http://10.0.2.2:3000')).baseUrl,
      'http://10.0.2.2:3000/api',
    );
  });

  test('a request goes to <server>/api/<path> with the bearer token', () async {
    final client = ApiClient.forServer(Uri.parse('https://example.test/lukas/'), token: 'abc');
    final adapter = _RecordingAdapter();
    client.dio.httpClientAdapter = adapter;

    await client.dio.get<Object>('/v1/me');

    expect(adapter.last!.uri.toString(), 'https://example.test/lukas/api/v1/me');
    expect(adapter.last!.headers['Authorization'], 'Bearer abc');
  });

  test('signed out, a request carries no Authorization header', () async {
    final client = ApiClient.forServer(Uri.parse('https://example.test'));
    final adapter = _RecordingAdapter();
    client.dio.httpClientAdapter = adapter;

    await client.dio.get<Object>('/v1/me');

    expect(adapter.last!.uri.toString(), 'https://example.test/api/v1/me');
    expect(adapter.last!.headers.containsKey('Authorization'), isFalse);
  });

  group('the client address (the emulator suite, debug builds only)', () {
    Future<Map<String, dynamic>> headersOf({
      required bool development,
      String ip = '198.18.4.7',
    }) async {
      final client = ApiClient.forServer(
        Uri.parse('https://example.test'),
        clientIp: ip,
        development: development,
      );
      final adapter = _RecordingAdapter();
      client.dio.httpClientAdapter = adapter;
      await client.dio.get<Object>('/v1/me');
      return adapter.last!.headers;
    }

    test('a debug build sends it as x-forwarded-for', () async {
      expect((await headersOf(development: true))['x-forwarded-for'], '198.18.4.7');
    });

    test('a release build ignores it', () async {
      expect(await headersOf(development: false), isNot(contains('x-forwarded-for')));
    });

    test('without one of its own it sends the address the suite set while the app runs', () async {
      final before = debugClientIp;
      addTearDown(() => debugClientIp = before);
      debugClientIp = '198.19.8.9';
      final client = ApiClient.forServer(Uri.parse('https://example.test'), development: true);
      final adapter = _RecordingAdapter();
      client.dio.httpClientAdapter = adapter;
      await client.dio.get<Object>('/v1/me');
      expect(adapter.last!.headers['x-forwarded-for'], '198.19.8.9');
    });

    test('a debug build without one sends none', () async {
      expect(await headersOf(development: true, ip: ''), isNot(contains('x-forwarded-for')));
    });
  });
}
