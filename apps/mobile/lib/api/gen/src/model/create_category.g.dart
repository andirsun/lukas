// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateCategoryKindEnum _$createCategoryKindEnum_expense = const CreateCategoryKindEnum._(
  'expense',
);
const CreateCategoryKindEnum _$createCategoryKindEnum_income = const CreateCategoryKindEnum._(
  'income',
);

CreateCategoryKindEnum _$createCategoryKindEnumValueOf(String name) {
  switch (name) {
    case 'expense':
      return _$createCategoryKindEnum_expense;
    case 'income':
      return _$createCategoryKindEnum_income;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateCategoryKindEnum> _$createCategoryKindEnumValues =
    BuiltSet<CreateCategoryKindEnum>(const <CreateCategoryKindEnum>[
      _$createCategoryKindEnum_expense,
      _$createCategoryKindEnum_income,
    ]);

Serializer<CreateCategoryKindEnum> _$createCategoryKindEnumSerializer =
    _$CreateCategoryKindEnumSerializer();

class _$CreateCategoryKindEnumSerializer implements PrimitiveSerializer<CreateCategoryKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expense': 'expense',
    'income': 'income',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'expense': 'expense',
    'income': 'income',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateCategoryKindEnum];
  @override
  final String wireName = 'CreateCategoryKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateCategoryKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateCategoryKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateCategoryKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateCategory extends CreateCategory {
  @override
  final String name;
  @override
  final String icon;
  @override
  final String color;
  @override
  final int? sortOrder;
  @override
  final CreateCategoryKindEnum kind;

  factory _$CreateCategory([void Function(CreateCategoryBuilder)? updates]) =>
      (CreateCategoryBuilder()..update(updates))._build();

  _$CreateCategory._({
    required this.name,
    required this.icon,
    required this.color,
    this.sortOrder,
    required this.kind,
  }) : super._();
  @override
  CreateCategory rebuild(void Function(CreateCategoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateCategoryBuilder toBuilder() => CreateCategoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateCategory &&
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
    return (newBuiltValueToStringHelper(r'CreateCategory')
          ..add('name', name)
          ..add('icon', icon)
          ..add('color', color)
          ..add('sortOrder', sortOrder)
          ..add('kind', kind))
        .toString();
  }
}

class CreateCategoryBuilder implements Builder<CreateCategory, CreateCategoryBuilder> {
  _$CreateCategory? _$v;

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

  CreateCategoryKindEnum? _kind;
  CreateCategoryKindEnum? get kind => _$this._kind;
  set kind(CreateCategoryKindEnum? kind) => _$this._kind = kind;

  CreateCategoryBuilder() {
    CreateCategory._defaults(this);
  }

  CreateCategoryBuilder get _$this {
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
  void replace(CreateCategory other) {
    _$v = other as _$CreateCategory;
  }

  @override
  void update(void Function(CreateCategoryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateCategory build() => _build();

  _$CreateCategory _build() {
    final _$result =
        _$v ??
        _$CreateCategory._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'CreateCategory', 'name'),
          icon: BuiltValueNullFieldError.checkNotNull(icon, r'CreateCategory', 'icon'),
          color: BuiltValueNullFieldError.checkNotNull(color, r'CreateCategory', 'color'),
          sortOrder: sortOrder,
          kind: BuiltValueNullFieldError.checkNotNull(kind, r'CreateCategory', 'kind'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
