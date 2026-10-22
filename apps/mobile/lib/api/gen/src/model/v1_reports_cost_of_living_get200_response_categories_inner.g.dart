// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_reports_cost_of_living_get200_response_categories_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum
_$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_fixed =
    const V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum._('fixed');
const V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum
_$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_variable =
    const V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum._('variable');

V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum
_$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumValueOf(String name) {
  switch (name) {
    case 'fixed':
      return _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_fixed;
    case 'variable':
      return _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_variable;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum>
_$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumValues =
    BuiltSet<V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum>(
      const <V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum>[
        _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_fixed,
        _$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum_variable,
      ],
    );

Serializer<V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum>
_$v1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumSerializer =
    _$V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumSerializer();

class _$V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnumSerializer
    implements PrimitiveSerializer<V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'fixed': 'fixed',
    'variable': 'variable',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'fixed': 'fixed',
    'variable': 'variable',
  };

  @override
  final Iterable<Type> types = const <Type>[
    V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum,
  ];
  @override
  final String wireName = 'V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1ReportsCostOfLivingGet200ResponseCategoriesInner
    extends V1ReportsCostOfLivingGet200ResponseCategoriesInner {
  @override
  final String categoryId;
  @override
  final int average;
  @override
  final V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum type;

  factory _$V1ReportsCostOfLivingGet200ResponseCategoriesInner([
    void Function(V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder)? updates,
  ]) => (V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder()..update(updates))._build();

  _$V1ReportsCostOfLivingGet200ResponseCategoriesInner._({
    required this.categoryId,
    required this.average,
    required this.type,
  }) : super._();
  @override
  V1ReportsCostOfLivingGet200ResponseCategoriesInner rebuild(
    void Function(V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder toBuilder() =>
      V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ReportsCostOfLivingGet200ResponseCategoriesInner &&
        categoryId == other.categoryId &&
        average == other.average &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, average.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1ReportsCostOfLivingGet200ResponseCategoriesInner')
          ..add('categoryId', categoryId)
          ..add('average', average)
          ..add('type', type))
        .toString();
  }
}

class V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder
    implements
        Builder<
          V1ReportsCostOfLivingGet200ResponseCategoriesInner,
          V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder
        > {
  _$V1ReportsCostOfLivingGet200ResponseCategoriesInner? _$v;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  int? _average;
  int? get average => _$this._average;
  set average(int? average) => _$this._average = average;

  V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum? _type;
  V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum? get type => _$this._type;
  set type(V1ReportsCostOfLivingGet200ResponseCategoriesInnerTypeEnum? type) => _$this._type = type;

  V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder() {
    V1ReportsCostOfLivingGet200ResponseCategoriesInner._defaults(this);
  }

  V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categoryId = $v.categoryId;
      _average = $v.average;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1ReportsCostOfLivingGet200ResponseCategoriesInner other) {
    _$v = other as _$V1ReportsCostOfLivingGet200ResponseCategoriesInner;
  }

  @override
  void update(void Function(V1ReportsCostOfLivingGet200ResponseCategoriesInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ReportsCostOfLivingGet200ResponseCategoriesInner build() => _build();

  _$V1ReportsCostOfLivingGet200ResponseCategoriesInner _build() {
    final _$result =
        _$v ??
        _$V1ReportsCostOfLivingGet200ResponseCategoriesInner._(
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1ReportsCostOfLivingGet200ResponseCategoriesInner',
            'categoryId',
          ),
          average: BuiltValueNullFieldError.checkNotNull(
            average,
            r'V1ReportsCostOfLivingGet200ResponseCategoriesInner',
            'average',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'V1ReportsCostOfLivingGet200ResponseCategoriesInner',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
