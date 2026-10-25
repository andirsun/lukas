// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_budget.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SetBudget extends SetBudget {
  @override
  final int amount;
  @override
  final String effectiveFrom;

  factory _$SetBudget([void Function(SetBudgetBuilder)? updates]) =>
      (SetBudgetBuilder()..update(updates))._build();

  _$SetBudget._({required this.amount, required this.effectiveFrom}) : super._();
  @override
  SetBudget rebuild(void Function(SetBudgetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SetBudgetBuilder toBuilder() => SetBudgetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SetBudget && amount == other.amount && effectiveFrom == other.effectiveFrom;
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
    return (newBuiltValueToStringHelper(r'SetBudget')
          ..add('amount', amount)
          ..add('effectiveFrom', effectiveFrom))
        .toString();
  }
}

class SetBudgetBuilder implements Builder<SetBudget, SetBudgetBuilder> {
  _$SetBudget? _$v;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _effectiveFrom;
  String? get effectiveFrom => _$this._effectiveFrom;
  set effectiveFrom(String? effectiveFrom) => _$this._effectiveFrom = effectiveFrom;

  SetBudgetBuilder() {
    SetBudget._defaults(this);
  }

  SetBudgetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _amount = $v.amount;
      _effectiveFrom = $v.effectiveFrom;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SetBudget other) {
    _$v = other as _$SetBudget;
  }

  @override
  void update(void Function(SetBudgetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SetBudget build() => _build();

  _$SetBudget _build() {
    final _$result =
        _$v ??
        _$SetBudget._(
          amount: BuiltValueNullFieldError.checkNotNull(amount, r'SetBudget', 'amount'),
          effectiveFrom: BuiltValueNullFieldError.checkNotNull(
            effectiveFrom,
            r'SetBudget',
            'effectiveFrom',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
