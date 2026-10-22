// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_summary_get200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1SummaryGet200Response extends V1SummaryGet200Response {
  @override
  final String month;
  @override
  final int budgetTotal;
  @override
  final int spent;
  @override
  final int remaining;
  @override
  final int income;
  @override
  final int balance;
  @override
  final BuiltList<V1SummaryGet200ResponseCategoriesInner> categories;

  factory _$V1SummaryGet200Response([void Function(V1SummaryGet200ResponseBuilder)? updates]) =>
      (V1SummaryGet200ResponseBuilder()..update(updates))._build();

  _$V1SummaryGet200Response._({
    required this.month,
    required this.budgetTotal,
    required this.spent,
    required this.remaining,
    required this.income,
    required this.balance,
    required this.categories,
  }) : super._();
  @override
  V1SummaryGet200Response rebuild(void Function(V1SummaryGet200ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1SummaryGet200ResponseBuilder toBuilder() => V1SummaryGet200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1SummaryGet200Response &&
        month == other.month &&
        budgetTotal == other.budgetTotal &&
        spent == other.spent &&
        remaining == other.remaining &&
        income == other.income &&
        balance == other.balance &&
        categories == other.categories;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, month.hashCode);
    _$hash = $jc(_$hash, budgetTotal.hashCode);
    _$hash = $jc(_$hash, spent.hashCode);
    _$hash = $jc(_$hash, remaining.hashCode);
    _$hash = $jc(_$hash, income.hashCode);
    _$hash = $jc(_$hash, balance.hashCode);
    _$hash = $jc(_$hash, categories.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1SummaryGet200Response')
          ..add('month', month)
          ..add('budgetTotal', budgetTotal)
          ..add('spent', spent)
          ..add('remaining', remaining)
          ..add('income', income)
          ..add('balance', balance)
          ..add('categories', categories))
        .toString();
  }
}

class V1SummaryGet200ResponseBuilder
    implements Builder<V1SummaryGet200Response, V1SummaryGet200ResponseBuilder> {
  _$V1SummaryGet200Response? _$v;

  String? _month;
  String? get month => _$this._month;
  set month(String? month) => _$this._month = month;

  int? _budgetTotal;
  int? get budgetTotal => _$this._budgetTotal;
  set budgetTotal(int? budgetTotal) => _$this._budgetTotal = budgetTotal;

  int? _spent;
  int? get spent => _$this._spent;
  set spent(int? spent) => _$this._spent = spent;

  int? _remaining;
  int? get remaining => _$this._remaining;
  set remaining(int? remaining) => _$this._remaining = remaining;

  int? _income;
  int? get income => _$this._income;
  set income(int? income) => _$this._income = income;

  int? _balance;
  int? get balance => _$this._balance;
  set balance(int? balance) => _$this._balance = balance;

  ListBuilder<V1SummaryGet200ResponseCategoriesInner>? _categories;
  ListBuilder<V1SummaryGet200ResponseCategoriesInner> get categories =>
      _$this._categories ??= ListBuilder<V1SummaryGet200ResponseCategoriesInner>();
  set categories(ListBuilder<V1SummaryGet200ResponseCategoriesInner>? categories) =>
      _$this._categories = categories;

  V1SummaryGet200ResponseBuilder() {
    V1SummaryGet200Response._defaults(this);
  }

  V1SummaryGet200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _month = $v.month;
      _budgetTotal = $v.budgetTotal;
      _spent = $v.spent;
      _remaining = $v.remaining;
      _income = $v.income;
      _balance = $v.balance;
      _categories = $v.categories.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1SummaryGet200Response other) {
    _$v = other as _$V1SummaryGet200Response;
  }

  @override
  void update(void Function(V1SummaryGet200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1SummaryGet200Response build() => _build();

  _$V1SummaryGet200Response _build() {
    _$V1SummaryGet200Response _$result;
    try {
      _$result =
          _$v ??
          _$V1SummaryGet200Response._(
            month: BuiltValueNullFieldError.checkNotNull(
              month,
              r'V1SummaryGet200Response',
              'month',
            ),
            budgetTotal: BuiltValueNullFieldError.checkNotNull(
              budgetTotal,
              r'V1SummaryGet200Response',
              'budgetTotal',
            ),
            spent: BuiltValueNullFieldError.checkNotNull(
              spent,
              r'V1SummaryGet200Response',
              'spent',
            ),
            remaining: BuiltValueNullFieldError.checkNotNull(
              remaining,
              r'V1SummaryGet200Response',
              'remaining',
            ),
            income: BuiltValueNullFieldError.checkNotNull(
              income,
              r'V1SummaryGet200Response',
              'income',
            ),
            balance: BuiltValueNullFieldError.checkNotNull(
              balance,
              r'V1SummaryGet200Response',
              'balance',
            ),
            categories: categories.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'categories';
        categories.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'V1SummaryGet200Response', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
