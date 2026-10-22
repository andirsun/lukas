// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_categories_id_budget_put_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1CategoriesIdBudgetPutRequest extends V1CategoriesIdBudgetPutRequest {
  @override
  final int amount;
  @override
  final String effectiveFrom;

  factory _$V1CategoriesIdBudgetPutRequest([
    void Function(V1CategoriesIdBudgetPutRequestBuilder)? updates,
  ]) => (V1CategoriesIdBudgetPutRequestBuilder()..update(updates))._build();

  _$V1CategoriesIdBudgetPutRequest._({required this.amount, required this.effectiveFrom})
    : super._();
  @override
  V1CategoriesIdBudgetPutRequest rebuild(
    void Function(V1CategoriesIdBudgetPutRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1CategoriesIdBudgetPutRequestBuilder toBuilder() =>
      V1CategoriesIdBudgetPutRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1CategoriesIdBudgetPutRequest &&
        amount == other.amount &&
        effectiveFrom == other.effectiveFrom;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, effectiveFrom.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1CategoriesIdBudgetPutRequest')
          ..add('amount', amount)
          ..add('effectiveFrom', effectiveFrom))
        .toString();
  }
}

class V1CategoriesIdBudgetPutRequestBuilder
    implements Builder<V1CategoriesIdBudgetPutRequest, V1CategoriesIdBudgetPutRequestBuilder> {
  _$V1CategoriesIdBudgetPutRequest? _$v;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _effectiveFrom;
  String? get effectiveFrom => _$this._effectiveFrom;
  set effectiveFrom(String? effectiveFrom) => _$this._effectiveFrom = effectiveFrom;

  V1CategoriesIdBudgetPutRequestBuilder() {
    V1CategoriesIdBudgetPutRequest._defaults(this);
  }

  V1CategoriesIdBudgetPutRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amount = $v.amount;
      _effectiveFrom = $v.effectiveFrom;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1CategoriesIdBudgetPutRequest other) {
    _$v = other as _$V1CategoriesIdBudgetPutRequest;
  }

  @override
  void update(void Function(V1CategoriesIdBudgetPutRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1CategoriesIdBudgetPutRequest build() => _build();

  _$V1CategoriesIdBudgetPutRequest _build() {
    final _$result =
        _$v ??
        _$V1CategoriesIdBudgetPutRequest._(
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'V1CategoriesIdBudgetPutRequest',
            'amount',
          ),
          effectiveFrom: BuiltValueNullFieldError.checkNotNull(
            effectiveFrom,
            r'V1CategoriesIdBudgetPutRequest',
            'effectiveFrom',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
