//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:lukitas/api/gen/src/date_serializer.dart';
import 'package:lukitas/api/gen/src/model/date.dart';

import 'package:lukitas/api/gen/src/model/v1_categories_get200_response_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_categories_id_budget_put_request.dart';
import 'package:lukitas/api/gen/src/model/v1_categories_id_patch_request.dart';
import 'package:lukitas/api/gen/src/model/v1_categories_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_imports_id_confirm_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_imports_post201_response.dart';
import 'package:lukitas/api/gen/src/model/v1_imports_post201_response_stats.dart';
import 'package:lukitas/api/gen/src/model/v1_imports_post201_response_stats_average_monthly_spending_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_imports_post201_response_stats_average_window.dart';
import 'package:lukitas/api/gen/src/model/v1_imports_post201_response_stats_rejected_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_me_claim_email_send_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_me_claim_email_verify_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_me_get200_response.dart';
import 'package:lukitas/api/gen/src/model/v1_me_patch409_response.dart';
import 'package:lukitas/api/gen/src/model/v1_me_patch409_response_errors_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_me_patch_request.dart';
import 'package:lukitas/api/gen/src/model/v1_recurrences_get200_response_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_recurrences_id_patch_request.dart';
import 'package:lukitas/api/gen/src/model/v1_recurrences_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_by_category_get200_response.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_by_category_get200_response_items_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_cost_of_living_get200_response.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_cost_of_living_get200_response_categories_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_trend_get200_response.dart';
import 'package:lukitas/api/gen/src/model/v1_reports_trend_get200_response_months_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_summary_get200_response.dart';
import 'package:lukitas/api/gen/src/model/v1_summary_get200_response_categories_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_batch_delete_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_batch_post201_response.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_batch_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_get200_response.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_get200_response_items_inner.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_id_patch_request.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_post_request.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_suggestions_get200_response.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_suggestions_get200_response_items_inner.dart';

part 'serializers.g.dart';

@SerializersFor([
  V1CategoriesGet200ResponseInner,
  V1CategoriesIdBudgetPutRequest,
  V1CategoriesIdPatchRequest,
  V1CategoriesPostRequest,
  V1ImportsIdConfirmPostRequest,
  V1ImportsPost201Response,
  V1ImportsPost201ResponseStats,
  V1ImportsPost201ResponseStatsAverageMonthlySpendingInner,
  V1ImportsPost201ResponseStatsAverageWindow,
  V1ImportsPost201ResponseStatsRejectedInner,
  V1MeClaimEmailSendPostRequest,
  V1MeClaimEmailVerifyPostRequest,
  V1MeGet200Response,
  V1MePatch409Response,
  V1MePatch409ResponseErrorsInner,
  V1MePatchRequest,
  V1RecurrencesGet200ResponseInner,
  V1RecurrencesIdPatchRequest,
  V1RecurrencesPostRequest,
  V1ReportsByCategoryGet200Response,
  V1ReportsByCategoryGet200ResponseItemsInner,
  V1ReportsCostOfLivingGet200Response,
  V1ReportsCostOfLivingGet200ResponseCategoriesInner,
  V1ReportsTrendGet200Response,
  V1ReportsTrendGet200ResponseMonthsInner,
  V1SummaryGet200Response,
  V1SummaryGet200ResponseCategoriesInner,
  V1TransactionsBatchDeletePostRequest,
  V1TransactionsBatchPost201Response,
  V1TransactionsBatchPostRequest,
  V1TransactionsGet200Response,
  V1TransactionsGet200ResponseItemsInner,
  V1TransactionsIdPatchRequest,
  V1TransactionsPostRequest,
  V1TransactionsSuggestionsGet200Response,
  V1TransactionsSuggestionsGet200ResponseItemsInner,
])
Serializers serializers =
    (_$serializers.toBuilder()
          ..addBuilderFactory(
            const FullType(BuiltList, [
              FullType(V1TransactionsSuggestionsGet200ResponseItemsInner),
            ]),
            () => ListBuilder<V1TransactionsSuggestionsGet200ResponseItemsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [
              FullType(V1ImportsPost201ResponseStatsAverageMonthlySpendingInner),
            ]),
            () => ListBuilder<V1ImportsPost201ResponseStatsAverageMonthlySpendingInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1RecurrencesGet200ResponseInner)]),
            () => ListBuilder<V1RecurrencesGet200ResponseInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1ImportsPost201ResponseStatsRejectedInner)]),
            () => ListBuilder<V1ImportsPost201ResponseStatsRejectedInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1TransactionsGet200ResponseItemsInner)]),
            () => ListBuilder<V1TransactionsGet200ResponseItemsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1TransactionsPostRequest)]),
            () => ListBuilder<V1TransactionsPostRequest>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1ReportsTrendGet200ResponseMonthsInner)]),
            () => ListBuilder<V1ReportsTrendGet200ResponseMonthsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [
              FullType(V1ReportsCostOfLivingGet200ResponseCategoriesInner),
            ]),
            () => ListBuilder<V1ReportsCostOfLivingGet200ResponseCategoriesInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1SummaryGet200ResponseCategoriesInner)]),
            () => ListBuilder<V1SummaryGet200ResponseCategoriesInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1MePatch409ResponseErrorsInner)]),
            () => ListBuilder<V1MePatch409ResponseErrorsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1ReportsByCategoryGet200ResponseItemsInner)]),
            () => ListBuilder<V1ReportsByCategoryGet200ResponseItemsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(V1CategoriesGet200ResponseInner)]),
            () => ListBuilder<V1CategoriesGet200ResponseInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..add(const OneOfSerializer())
          ..add(const AnyOfSerializer())
          ..add(const DateSerializer())
          ..add(Iso8601DateTimeSerializer()))
        .build();

Serializers standardSerializers = (serializers.toBuilder()..addPlugin(StandardJsonPlugin()))
    .build();
