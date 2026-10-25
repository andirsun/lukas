// What the export and deleting the account ask of the server: the web's
// apps/web/app/features/settings/use-export.ts (`GET /v1/me/export`) and DeleteAccount.tsx
// (`DELETE /v1/me`).
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/session.dart';
import '../home/home_repository.dart';
import 'settings_model.dart';

/// The two exports (`GET /v1/me/export?format=`): everything as JSON, or the transactions as CSV.
enum ExportFormat {
  json('application/json'),
  csv('text/csv');

  const ExportFormat(this.mime);

  /// The file's MIME type, for the save picker and the share sheet.
  final String mime;
}

/// An export as the server made it.
class ExportFile {
  const ExportFile({required this.name, required this.bytes, required this.mime});

  final String name;
  final Uint8List bytes;
  final String mime;
}

/// The account's own endpoints. Every failure is a [HomeFailure].
abstract interface class AccountRepository {
  /// The export, named by the server (`lukas-export-<day>.<format>`).
  Future<ExportFile> export(ExportFormat format);

  /// Deletes the account and everything in it, for good (`DELETE /v1/me`, 204).
  Future<void> deleteAccount();
}

/// [AccountRepository] over the API's HTTP client.
class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._dio);

  final Dio _dio;

  @override
  Future<ExportFile> export(ExportFormat format) async {
    try {
      final response = await _dio.get<List<int>>(
        '/v1/me/export',
        queryParameters: {'format': format.name},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) throw const HomeFailure(500);
      return ExportFile(
        name: filenameFrom(
          response.headers.value('content-disposition'),
          'lukas-export.${format.name}',
        ),
        bytes: Uint8List.fromList(bytes),
        mime: format.mime,
      );
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<Object?>('/v1/me');
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }
}

/// The account's endpoints for the signed-in session (rebuilt when the token changes).
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => ApiAccountRepository(ref.watch(apiClientProvider).dio),
);
