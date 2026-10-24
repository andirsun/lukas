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
}
