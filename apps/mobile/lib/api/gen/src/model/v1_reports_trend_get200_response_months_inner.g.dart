// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_reports_trend_get200_response_months_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ReportsTrendGet200ResponseMonthsInner extends V1ReportsTrendGet200ResponseMonthsInner {
  @override
  final String month;
  @override
  final int income;
  @override
  final int expenses;
  @override
  final int budget;

  factory _$V1ReportsTrendGet200ResponseMonthsInner([
    void Function(V1ReportsTrendGet200ResponseMonthsInnerBuilder)? updates,
  ]) => (V1ReportsTrendGet200ResponseMonthsInnerBuilder()..update(updates))._build();

  _$V1ReportsTrendGet200ResponseMonthsInner._({
    required this.month,
    required this.income,
    required this.expenses,
    required this.budget,
  }) : super._();
  @override
  V1ReportsTrendGet200ResponseMonthsInner rebuild(
    void Function(V1ReportsTrendGet200ResponseMonthsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ReportsTrendGet200ResponseMonthsInnerBuilder toBuilder() =>
      V1ReportsTrendGet200ResponseMonthsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ReportsTrendGet200ResponseMonthsInner &&
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
    return (newBuiltValueToStringHelper(r'V1ReportsTrendGet200ResponseMonthsInner')
          ..add('month', month)
          ..add('income', income)
          ..add('expenses', expenses)
          ..add('budget', budget))
        .toString();
  }
}

class V1ReportsTrendGet200ResponseMonthsInnerBuilder
    implements
        Builder<
          V1ReportsTrendGet200ResponseMonthsInner,
          V1ReportsTrendGet200ResponseMonthsInnerBuilder
        > {
  _$V1ReportsTrendGet200ResponseMonthsInner? _$v;

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

  V1ReportsTrendGet200ResponseMonthsInnerBuilder() {
    V1ReportsTrendGet200ResponseMonthsInner._defaults(this);
  }

  V1ReportsTrendGet200ResponseMonthsInnerBuilder get _$this {
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
  void replace(V1ReportsTrendGet200ResponseMonthsInner other) {
    _$v = other as _$V1ReportsTrendGet200ResponseMonthsInner;
  }

  @override
  void update(void Function(V1ReportsTrendGet200ResponseMonthsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ReportsTrendGet200ResponseMonthsInner build() => _build();

  _$V1ReportsTrendGet200ResponseMonthsInner _build() {
    final _$result =
        _$v ??
        _$V1ReportsTrendGet200ResponseMonthsInner._(
          month: BuiltValueNullFieldError.checkNotNull(
            month,
            r'V1ReportsTrendGet200ResponseMonthsInner',
            'month',
          ),
          income: BuiltValueNullFieldError.checkNotNull(
            income,
            r'V1ReportsTrendGet200ResponseMonthsInner',
            'income',
          ),
          expenses: BuiltValueNullFieldError.checkNotNull(
            expenses,
            r'V1ReportsTrendGet200ResponseMonthsInner',
            'expenses',
          ),
          budget: BuiltValueNullFieldError.checkNotNull(
            budget,
            r'V1ReportsTrendGet200ResponseMonthsInner',
            'budget',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
