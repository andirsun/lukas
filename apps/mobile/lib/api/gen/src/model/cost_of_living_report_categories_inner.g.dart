// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_of_living_report_categories_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CostOfLivingReportCategoriesInnerTypeEnum _$costOfLivingReportCategoriesInnerTypeEnum_fixed =
    const CostOfLivingReportCategoriesInnerTypeEnum._('fixed');
const CostOfLivingReportCategoriesInnerTypeEnum
_$costOfLivingReportCategoriesInnerTypeEnum_variable =
    const CostOfLivingReportCategoriesInnerTypeEnum._('variable');

CostOfLivingReportCategoriesInnerTypeEnum _$costOfLivingReportCategoriesInnerTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'fixed':
      return _$costOfLivingReportCategoriesInnerTypeEnum_fixed;
    case 'variable':
      return _$costOfLivingReportCategoriesInnerTypeEnum_variable;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CostOfLivingReportCategoriesInnerTypeEnum>
_$costOfLivingReportCategoriesInnerTypeEnumValues =
    BuiltSet<CostOfLivingReportCategoriesInnerTypeEnum>(
      const <CostOfLivingReportCategoriesInnerTypeEnum>[
        _$costOfLivingReportCategoriesInnerTypeEnum_fixed,
        _$costOfLivingReportCategoriesInnerTypeEnum_variable,
      ],
    );

Serializer<CostOfLivingReportCategoriesInnerTypeEnum>
_$costOfLivingReportCategoriesInnerTypeEnumSerializer =
    _$CostOfLivingReportCategoriesInnerTypeEnumSerializer();

class _$CostOfLivingReportCategoriesInnerTypeEnumSerializer
    implements PrimitiveSerializer<CostOfLivingReportCategoriesInnerTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'fixed': 'fixed',
    'variable': 'variable',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'fixed': 'fixed',
    'variable': 'variable',
  };

  @override
  final Iterable<Type> types = const <Type>[CostOfLivingReportCategoriesInnerTypeEnum];
  @override
  final String wireName = 'CostOfLivingReportCategoriesInnerTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    CostOfLivingReportCategoriesInnerTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CostOfLivingReportCategoriesInnerTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CostOfLivingReportCategoriesInnerTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CostOfLivingReportCategoriesInner extends CostOfLivingReportCategoriesInner {
  @override
  final String categoryId;
  @override
  final int average;
  @override
  final CostOfLivingReportCategoriesInnerTypeEnum type;

  factory _$CostOfLivingReportCategoriesInner([
    void Function(CostOfLivingReportCategoriesInnerBuilder)? updates,
  ]) => (CostOfLivingReportCategoriesInnerBuilder()..update(updates))._build();

  _$CostOfLivingReportCategoriesInner._({
    required this.categoryId,
    required this.average,
    required this.type,
  }) : super._();
  @override
  CostOfLivingReportCategoriesInner rebuild(
    void Function(CostOfLivingReportCategoriesInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CostOfLivingReportCategoriesInnerBuilder toBuilder() =>
      CostOfLivingReportCategoriesInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CostOfLivingReportCategoriesInner &&
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
    return (newBuiltValueToStringHelper(r'CostOfLivingReportCategoriesInner')
          ..add('categoryId', categoryId)
          ..add('average', average)
          ..add('type', type))
        .toString();
  }
}

class CostOfLivingReportCategoriesInnerBuilder
    implements
        Builder<CostOfLivingReportCategoriesInner, CostOfLivingReportCategoriesInnerBuilder> {
  _$CostOfLivingReportCategoriesInner? _$v;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  int? _average;
  int? get average => _$this._average;
  set average(int? average) => _$this._average = average;

  CostOfLivingReportCategoriesInnerTypeEnum? _type;
  CostOfLivingReportCategoriesInnerTypeEnum? get type => _$this._type;
  set type(CostOfLivingReportCategoriesInnerTypeEnum? type) => _$this._type = type;

  CostOfLivingReportCategoriesInnerBuilder() {
    CostOfLivingReportCategoriesInner._defaults(this);
  }

  CostOfLivingReportCategoriesInnerBuilder get _$this {
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
  void replace(CostOfLivingReportCategoriesInner other) {
    _$v = other as _$CostOfLivingReportCategoriesInner;
  }

  @override
  void update(void Function(CostOfLivingReportCategoriesInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CostOfLivingReportCategoriesInner build() => _build();

  _$CostOfLivingReportCategoriesInner _build() {
    final _$result =
        _$v ??
        _$CostOfLivingReportCategoriesInner._(
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'CostOfLivingReportCategoriesInner',
            'categoryId',
          ),
          average: BuiltValueNullFieldError.checkNotNull(
            average,
            r'CostOfLivingReportCategoriesInner',
            'average',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'CostOfLivingReportCategoriesInner',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
