// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_stats_average_monthly_spending_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ImportStatsAverageMonthlySpendingInner extends ImportStatsAverageMonthlySpendingInner {
  @override
  final String category;
  @override
  final int amount;

  factory _$ImportStatsAverageMonthlySpendingInner([
    void Function(ImportStatsAverageMonthlySpendingInnerBuilder)? updates,
  ]) => (ImportStatsAverageMonthlySpendingInnerBuilder()..update(updates))._build();

  _$ImportStatsAverageMonthlySpendingInner._({required this.category, required this.amount})
    : super._();
  @override
  ImportStatsAverageMonthlySpendingInner rebuild(
    void Function(ImportStatsAverageMonthlySpendingInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ImportStatsAverageMonthlySpendingInnerBuilder toBuilder() =>
      ImportStatsAverageMonthlySpendingInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportStatsAverageMonthlySpendingInner &&
        category == other.category &&
        amount == other.amount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImportStatsAverageMonthlySpendingInner')
          ..add('category', category)
          ..add('amount', amount))
        .toString();
  }
}

class ImportStatsAverageMonthlySpendingInnerBuilder
    implements
        Builder<
          ImportStatsAverageMonthlySpendingInner,
          ImportStatsAverageMonthlySpendingInnerBuilder
        > {
  _$ImportStatsAverageMonthlySpendingInner? _$v;

  String? _category;
  String? get category => _$this._category;
  set category(String? category) => _$this._category = category;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  ImportStatsAverageMonthlySpendingInnerBuilder() {
    ImportStatsAverageMonthlySpendingInner._defaults(this);
  }

  ImportStatsAverageMonthlySpendingInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _category = $v.category;
      _amount = $v.amount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportStatsAverageMonthlySpendingInner other) {
    _$v = other as _$ImportStatsAverageMonthlySpendingInner;
  }

  @override
  void update(void Function(ImportStatsAverageMonthlySpendingInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportStatsAverageMonthlySpendingInner build() => _build();

  _$ImportStatsAverageMonthlySpendingInner _build() {
    final _$result =
        _$v ??
        _$ImportStatsAverageMonthlySpendingInner._(
          category: BuiltValueNullFieldError.checkNotNull(
            category,
            r'ImportStatsAverageMonthlySpendingInner',
            'category',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'ImportStatsAverageMonthlySpendingInner',
            'amount',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
