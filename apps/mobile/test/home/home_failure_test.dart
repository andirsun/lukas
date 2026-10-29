import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/home/home_repository.dart';

/// A Dio error with the answer [status] and [data], as a call to `/api/...` gets it.
DioException answered(int status, Object? data) {
  final request = RequestOptions(path: '/v1/transactions');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: request,
    response: Response(requestOptions: request, statusCode: status, data: data),
  );
}

void main() {
  test('no answer at all is offline', () {
    final error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/v1/transactions'),
      reason: 'Connection refused',
    );
    expect(HomeFailure.fromDio(error).offline, isTrue);
  });

  // The server down behind Caddy and Cloudflare: the phone gets an answer, but from the proxy, not
  // from the API, so it is the same as no answer at all.
  for (final status in [502, 503, 504, 520, 521, 522, 523, 524, 525, 526, 530]) {
    test('a proxy answering $status for a server that is not there is offline', () {
      final failure = HomeFailure.fromDio(
        answered(status, '<!DOCTYPE html><title>$status</title>'),
      );
      expect(failure.offline, isTrue);
      expect(failure.status, 0);
    });
  }

  test('a proxy answering with an empty body is offline', () {
    expect(HomeFailure.fromDio(answered(502, '')).offline, isTrue);
  });

  test("the API's own 503 is a server error, not offline", () {
    final failure = HomeFailure.fromDio(
      answered(503, {'code': 'internal_error', 'title': 'Internal error'}),
    );
    expect(failure.offline, isFalse);
    expect(failure.status, 503);
    expect(failure.code, 'internal_error');
  });

  test('a 500 is a server error, not offline', () {
    final failure = HomeFailure.fromDio(answered(500, '<html>oops</html>'));
    expect(failure.offline, isFalse);
    expect(failure.status, 500);
  });
}
