// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_categories_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1CategoriesPostRequestKindEnum _$v1CategoriesPostRequestKindEnum_expense =
    const V1CategoriesPostRequestKindEnum._('expense');
const V1CategoriesPostRequestKindEnum _$v1CategoriesPostRequestKindEnum_income =
    const V1CategoriesPostRequestKindEnum._('income');

V1CategoriesPostRequestKindEnum _$v1CategoriesPostRequestKindEnumValueOf(String name) {
  switch (name) {
    case 'expense':
      return _$v1CategoriesPostRequestKindEnum_expense;
    case 'income':
      return _$v1CategoriesPostRequestKindEnum_income;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1CategoriesPostRequestKindEnum> _$v1CategoriesPostRequestKindEnumValues =
    BuiltSet<V1CategoriesPostRequestKindEnum>(const <V1CategoriesPostRequestKindEnum>[
      _$v1CategoriesPostRequestKindEnum_expense,
      _$v1CategoriesPostRequestKindEnum_income,
    ]);

Serializer<V1CategoriesPostRequestKindEnum> _$v1CategoriesPostRequestKindEnumSerializer =
    _$V1CategoriesPostRequestKindEnumSerializer();

class _$V1CategoriesPostRequestKindEnumSerializer
    implements PrimitiveSerializer<V1CategoriesPostRequestKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expense': 'expense',
    'income': 'income',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'expense': 'expense',
    'income': 'income',
  };

  @override
  final Iterable<Type> types = const <Type>[V1CategoriesPostRequestKindEnum];
  @override
  final String wireName = 'V1CategoriesPostRequestKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1CategoriesPostRequestKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1CategoriesPostRequestKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1CategoriesPostRequestKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1CategoriesPostRequest extends V1CategoriesPostRequest {
  @override
  final String name;
  @override
  final String icon;
  @override
  final String color;
  @override
  final int? sortOrder;
  @override
  final V1CategoriesPostRequestKindEnum kind;

  factory _$V1CategoriesPostRequest([void Function(V1CategoriesPostRequestBuilder)? updates]) =>
      (V1CategoriesPostRequestBuilder()..update(updates))._build();

  _$V1CategoriesPostRequest._({
    required this.name,
    required this.icon,
    required this.color,
    this.sortOrder,
    required this.kind,
  }) : super._();
  @override
  V1CategoriesPostRequest rebuild(void Function(V1CategoriesPostRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1CategoriesPostRequestBuilder toBuilder() => V1CategoriesPostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1CategoriesPostRequest &&
        name == other.name &&
        icon == other.icon &&
        color == other.color &&
        sortOrder == other.sortOrder &&
        kind == other.kind;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, icon.hashCode);
    _$hash = $jc(_$hash, color.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1CategoriesPostRequest')
          ..add('name', name)
          ..add('icon', icon)
          ..add('color', color)
          ..add('sortOrder', sortOrder)
          ..add('kind', kind))
        .toString();
  }
}

class V1CategoriesPostRequestBuilder
    implements Builder<V1CategoriesPostRequest, V1CategoriesPostRequestBuilder> {
  _$V1CategoriesPostRequest? _$v;

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

  V1CategoriesPostRequestKindEnum? _kind;
  V1CategoriesPostRequestKindEnum? get kind => _$this._kind;
  set kind(V1CategoriesPostRequestKindEnum? kind) => _$this._kind = kind;

  V1CategoriesPostRequestBuilder() {
    V1CategoriesPostRequest._defaults(this);
  }

  V1CategoriesPostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _icon = $v.icon;
      _color = $v.color;
      _sortOrder = $v.sortOrder;
      _kind = $v.kind;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1CategoriesPostRequest other) {
    _$v = other as _$V1CategoriesPostRequest;
  }

  @override
  void update(void Function(V1CategoriesPostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1CategoriesPostRequest build() => _build();

  _$V1CategoriesPostRequest _build() {
    final _$result =
        _$v ??
        _$V1CategoriesPostRequest._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'V1CategoriesPostRequest', 'name'),
          icon: BuiltValueNullFieldError.checkNotNull(icon, r'V1CategoriesPostRequest', 'icon'),
          color: BuiltValueNullFieldError.checkNotNull(color, r'V1CategoriesPostRequest', 'color'),
          sortOrder: sortOrder,
          kind: BuiltValueNullFieldError.checkNotNull(kind, r'V1CategoriesPostRequest', 'kind'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
