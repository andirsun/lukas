// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_report_months_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrendReportMonthsInner extends TrendReportMonthsInner {
  @override
  final String month;
  @override
  final int income;
  @override
  final int expenses;
  @override
  final int budget;

  factory _$TrendReportMonthsInner([void Function(TrendReportMonthsInnerBuilder)? updates]) =>
      (TrendReportMonthsInnerBuilder()..update(updates))._build();

  _$TrendReportMonthsInner._({
    required this.month,
    required this.income,
    required this.expenses,
    required this.budget,
  }) : super._();
  @override
  TrendReportMonthsInner rebuild(void Function(TrendReportMonthsInnerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrendReportMonthsInnerBuilder toBuilder() => TrendReportMonthsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrendReportMonthsInner &&
        month == other.month &&
        income == other.income &&
        expenses == other.expenses &&
        budget == other.budget;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, month.hashCode);
    _$hash = $jc(_$hash, income.hashCode);
    _$hash = $jc(_$hash, expenses.hashCode);
    _$hash = $jc(_$hash, budget.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrendReportMonthsInner')
          ..add('month', month)
          ..add('income', income)
          ..add('expenses', expenses)
          ..add('budget', budget))
        .toString();
  }
}

class TrendReportMonthsInnerBuilder
    implements Builder<TrendReportMonthsInner, TrendReportMonthsInnerBuilder> {
  _$TrendReportMonthsInner? _$v;

  String? _month;
  String? get month => _$this._month;
  set month(String? month) => _$this._month = month;

  int? _income;
  int? get income => _$this._income;
  set income(int? income) => _$this._income = income;

  int? _expenses;
  int? get expenses => _$this._expenses;
  set expenses(int? expenses) => _$this._expenses = expenses;

  int? _budget;
  int? get budget => _$this._budget;
  set budget(int? budget) => _$this._budget = budget;

  TrendReportMonthsInnerBuilder() {
    TrendReportMonthsInner._defaults(this);
  }

  TrendReportMonthsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _month = $v.month;
      _income = $v.income;
      _expenses = $v.expenses;
      _budget = $v.budget;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrendReportMonthsInner other) {
    _$v = other as _$TrendReportMonthsInner;
  }

  @override
  void update(void Function(TrendReportMonthsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrendReportMonthsInner build() => _build();

  _$TrendReportMonthsInner _build() {
    final _$result =
        _$v ??
        _$TrendReportMonthsInner._(
          month: BuiltValueNullFieldError.checkNotNull(month, r'TrendReportMonthsInner', 'month'),
          income: BuiltValueNullFieldError.checkNotNull(
            income,
            r'TrendReportMonthsInner',
            'income',
          ),
          expenses: BuiltValueNullFieldError.checkNotNull(
            expenses,
            r'TrendReportMonthsInner',
            'expenses',
          ),
          budget: BuiltValueNullFieldError.checkNotNull(
            budget,
            r'TrendReportMonthsInner',
            'budget',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
