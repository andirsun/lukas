// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_summary_get200_response_categories_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1SummaryGet200ResponseCategoriesInnerStateEnum
_$v1SummaryGet200ResponseCategoriesInnerStateEnum_ok =
    const V1SummaryGet200ResponseCategoriesInnerStateEnum._('ok');
const V1SummaryGet200ResponseCategoriesInnerStateEnum
_$v1SummaryGet200ResponseCategoriesInnerStateEnum_near =
    const V1SummaryGet200ResponseCategoriesInnerStateEnum._('near');
const V1SummaryGet200ResponseCategoriesInnerStateEnum
_$v1SummaryGet200ResponseCategoriesInnerStateEnum_over =
    const V1SummaryGet200ResponseCategoriesInnerStateEnum._('over');

V1SummaryGet200ResponseCategoriesInnerStateEnum
_$v1SummaryGet200ResponseCategoriesInnerStateEnumValueOf(String name) {
  switch (name) {
    case 'ok':
      return _$v1SummaryGet200ResponseCategoriesInnerStateEnum_ok;
    case 'near':
      return _$v1SummaryGet200ResponseCategoriesInnerStateEnum_near;
    case 'over':
      return _$v1SummaryGet200ResponseCategoriesInnerStateEnum_over;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1SummaryGet200ResponseCategoriesInnerStateEnum>
_$v1SummaryGet200ResponseCategoriesInnerStateEnumValues =
    BuiltSet<V1SummaryGet200ResponseCategoriesInnerStateEnum>(
      const <V1SummaryGet200ResponseCategoriesInnerStateEnum>[
        _$v1SummaryGet200ResponseCategoriesInnerStateEnum_ok,
        _$v1SummaryGet200ResponseCategoriesInnerStateEnum_near,
        _$v1SummaryGet200ResponseCategoriesInnerStateEnum_over,
      ],
    );

Serializer<V1SummaryGet200ResponseCategoriesInnerStateEnum>
_$v1SummaryGet200ResponseCategoriesInnerStateEnumSerializer =
    _$V1SummaryGet200ResponseCategoriesInnerStateEnumSerializer();

class _$V1SummaryGet200ResponseCategoriesInnerStateEnumSerializer
    implements PrimitiveSerializer<V1SummaryGet200ResponseCategoriesInnerStateEnum> {
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
  final Iterable<Type> types = const <Type>[V1SummaryGet200ResponseCategoriesInnerStateEnum];
  @override
  final String wireName = 'V1SummaryGet200ResponseCategoriesInnerStateEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1SummaryGet200ResponseCategoriesInnerStateEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1SummaryGet200ResponseCategoriesInnerStateEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1SummaryGet200ResponseCategoriesInnerStateEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1SummaryGet200ResponseCategoriesInner extends V1SummaryGet200ResponseCategoriesInner {
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
  final V1SummaryGet200ResponseCategoriesInnerStateEnum state;

  factory _$V1SummaryGet200ResponseCategoriesInner([
    void Function(V1SummaryGet200ResponseCategoriesInnerBuilder)? updates,
  ]) => (V1SummaryGet200ResponseCategoriesInnerBuilder()..update(updates))._build();

  _$V1SummaryGet200ResponseCategoriesInner._({
    required this.categoryId,
    this.budget,
    required this.spent,
    this.remaining,
    this.ratio,
    required this.state,
  }) : super._();
  @override
  V1SummaryGet200ResponseCategoriesInner rebuild(
    void Function(V1SummaryGet200ResponseCategoriesInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1SummaryGet200ResponseCategoriesInnerBuilder toBuilder() =>
      V1SummaryGet200ResponseCategoriesInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1SummaryGet200ResponseCategoriesInner &&
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
    return (newBuiltValueToStringHelper(r'V1SummaryGet200ResponseCategoriesInner')
          ..add('categoryId', categoryId)
          ..add('budget', budget)
          ..add('spent', spent)
          ..add('remaining', remaining)
          ..add('ratio', ratio)
          ..add('state', state))
        .toString();
  }
}

class V1SummaryGet200ResponseCategoriesInnerBuilder
    implements
        Builder<
          V1SummaryGet200ResponseCategoriesInner,
          V1SummaryGet200ResponseCategoriesInnerBuilder
        > {
  _$V1SummaryGet200ResponseCategoriesInner? _$v;

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

  V1SummaryGet200ResponseCategoriesInnerStateEnum? _state;
  V1SummaryGet200ResponseCategoriesInnerStateEnum? get state => _$this._state;
  set state(V1SummaryGet200ResponseCategoriesInnerStateEnum? state) => _$this._state = state;

  V1SummaryGet200ResponseCategoriesInnerBuilder() {
    V1SummaryGet200ResponseCategoriesInner._defaults(this);
  }

  V1SummaryGet200ResponseCategoriesInnerBuilder get _$this {
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
  void replace(V1SummaryGet200ResponseCategoriesInner other) {
    _$v = other as _$V1SummaryGet200ResponseCategoriesInner;
  }

  @override
  void update(void Function(V1SummaryGet200ResponseCategoriesInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1SummaryGet200ResponseCategoriesInner build() => _build();

  _$V1SummaryGet200ResponseCategoriesInner _build() {
    final _$result =
        _$v ??
        _$V1SummaryGet200ResponseCategoriesInner._(
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1SummaryGet200ResponseCategoriesInner',
            'categoryId',
          ),
          budget: budget,
          spent: BuiltValueNullFieldError.checkNotNull(
            spent,
            r'V1SummaryGet200ResponseCategoriesInner',
            'spent',
          ),
          remaining: remaining,
          ratio: ratio,
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'V1SummaryGet200ResponseCategoriesInner',
            'state',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
