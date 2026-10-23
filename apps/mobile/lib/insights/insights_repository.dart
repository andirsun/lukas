import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/gen/lukitas_api.dart';
import '../api/session.dart';
import '../home/home_repository.dart';

/// What Análisis reads of the server, as the web's queries do (`useReportByCategory`, `useTrend`,
/// `useCostOfLiving` in apps/web/app/api/queries.ts). The profile and the categories are home's
/// ([HomeRepository]). There is no cache of these reports: offline, Análisis says so.
abstract interface class InsightsRepository {
  /// Totals per category over `from` to `to` (`YYYY-MM`, both included) for [kind] (`expense` or
  /// `income`), only the [status] (`paid` or `pending`) when given.
  Future<CategoryReport> byCategory({
    required String from,
    required String to,
    required String kind,
    String? status,
  });

  /// Income, expenses and budget of each month from `from` to `to`, oldest first.
  Future<TrendReport> trend({required String from, required String to});

  /// The average monthly spending over the last [months] complete months.
  Future<CostOfLivingReport> costOfLiving(int months);
}

/// [InsightsRepository] over the generated client. A call that fails throws a [HomeFailure].
class ApiInsightsRepository implements InsightsRepository {
  ApiInsightsRepository(this._api);

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
  Future<CategoryReport> byCategory({
    required String from,
    required String to,
    required String kind,
    String? status,
  }) => _settle(() => _api.getCategoryReport(from: from, to: to, kind: kind, status: status));

  @override
  Future<TrendReport> trend({required String from, required String to}) =>
      _settle(() => _api.getTrendReport(from: from, to: to));

  @override
  Future<CostOfLivingReport> costOfLiving(int months) =>
      _settle(() => _api.getCostOfLivingReport(months: months));
}

/// The insights repository for the signed-in session (rebuilt when the token changes).
final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => ApiInsightsRepository(ref.watch(apiClientProvider).api.getDefaultApi()),
);
