import 'package:dio/dio.dart';

import 'gen/lukitas_api.dart';

/// The API at one server: `<server>/api`, with the session's bearer token when signed in.
///
/// [api] is the generated client (lib/api/gen, from the API's OpenAPI document by
/// scripts/gen-api.sh); its paths carry no `/api` prefix, so the base URL adds it.
class ApiClient {
  // No auth interceptors: the API declares no security scheme, and the token is a default header.
  ApiClient._(this.dio) : api = LukitasApi(dio: dio, interceptors: []);

  /// A client for [server] (e.g. `https://app-lukas.andersonlaverde.com`). Any path on [server] is
  /// kept, so an API behind a sub-path works; a query or fragment is dropped.
  static ApiClient forServer(Uri server, {String? token}) {
    final path = server.path.replaceFirst(RegExp(r'/+$'), '');
    final base = Uri(
      scheme: server.scheme,
      userInfo: server.userInfo.isEmpty ? null : server.userInfo,
      host: server.host,
      port: server.hasPort ? server.port : null,
      path: '$path/api',
    );
    return ApiClient._(
      Dio(
        BaseOptions(
          baseUrl: base.toString(),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      ),
    );
  }

  /// The HTTP client every call goes through.
  final Dio dio;

  /// The generated API client.
  final LukitasApi api;

  /// The base URL calls go to, `<server>/api`.
  String get baseUrl => dio.options.baseUrl;
}
