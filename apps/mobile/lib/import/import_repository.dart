import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_repository.dart';

/// What the import reads and changes on the server, as the web's does
/// (apps/web/app/features/onboarding/onboarding-api.ts `uploadImport`, and use-import-flow.ts).
abstract interface class ImportRepository {
  /// `POST /v1/imports` (multipart: `source=budge` and the file): the preview of what confirming
  /// would do. Nothing changes until [confirm]. Throws a [HomeFailure] with the API's `code`:
  /// `import_too_large` (413, over 5 MB), `import_unrecognized_format` (422), `import_duplicate_file`
  /// (409, already imported).
  Future<FileImport> upload(String fileName, Uint8List bytes);

  /// `DELETE /v1/imports/{id}`: drops a preview that was not confirmed.
  Future<void> discard(String id);

  /// `POST /v1/imports/{id}/confirm`: the rows go in. [adoptFileCurrency] switches the (still empty)
  /// account to the file's currency in the same transaction, as the preview's `adoptsCurrency` said.
  Future<FileImport> confirm(String id, {bool adoptFileCurrency = false});
}

/// [ImportRepository] over the generated client.
class ApiImportRepository implements ImportRepository {
  ApiImportRepository(this._api);

  final DefaultApi _api;

  static Future<T> _settle<T>(Future<Response<T>> Function() call) async {
    try {
      final data = (await call()).data;
      if (data == null) throw const HomeFailure(500);
      return data;
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  @override
  Future<FileImport> upload(String fileName, Uint8List bytes) => _settle(
    () => _api.createImport(
      source_: 'budge',
      file: MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType('text', 'csv'),
      ),
    ),
  );

  @override
  Future<void> discard(String id) async {
    try {
      await _api.revertImport(id: id);
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  @override
  Future<FileImport> confirm(String id, {bool adoptFileCurrency = false}) => _settle(
    () => _api.confirmImport(
      id: id,
      // Always a body, `{}` when not adopting: the client marks the request as JSON, and the API
      // answers an empty JSON body with 400 "Malformed JSON" (the web sends neither a body nor the type).
      confirmImport: ConfirmImport((b) => b..adoptFileCurrency = adoptFileCurrency ? true : null),
    ),
  );
}

/// The import repository for the signed-in session (rebuilt when the token changes).
final importRepositoryProvider = Provider<ImportRepository>(
  (ref) => ApiImportRepository(ref.watch(apiClientProvider).api.getDefaultApi()),
);
