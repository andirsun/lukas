// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Summary extends Summary {
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
  final BuiltList<SummaryCategoriesInner> categories;

  factory _$Summary([void Function(SummaryBuilder)? updates]) =>
      (SummaryBuilder()..update(updates))._build();

  _$Summary._({
    required this.month,
    required this.budgetTotal,
    required this.spent,
    required this.remaining,
    required this.income,
    required this.balance,
    required this.categories,
  }) : super._();
  @override
  Summary rebuild(void Function(SummaryBuilder) updates) => (toBuilder()..update(updates)).build();

  @override
  SummaryBuilder toBuilder() => SummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Summary &&
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
    return (newBuiltValueToStringHelper(r'Summary')
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

class SummaryBuilder implements Builder<Summary, SummaryBuilder> {
  _$Summary? _$v;

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

  ListBuilder<SummaryCategoriesInner>? _categories;
  ListBuilder<SummaryCategoriesInner> get categories =>
      _$this._categories ??= ListBuilder<SummaryCategoriesInner>();
  set categories(ListBuilder<SummaryCategoriesInner>? categories) =>
      _$this._categories = categories;

  SummaryBuilder() {
    Summary._defaults(this);
  }

  SummaryBuilder get _$this {
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
  void replace(Summary other) {
    _$v = other as _$Summary;
  }

  @override
  void update(void Function(SummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Summary build() => _build();

  _$Summary _build() {
    _$Summary _$result;
    try {
      _$result =
          _$v ??
          _$Summary._(
            month: BuiltValueNullFieldError.checkNotNull(month, r'Summary', 'month'),
            budgetTotal: BuiltValueNullFieldError.checkNotNull(
              budgetTotal,
              r'Summary',
              'budgetTotal',
            ),
            spent: BuiltValueNullFieldError.checkNotNull(spent, r'Summary', 'spent'),
            remaining: BuiltValueNullFieldError.checkNotNull(remaining, r'Summary', 'remaining'),
            income: BuiltValueNullFieldError.checkNotNull(income, r'Summary', 'income'),
            balance: BuiltValueNullFieldError.checkNotNull(balance, r'Summary', 'balance'),
            categories: categories.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'categories';
        categories.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Summary', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
