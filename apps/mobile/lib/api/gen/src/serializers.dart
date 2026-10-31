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

import 'package:lukitas/api/gen/src/model/assistant.dart';
import 'package:lukitas/api/gen/src/model/assistant_list.dart';
import 'package:lukitas/api/gen/src/model/category.dart';
import 'package:lukitas/api/gen/src/model/category_report.dart';
import 'package:lukitas/api/gen/src/model/category_report_items_inner.dart';
import 'package:lukitas/api/gen/src/model/claim_email_send.dart';
import 'package:lukitas/api/gen/src/model/claim_email_verify.dart';
import 'package:lukitas/api/gen/src/model/confirm_import.dart';
import 'package:lukitas/api/gen/src/model/cost_of_living_report.dart';
import 'package:lukitas/api/gen/src/model/cost_of_living_report_categories_inner.dart';
import 'package:lukitas/api/gen/src/model/create_category.dart';
import 'package:lukitas/api/gen/src/model/create_recurrence.dart';
import 'package:lukitas/api/gen/src/model/create_transaction.dart';
import 'package:lukitas/api/gen/src/model/create_transaction_repeat.dart';
import 'package:lukitas/api/gen/src/model/create_transactions_batch.dart';
import 'package:lukitas/api/gen/src/model/delete_transactions_batch.dart';
import 'package:lukitas/api/gen/src/model/file_import.dart';
import 'package:lukitas/api/gen/src/model/import_stats.dart';
import 'package:lukitas/api/gen/src/model/import_stats_average_monthly_spending_inner.dart';
import 'package:lukitas/api/gen/src/model/import_stats_average_window.dart';
import 'package:lukitas/api/gen/src/model/import_stats_rejected_inner.dart';
import 'package:lukitas/api/gen/src/model/problem.dart';
import 'package:lukitas/api/gen/src/model/problem_errors_inner.dart';
import 'package:lukitas/api/gen/src/model/profile.dart';
import 'package:lukitas/api/gen/src/model/recurrence.dart';
import 'package:lukitas/api/gen/src/model/set_budget.dart';
import 'package:lukitas/api/gen/src/model/summary.dart';
import 'package:lukitas/api/gen/src/model/summary_categories_inner.dart';
import 'package:lukitas/api/gen/src/model/transaction.dart';
import 'package:lukitas/api/gen/src/model/transaction_list.dart';
import 'package:lukitas/api/gen/src/model/transaction_page.dart';
import 'package:lukitas/api/gen/src/model/transaction_suggestion.dart';
import 'package:lukitas/api/gen/src/model/transaction_suggestions.dart';
import 'package:lukitas/api/gen/src/model/trend_report.dart';
import 'package:lukitas/api/gen/src/model/trend_report_months_inner.dart';
import 'package:lukitas/api/gen/src/model/update_category.dart';
import 'package:lukitas/api/gen/src/model/update_profile.dart';
import 'package:lukitas/api/gen/src/model/update_recurrence.dart';
import 'package:lukitas/api/gen/src/model/update_transaction.dart';

part 'serializers.g.dart';

@SerializersFor([
  Assistant,
  AssistantList,
  Category,
  CategoryReport,
  CategoryReportItemsInner,
  ClaimEmailSend,
  ClaimEmailVerify,
  ConfirmImport,
  CostOfLivingReport,
  CostOfLivingReportCategoriesInner,
  CreateCategory,
  CreateRecurrence,
  CreateTransaction,
  CreateTransactionRepeat,
  CreateTransactionsBatch,
  DeleteTransactionsBatch,
  FileImport,
  ImportStats,
  ImportStatsAverageMonthlySpendingInner,
  ImportStatsAverageWindow,
  ImportStatsRejectedInner,
  Problem,
  ProblemErrorsInner,
  Profile,
  Recurrence,
  SetBudget,
  Summary,
  SummaryCategoriesInner,
  Transaction,
  TransactionList,
  TransactionPage,
  TransactionSuggestion,
  TransactionSuggestions,
  TrendReport,
  TrendReportMonthsInner,
  UpdateCategory,
  UpdateProfile,
  UpdateRecurrence,
  UpdateTransaction,
])
Serializers serializers =
    (_$serializers.toBuilder()
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(CategoryReportItemsInner)]),
            () => ListBuilder<CategoryReportItemsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(TrendReportMonthsInner)]),
            () => ListBuilder<TrendReportMonthsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Recurrence)]),
            () => ListBuilder<Recurrence>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(ProblemErrorsInner)]),
            () => ListBuilder<ProblemErrorsInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Category)]),
            () => ListBuilder<Category>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Transaction)]),
            () => ListBuilder<Transaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(TransactionSuggestion)]),
            () => ListBuilder<TransactionSuggestion>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(CostOfLivingReportCategoriesInner)]),
            () => ListBuilder<CostOfLivingReportCategoriesInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(SummaryCategoriesInner)]),
            () => ListBuilder<SummaryCategoriesInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(CreateTransaction)]),
            () => ListBuilder<CreateTransaction>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(String)]),
            () => ListBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(ImportStatsRejectedInner)]),
            () => ListBuilder<ImportStatsRejectedInner>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(Assistant)]),
            () => ListBuilder<Assistant>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, [FullType(ImportStatsAverageMonthlySpendingInner)]),
            () => ListBuilder<ImportStatsAverageMonthlySpendingInner>(),
          )
          ..add(const OneOfSerializer())
          ..add(const AnyOfSerializer())
          ..add(const DateSerializer())
          ..add(Iso8601DateTimeSerializer()))
        .build();

Serializers standardSerializers = (serializers.toBuilder()..addPlugin(StandardJsonPlugin()))
    .build();
