// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_categories_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SummaryCategoriesInnerStateEnum _$summaryCategoriesInnerStateEnum_ok =
    const SummaryCategoriesInnerStateEnum._('ok');
const SummaryCategoriesInnerStateEnum _$summaryCategoriesInnerStateEnum_near =
    const SummaryCategoriesInnerStateEnum._('near');
const SummaryCategoriesInnerStateEnum _$summaryCategoriesInnerStateEnum_over =
    const SummaryCategoriesInnerStateEnum._('over');

SummaryCategoriesInnerStateEnum _$summaryCategoriesInnerStateEnumValueOf(String name) {
  switch (name) {
    case 'ok':
      return _$summaryCategoriesInnerStateEnum_ok;
    case 'near':
      return _$summaryCategoriesInnerStateEnum_near;
    case 'over':
      return _$summaryCategoriesInnerStateEnum_over;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SummaryCategoriesInnerStateEnum> _$summaryCategoriesInnerStateEnumValues =
    BuiltSet<SummaryCategoriesInnerStateEnum>(const <SummaryCategoriesInnerStateEnum>[
      _$summaryCategoriesInnerStateEnum_ok,
      _$summaryCategoriesInnerStateEnum_near,
      _$summaryCategoriesInnerStateEnum_over,
    ]);

Serializer<SummaryCategoriesInnerStateEnum> _$summaryCategoriesInnerStateEnumSerializer =
    _$SummaryCategoriesInnerStateEnumSerializer();

class _$SummaryCategoriesInnerStateEnumSerializer
    implements PrimitiveSerializer<SummaryCategoriesInnerStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ok': 'ok',
    'near': 'near',
    'over': 'over',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ok': 'ok',
    'near': 'near',
    'over': 'over',
  };

  @override
  final Iterable<Type> types = const <Type>[SummaryCategoriesInnerStateEnum];
  @override
  final String wireName = 'SummaryCategoriesInnerStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    SummaryCategoriesInnerStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SummaryCategoriesInnerStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SummaryCategoriesInnerStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$SummaryCategoriesInner extends SummaryCategoriesInner {
  @override
  final String categoryId;
  @override
  final int? budget;
  @override
  final int spent;
  @override
  final int? remaining;
  @override
  final num? ratio;
  @override
  final SummaryCategoriesInnerStateEnum state;

  factory _$SummaryCategoriesInner([void Function(SummaryCategoriesInnerBuilder)? updates]) =>
      (SummaryCategoriesInnerBuilder()..update(updates))._build();

  _$SummaryCategoriesInner._({
    required this.categoryId,
    this.budget,
    required this.spent,
    this.remaining,
    this.ratio,
    required this.state,
  }) : super._();
  @override
  SummaryCategoriesInner rebuild(void Function(SummaryCategoriesInnerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SummaryCategoriesInnerBuilder toBuilder() => SummaryCategoriesInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SummaryCategoriesInner &&
        categoryId == other.categoryId &&
        budget == other.budget &&
        spent == other.spent &&
        remaining == other.remaining &&
        ratio == other.ratio &&
        state == other.state;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, budget.hashCode);
    _$hash = $jc(_$hash, spent.hashCode);
    _$hash = $jc(_$hash, remaining.hashCode);
    _$hash = $jc(_$hash, ratio.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SummaryCategoriesInner')
          ..add('categoryId', categoryId)
          ..add('budget', budget)
          ..add('spent', spent)
          ..add('remaining', remaining)
          ..add('ratio', ratio)
          ..add('state', state))
        .toString();
  }
}

class SummaryCategoriesInnerBuilder
    implements Builder<SummaryCategoriesInner, SummaryCategoriesInnerBuilder> {
  _$SummaryCategoriesInner? _$v;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  int? _budget;
  int? get budget => _$this._budget;
  set budget(int? budget) => _$this._budget = budget;

  int? _spent;
  int? get spent => _$this._spent;
  set spent(int? spent) => _$this._spent = spent;

  int? _remaining;
  int? get remaining => _$this._remaining;
  set remaining(int? remaining) => _$this._remaining = remaining;

  num? _ratio;
  num? get ratio => _$this._ratio;
  set ratio(num? ratio) => _$this._ratio = ratio;

  SummaryCategoriesInnerStateEnum? _state;
  SummaryCategoriesInnerStateEnum? get state => _$this._state;
  set state(SummaryCategoriesInnerStateEnum? state) => _$this._state = state;

  SummaryCategoriesInnerBuilder() {
    SummaryCategoriesInner._defaults(this);
  }

  SummaryCategoriesInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categoryId = $v.categoryId;
      _budget = $v.budget;
      _spent = $v.spent;
      _remaining = $v.remaining;
      _ratio = $v.ratio;
      _state = $v.state;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SummaryCategoriesInner other) {
    _$v = other as _$SummaryCategoriesInner;
  }

  @override
  void update(void Function(SummaryCategoriesInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SummaryCategoriesInner build() => _build();

  _$SummaryCategoriesInner _build() {
    final _$result =
        _$v ??
        _$SummaryCategoriesInner._(
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'SummaryCategoriesInner',
            'categoryId',
          ),
          budget: budget,
          spent: BuiltValueNullFieldError.checkNotNull(spent, r'SummaryCategoriesInner', 'spent'),
          remaining: remaining,
          ratio: ratio,
          state: BuiltValueNullFieldError.checkNotNull(state, r'SummaryCategoriesInner', 'state'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
