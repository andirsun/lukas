import 'package:flutter_test/flutter_test.dart';
import 'package:lukitas/api/client.dart';

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

  test('forServer sends the bearer token only when there is one', () {
    final signedIn = ApiClient.forServer(Uri.parse('https://example.test'), token: 'abc');
    expect(signedIn.dio.options.headers['Authorization'], 'Bearer abc');

    final signedOut = ApiClient.forServer(Uri.parse('https://example.test'));
    expect(signedOut.dio.options.headers.containsKey('Authorization'), isFalse);
  });
}
