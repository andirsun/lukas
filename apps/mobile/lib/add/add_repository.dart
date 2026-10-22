import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_repository.dart';

/// The fields of a movement that changed in an edit (the API's PATCH). Anything left out is not
/// sent, so a change made elsewhere in the meantime survives.
class TransactionPatch {
  const TransactionPatch({
    this.name,
    this.amount,
    this.categoryId,
    this.date,
    this.pending,
    this.setNote = false,
    this.note,
  });

  final String? name;

  /// Signed cents, as stored.
  final int? amount;
  final String? categoryId;

  /// `YYYY-MM-DD`.
  final String? date;

  /// Whether the movement is now pending (true) or paid (false); null: unchanged.
  final bool? pending;

  /// Whether the note changed: with [note] null that clears it.
  final bool setNote;
  final String? note;

  bool get isEmpty =>
      name == null &&
      amount == null &&
      categoryId == null &&
      date == null &&
      pending == null &&
      !setNote;

  Map<String, Object?> toJson() => {
    if (name != null) 'name': name,
    if (amount != null) 'amount': amount,
    if (categoryId != null) 'categoryId': categoryId,
    if (date != null) 'date': date,
    if (pending != null) 'status': pending! ? 'pending' : 'paid',
    if (setNote) 'note': note,
  };
}

/// What the add sheet reads and writes on the server (apps/web/app/api/queries.ts, the create,
/// update and suggestions queries). Every failure is a [HomeFailure].
abstract interface class AddRepository {
  /// Saves a new movement. [idempotencyKey] makes a repeat of the same save one movement: a retry
  /// of a request that did reach the server gets its answer instead of a second row.
  Future<Transaction> create(CreateTransaction input, {required String idempotencyKey});

  Future<Transaction> update(String id, TransactionPatch patch);

  /// Names already used, with the category they usually go in, most used first. [query] filters;
  /// empty means the top ones.
  Future<List<TransactionSuggestion>> suggestions(String query);
}

/// How many suggestions are asked for: more than two rows can show, so the rows are always full.
const suggestionsAsked = 8;

/// [AddRepository] over the generated client.
class ApiAddRepository implements AddRepository {
  ApiAddRepository(this._api, this._dio);

  final DefaultApi _api;

  /// The same HTTP client the generated one uses, for the one call it cannot express (see
  /// [update]).
  final Dio _dio;

  @override
  Future<Transaction> create(CreateTransaction input, {required String idempotencyKey}) async {
    try {
      final data = (await _api.createTransaction(
        createTransaction: input,
        idempotencyKey: idempotencyKey,
      )).data;
      if (data == null) throw const HomeFailure(500);
      return data;
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  /// Sent by hand rather than through the generated `updateTransaction`: its model leaves a null
  /// field out, so it cannot say "clear the note" (`{"note": null}`).
  @override
  Future<Transaction> update(String id, TransactionPatch patch) async {
    try {
      final response = await _dio.patch<Object?>('/v1/transactions/$id', data: patch.toJson());
      final data = response.data;
      if (data == null) throw const HomeFailure(500);
      final Transaction saved = standardSerializers.deserializeWith(Transaction.serializer, data)!;
      return saved;
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  @override
  Future<List<TransactionSuggestion>> suggestions(String query) async {
    try {
      final data = (await _api.listTransactionSuggestions(
        q: query.isEmpty ? null : query,
        limit: suggestionsAsked,
      )).data;
      if (data == null) throw const HomeFailure(500);
      return data.items.toList();
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }
}

/// The add repository for the signed-in session (rebuilt when the token changes).
final addRepositoryProvider = Provider<AddRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiAddRepository(client.api.getDefaultApi(), client.dio);
});
