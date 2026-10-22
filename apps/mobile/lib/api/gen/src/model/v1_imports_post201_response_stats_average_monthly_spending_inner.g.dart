// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_imports_post201_response_stats_average_monthly_spending_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner
    extends V1ImportsPost201ResponseStatsAverageMonthlySpendingInner {
  @override
  final String category;
  @override
  final int amount;

  factory _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner([
    void Function(V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder)? updates,
  ]) =>
      (V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder()..update(updates))._build();

  _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner._({
    required this.category,
    required this.amount,
  }) : super._();
  @override
  V1ImportsPost201ResponseStatsAverageMonthlySpendingInner rebuild(
    void Function(V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder toBuilder() =>
      V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ImportsPost201ResponseStatsAverageMonthlySpendingInner &&
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
    return (newBuiltValueToStringHelper(r'V1ImportsPost201ResponseStatsAverageMonthlySpendingInner')
          ..add('category', category)
          ..add('amount', amount))
        .toString();
  }
}

class V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder
    implements
        Builder<
          V1ImportsPost201ResponseStatsAverageMonthlySpendingInner,
          V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder
        > {
  _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner? _$v;

  String? _category;
  String? get category => _$this._category;
  set category(String? category) => _$this._category = category;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder() {
    V1ImportsPost201ResponseStatsAverageMonthlySpendingInner._defaults(this);
  }

  V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _category = $v.category;
      _amount = $v.amount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1ImportsPost201ResponseStatsAverageMonthlySpendingInner other) {
    _$v = other as _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner;
  }

  @override
  void update(
    void Function(V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  V1ImportsPost201ResponseStatsAverageMonthlySpendingInner build() => _build();

  _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner _build() {
    final _$result =
        _$v ??
        _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner._(
          category: BuiltValueNullFieldError.checkNotNull(
            category,
            r'V1ImportsPost201ResponseStatsAverageMonthlySpendingInner',
            'category',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'V1ImportsPost201ResponseStatsAverageMonthlySpendingInner',
            'amount',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
