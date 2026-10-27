import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'device.dart';
import 'gen/lukitas_api.dart';

/// The client address a debug build tells the server it is (`--dart-define=LUKITAS_CLIENT_IP=...`,
/// or set while the app runs), as `x-forwarded-for`. The emulator suite gives each group of tests its
/// own, as the web's e2e gives each browser its own, so the API's per-address limit on sign-in codes
/// counts each as a new client. Empty by default, and never sent by a release build.
String debugClientIp = const String.fromEnvironment('LUKITAS_CLIENT_IP');

/// The API at one server: `<server>/api`, with the session's bearer token when signed in and the
/// phone's time zone and language ([DeviceHints]) on every request.
///
/// [api] is the generated client (lib/api/gen, from the API's OpenAPI document by
/// scripts/gen-api.sh); its paths carry no `/api` prefix, so the base URL adds it.
class ApiClient {
  // No auth interceptors: the API declares no security scheme, and the token is a default header.
  ApiClient._(this.dio) : api = LukitasApi(dio: dio, interceptors: []);

  /// A client for [server] (e.g. `https://app-lukas.andersonlaverde.com`). Any path on [server] is
  /// kept, so an API behind a sub-path works; a query or fragment is dropped.
  ///
  /// [clientIp] (else [debugClientIp]) is sent as `x-forwarded-for` only when [development] (debug builds: [kDebugMode]) is
  /// true, so a release build never claims an address of its own. The server decides what it trusts.
  static ApiClient forServer(
    Uri server, {
    String? token,
    DeviceHints? hints,
    String? clientIp,
    bool development = kDebugMode,
  }) {
    final address = clientIp ?? debugClientIp;
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
          headers: {
            ...?hints?.headers,
            if (token != null) 'Authorization': 'Bearer $token',
            if (development && address.isNotEmpty) 'x-forwarded-for': address,
          },
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
