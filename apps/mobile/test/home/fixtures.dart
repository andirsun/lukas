import 'package:lukitas/api/gen/lukitas_api.dart';

/// A transaction as the API sends it. [amount] is signed cents (expenses negative).
Transaction tx(
  String id,
  String date,
  int amount, {
  String? name,
  String status = 'paid',
  String categoryId = 'cat-groceries',
  String currency = 'COP',
}) => Transaction(
  (b) => b
    ..id = id
    ..name = name ?? id
    ..amount = amount
    ..currency = currency
    ..date = date
    ..status = status == 'pending' ? TransactionStatusEnum.pending : TransactionStatusEnum.paid
    ..categoryId = categoryId
    ..source_ = TransactionSource_Enum.app
    ..createdAt = '2026-10-01T10:00:00.000Z'
    ..updatedAt = '2026-10-01T10:00:00.000Z',
);

SummaryCategoriesInner categorySummary(
  String categoryId, {
  int? budget,
  int spent = 0,
  String state = 'ok',
}) => SummaryCategoriesInner(
  (b) => b
    ..categoryId = categoryId
    ..budget = budget
    ..spent = spent
    ..remaining = budget == null ? null : budget - spent
    ..ratio = budget == null || budget == 0 ? null : spent / budget
    ..state = SummaryCategoriesInnerStateEnum.valueOf(state),
);

/// A month's summary. Amounts are cents.
Summary summary({
  String month = '2026-10',
  int budgetTotal = 0,
  int spent = 0,
  int? remaining,
  List<SummaryCategoriesInner> categories = const [],
}) => Summary(
  (b) => b
    ..month = month
    ..budgetTotal = budgetTotal
    ..spent = spent
    ..remaining = remaining ?? budgetTotal - spent
    ..income = 0
    ..balance = -spent
    ..categories.replace(categories),
);

Category category(
  String id,
  String name, {
  String kind = 'expense',
  String icon = '🛒',
  String color = '#2fd388',
  int? budget,
  bool archived = false,
}) => Category(
  (b) => b
    ..id = id
    ..name = name
    ..kind = kind == 'income' ? CategoryKindEnum.income : CategoryKindEnum.expense
    ..icon = icon
    ..color = color
    ..sortOrder = 0
    ..archived = archived
    ..currentBudget = budget,
);
