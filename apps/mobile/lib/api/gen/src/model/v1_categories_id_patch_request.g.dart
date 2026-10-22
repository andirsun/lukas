// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_categories_id_patch_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1CategoriesIdPatchRequestKindEnum _$v1CategoriesIdPatchRequestKindEnum_expense =
    const V1CategoriesIdPatchRequestKindEnum._('expense');
const V1CategoriesIdPatchRequestKindEnum _$v1CategoriesIdPatchRequestKindEnum_income =
    const V1CategoriesIdPatchRequestKindEnum._('income');

V1CategoriesIdPatchRequestKindEnum _$v1CategoriesIdPatchRequestKindEnumValueOf(String name) {
  switch (name) {
    case 'expense':
      return _$v1CategoriesIdPatchRequestKindEnum_expense;
    case 'income':
      return _$v1CategoriesIdPatchRequestKindEnum_income;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1CategoriesIdPatchRequestKindEnum> _$v1CategoriesIdPatchRequestKindEnumValues =
    BuiltSet<V1CategoriesIdPatchRequestKindEnum>(const <V1CategoriesIdPatchRequestKindEnum>[
      _$v1CategoriesIdPatchRequestKindEnum_expense,
      _$v1CategoriesIdPatchRequestKindEnum_income,
    ]);

Serializer<V1CategoriesIdPatchRequestKindEnum> _$v1CategoriesIdPatchRequestKindEnumSerializer =
    _$V1CategoriesIdPatchRequestKindEnumSerializer();

class _$V1CategoriesIdPatchRequestKindEnumSerializer
    implements PrimitiveSerializer<V1CategoriesIdPatchRequestKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expense': 'expense',
    'income': 'income',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'expense': 'expense',
    'income': 'income',
  };

  @override
  final Iterable<Type> types = const <Type>[V1CategoriesIdPatchRequestKindEnum];
  @override
  final String wireName = 'V1CategoriesIdPatchRequestKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1CategoriesIdPatchRequestKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1CategoriesIdPatchRequestKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1CategoriesIdPatchRequestKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1CategoriesIdPatchRequest extends V1CategoriesIdPatchRequest {
  @override
  final String? name;
  @override
  final String? icon;
  @override
  final String? color;
  @override
  final int? sortOrder;
  @override
  final V1CategoriesIdPatchRequestKindEnum? kind;
  @override
  final bool? archived;

  factory _$V1CategoriesIdPatchRequest([
    void Function(V1CategoriesIdPatchRequestBuilder)? updates,
  ]) => (V1CategoriesIdPatchRequestBuilder()..update(updates))._build();

  _$V1CategoriesIdPatchRequest._({
    this.name,
    this.icon,
    this.color,
    this.sortOrder,
    this.kind,
    this.archived,
  }) : super._();
  @override
  V1CategoriesIdPatchRequest rebuild(void Function(V1CategoriesIdPatchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1CategoriesIdPatchRequestBuilder toBuilder() =>
      V1CategoriesIdPatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1CategoriesIdPatchRequest &&
        name == other.name &&
        icon == other.icon &&
        color == other.color &&
        sortOrder == other.sortOrder &&
        kind == other.kind &&
        archived == other.archived;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, icon.hashCode);
    _$hash = $jc(_$hash, color.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, archived.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1CategoriesIdPatchRequest')
          ..add('name', name)
          ..add('icon', icon)
          ..add('color', color)
          ..add('sortOrder', sortOrder)
          ..add('kind', kind)
          ..add('archived', archived))
        .toString();
  }
}

class V1CategoriesIdPatchRequestBuilder
    implements Builder<V1CategoriesIdPatchRequest, V1CategoriesIdPatchRequestBuilder> {
  _$V1CategoriesIdPatchRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _icon;
  String? get icon => _$this._icon;
  set icon(String? icon) => _$this._icon = icon;

  String? _color;
  String? get color => _$this._color;
  set color(String? color) => _$this._color = color;

  int? _sortOrder;
  int? get sortOrder => _$this._sortOrder;
  set sortOrder(int? sortOrder) => _$this._sortOrder = sortOrder;

  V1CategoriesIdPatchRequestKindEnum? _kind;
  V1CategoriesIdPatchRequestKindEnum? get kind => _$this._kind;
  set kind(V1CategoriesIdPatchRequestKindEnum? kind) => _$this._kind = kind;

  bool? _archived;
  bool? get archived => _$this._archived;
  set archived(bool? archived) => _$this._archived = archived;

  V1CategoriesIdPatchRequestBuilder() {
    V1CategoriesIdPatchRequest._defaults(this);
  }

  V1CategoriesIdPatchRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _icon = $v.icon;
      _color = $v.color;
      _sortOrder = $v.sortOrder;
      _kind = $v.kind;
      _archived = $v.archived;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1CategoriesIdPatchRequest other) {
    _$v = other as _$V1CategoriesIdPatchRequest;
  }

  @override
  void update(void Function(V1CategoriesIdPatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1CategoriesIdPatchRequest build() => _build();

  _$V1CategoriesIdPatchRequest _build() {
    final _$result =
        _$v ??
        _$V1CategoriesIdPatchRequest._(
          name: name,
          icon: icon,
          color: color,
          sortOrder: sortOrder,
          kind: kind,
          archived: archived,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
