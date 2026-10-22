import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';

/// Rows asked of the API at a time. "Ver más movimientos" brings the next page.
const transactionsPageSize = 50;

/// What home needs of the profile: the currency amounts are written in and the zone "today" is
/// read in.
class HomeProfile {
  const HomeProfile({required this.id, required this.currency, required this.timezone});

  /// The user's id.
  final String id;
  final String currency;
  final String timezone;
}

/// A page of a month's transactions, newest first. [nextCursor] is null on the last page.
class TransactionsPage {
  const TransactionsPage(this.items, this.nextCursor);

  final List<Transaction> items;
  final String? nextCursor;
}

/// A call home made did not work. [status] is the HTTP status, or 0 when there was no answer at all
/// (offline, a timeout, a lost connection). [code] is the API's own error code when it sent one
/// (`category_not_found`, `idempotency_in_progress`).
class HomeFailure implements Exception {
  const HomeFailure(this.status, {this.code});

  /// What a failed Dio call means: the status and the problem document's `code`.
  factory HomeFailure.fromDio(DioException error) {
    final data = error.response?.data;
    var body = data;
    if (data is String && data.isNotEmpty) {
      try {
        body = jsonDecode(data);
      } on FormatException {
        body = null;
      }
    }
    final code = body is Map ? body['code'] : null;
    return HomeFailure(error.response?.statusCode ?? 0, code: code is String ? code : null);
  }

  final int status;
  final String? code;

  /// No answer from the server: the phone is offline or the server unreachable.
  bool get offline => status == 0;

  /// The server no longer knows the session.
  bool get unauthorized => status == 401;

  @override
  String toString() => 'HomeFailure($status)';
}

/// What home reads and changes on the server, as the web's queries do (apps/web/app/api/queries.ts).
abstract interface class HomeRepository {
  Future<HomeProfile> profile();

  Future<Summary> summary(String month);

  /// Every category, archived ones too: older transactions can be in them.
  Future<List<Category>> categories();

  Future<TransactionsPage> transactions(String month, {String? cursor});

  /// Deletes (the API keeps it, so [restore] can bring it back).
  Future<void> delete(String id);

  Future<Transaction> restore(String id);

  Future<Transaction> markPaid(String id);
}

/// [HomeRepository] over the generated client.
class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository(this._api);

  final DefaultApi _api;

  /// [call], with any Dio error turned into a [HomeFailure].
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
  Future<HomeProfile> profile() async {
    final me = await _settle(() => _api.getMe());
    return HomeProfile(id: me.id, currency: me.currency, timezone: me.timezone);
  }

  @override
  Future<Summary> summary(String month) => _settle(() => _api.getSummary(month: month));

  @override
  Future<List<Category>> categories() async {
    final list = await _settle(() => _api.listCategories(includeArchived: 'true'));
    return list.toList();
  }

  @override
  Future<TransactionsPage> transactions(String month, {String? cursor}) async {
    final page = await _settle(
      () => _api.listTransactions(month: month, cursor: cursor, limit: transactionsPageSize),
    );
    return TransactionsPage(page.items.toList(), page.nextCursor);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _api.deleteTransaction(id: id);
    } on DioException catch (error) {
      throw HomeFailure.fromDio(error);
    }
  }

  @override
  Future<Transaction> restore(String id) => _settle(() => _api.restoreTransaction(id: id));

  @override
  Future<Transaction> markPaid(String id) => _settle(
    () => _api.updateTransaction(
      id: id,
      updateTransaction: UpdateTransaction((b) => b..status = UpdateTransactionStatusEnum.paid),
    ),
  );
}

/// The home repository for the signed-in session (rebuilt when the token changes).
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => ApiHomeRepository(ref.watch(apiClientProvider).api.getDefaultApi()),
);
