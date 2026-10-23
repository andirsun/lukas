import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_repository.dart';
import 'parser/parse.dart' show Draft, Kind;

/// Saving a quick capture (spec section 5.5): every movement of a sentence at once, all or
/// nothing, and undoing them together. Every failure is a [HomeFailure].
abstract interface class CaptureRepository {
  /// Saves [drafts] in one batch (`POST /v1/transactions/batch`) and gives back the saved
  /// movements, ids included, in the same order. Every draft needs a category.
  ///
  /// [idempotencyKey] is the batch attempt's: the same for Reintentar, so a retry after a lost
  /// answer gets the first answer back instead of a second set of rows.
  Future<List<Transaction>> saveBatch(List<Draft> drafts, {required String idempotencyKey});

  /// Soft-deletes the movements [ids] together (`POST /v1/transactions/batch-delete`): one
  /// Deshacer for the whole batch.
  Future<void> undoBatch(List<String> ids);
}

/// [CaptureRepository] over the generated client.
class ApiCaptureRepository implements CaptureRepository {
  ApiCaptureRepository(this._api);

  final DefaultApi _api;

  @override
  Future<List<Transaction>> saveBatch(List<Draft> drafts, {required String idempotencyKey}) async {
    if (drafts.isEmpty || drafts.any((d) => d.categoryId == null)) {
      throw ArgumentError.value(drafts, 'drafts', 'every draft needs a category');
    }
    final batch = CreateTransactionsBatch(
      (b) => b.items = ListBuilder([
        for (final draft in drafts)
          CreateTransaction(
            (t) => t
              ..name = draft.name
              ..amount = draft.kind == Kind.expense ? -draft.amount : draft.amount
              ..categoryId = draft.categoryId
              ..date = draft.date
              ..status = CreateTransactionStatusEnum.paid
              ..source_ = CreateTransactionSource_Enum.app,
          ),
      ]),
    );
    try {
      final data = (await _api.createTransactionsBatch(
        idempotencyKey: idempotencyKey,
        createTransactionsBatch: batch,
      )).data;
      if (data == null) throw const HomeFailure(500);
      return data.items.toList();
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  @override
  Future<void> undoBatch(List<String> ids) async {
    try {
      await _api.deleteTransactionsBatch(
        deleteTransactionsBatch: DeleteTransactionsBatch((b) => b.ids = ListBuilder(ids)),
      );
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }
}

/// The capture repository for the signed-in session (rebuilt when the token changes).
final captureRepositoryProvider = Provider<CaptureRepository>(
  (ref) => ApiCaptureRepository(ref.watch(apiClientProvider).api.getDefaultApi()),
);
