// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateCategoryKindEnum _$updateCategoryKindEnum_expense = const UpdateCategoryKindEnum._(
  'expense',
);
const UpdateCategoryKindEnum _$updateCategoryKindEnum_income = const UpdateCategoryKindEnum._(
  'income',
);

UpdateCategoryKindEnum _$updateCategoryKindEnumValueOf(String name) {
  switch (name) {
    case 'expense':
      return _$updateCategoryKindEnum_expense;
    case 'income':
      return _$updateCategoryKindEnum_income;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateCategoryKindEnum> _$updateCategoryKindEnumValues =
    BuiltSet<UpdateCategoryKindEnum>(const <UpdateCategoryKindEnum>[
      _$updateCategoryKindEnum_expense,
      _$updateCategoryKindEnum_income,
    ]);

Serializer<UpdateCategoryKindEnum> _$updateCategoryKindEnumSerializer =
    _$UpdateCategoryKindEnumSerializer();

class _$UpdateCategoryKindEnumSerializer implements PrimitiveSerializer<UpdateCategoryKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expense': 'expense',
    'income': 'income',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'expense': 'expense',
    'income': 'income',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateCategoryKindEnum];
  @override
  final String wireName = 'UpdateCategoryKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateCategoryKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateCategoryKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateCategoryKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateCategory extends UpdateCategory {
  @override
  final String? name;
  @override
  final String? icon;
  @override
  final String? color;
  @override
  final int? sortOrder;
  @override
  final UpdateCategoryKindEnum? kind;
  @override
  final bool? archived;

  factory _$UpdateCategory([void Function(UpdateCategoryBuilder)? updates]) =>
      (UpdateCategoryBuilder()..update(updates))._build();

  _$UpdateCategory._({this.name, this.icon, this.color, this.sortOrder, this.kind, this.archived})
    : super._();
  @override
  UpdateCategory rebuild(void Function(UpdateCategoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateCategoryBuilder toBuilder() => UpdateCategoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateCategory &&
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
    return (newBuiltValueToStringHelper(r'UpdateCategory')
          ..add('name', name)
          ..add('icon', icon)
          ..add('color', color)
          ..add('sortOrder', sortOrder)
          ..add('kind', kind)
          ..add('archived', archived))
        .toString();
  }
}

class UpdateCategoryBuilder implements Builder<UpdateCategory, UpdateCategoryBuilder> {
  _$UpdateCategory? _$v;

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

  UpdateCategoryKindEnum? _kind;
  UpdateCategoryKindEnum? get kind => _$this._kind;
  set kind(UpdateCategoryKindEnum? kind) => _$this._kind = kind;

  bool? _archived;
  bool? get archived => _$this._archived;
  set archived(bool? archived) => _$this._archived = archived;

  UpdateCategoryBuilder() {
    UpdateCategory._defaults(this);
  }

  UpdateCategoryBuilder get _$this {
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
  void replace(UpdateCategory other) {
    _$v = other as _$UpdateCategory;
  }

  @override
  void update(void Function(UpdateCategoryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateCategory build() => _build();

  _$UpdateCategory _build() {
    final _$result =
        _$v ??
        _$UpdateCategory._(
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
