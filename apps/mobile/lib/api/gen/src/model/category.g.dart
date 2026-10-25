// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CategoryKindEnum _$categoryKindEnum_expense = const CategoryKindEnum._('expense');
const CategoryKindEnum _$categoryKindEnum_income = const CategoryKindEnum._('income');

CategoryKindEnum _$categoryKindEnumValueOf(String name) {
  switch (name) {
    case 'expense':
      return _$categoryKindEnum_expense;
    case 'income':
      return _$categoryKindEnum_income;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CategoryKindEnum> _$categoryKindEnumValues = BuiltSet<CategoryKindEnum>(
  const <CategoryKindEnum>[_$categoryKindEnum_expense, _$categoryKindEnum_income],
);

Serializer<CategoryKindEnum> _$categoryKindEnumSerializer = _$CategoryKindEnumSerializer();

class _$CategoryKindEnumSerializer implements PrimitiveSerializer<CategoryKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expense': 'expense',
    'income': 'income',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'expense': 'expense',
    'income': 'income',
  };

  @override
  final Iterable<Type> types = const <Type>[CategoryKindEnum];
  @override
  final String wireName = 'CategoryKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    CategoryKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CategoryKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CategoryKindEnum.valueOf(_fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$Category extends Category {
  @override
  final String id;
  @override
  final String name;
  @override
  final CategoryKindEnum kind;
  @override
  final String icon;
  @override
  final String color;
  @override
  final int sortOrder;
  @override
  final bool archived;
  @override
  final int? currentBudget;

  factory _$Category([void Function(CategoryBuilder)? updates]) =>
      (CategoryBuilder()..update(updates))._build();

  _$Category._({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.archived,
    this.currentBudget,
  }) : super._();
  @override
  Category rebuild(void Function(CategoryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CategoryBuilder toBuilder() => CategoryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Category &&
        id == other.id &&
        name == other.name &&
        kind == other.kind &&
        icon == other.icon &&
        color == other.color &&
        sortOrder == other.sortOrder &&
        archived == other.archived &&
        currentBudget == other.currentBudget;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, kind.hashCode);
    _$hash = $jc(_$hash, icon.hashCode);
    _$hash = $jc(_$hash, color.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, archived.hashCode);
    _$hash = $jc(_$hash, currentBudget.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Category')
          ..add('id', id)
          ..add('name', name)
          ..add('kind', kind)
          ..add('icon', icon)
          ..add('color', color)
          ..add('sortOrder', sortOrder)
          ..add('archived', archived)
          ..add('currentBudget', currentBudget))
        .toString();
  }
}

class CategoryBuilder implements Builder<Category, CategoryBuilder> {
  _$Category? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  CategoryKindEnum? _kind;
  CategoryKindEnum? get kind => _$this._kind;
  set kind(CategoryKindEnum? kind) => _$this._kind = kind;

  String? _icon;
  String? get icon => _$this._icon;
  set icon(String? icon) => _$this._icon = icon;

  String? _color;
  String? get color => _$this._color;
  set color(String? color) => _$this._color = color;

  int? _sortOrder;
  int? get sortOrder => _$this._sortOrder;
  set sortOrder(int? sortOrder) => _$this._sortOrder = sortOrder;

  bool? _archived;
  bool? get archived => _$this._archived;
  set archived(bool? archived) => _$this._archived = archived;

  int? _currentBudget;
  int? get currentBudget => _$this._currentBudget;
  set currentBudget(int? currentBudget) => _$this._currentBudget = currentBudget;

  CategoryBuilder() {
    Category._defaults(this);
  }

  CategoryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _kind = $v.kind;
      _icon = $v.icon;
      _color = $v.color;
      _sortOrder = $v.sortOrder;
      _archived = $v.archived;
      _currentBudget = $v.currentBudget;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Category other) {
    _$v = other as _$Category;
  }

  @override
  void update(void Function(CategoryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Category build() => _build();

  _$Category _build() {
    final _$result =
        _$v ??
        _$Category._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Category', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Category', 'name'),
          kind: BuiltValueNullFieldError.checkNotNull(kind, r'Category', 'kind'),
          icon: BuiltValueNullFieldError.checkNotNull(icon, r'Category', 'icon'),
          color: BuiltValueNullFieldError.checkNotNull(color, r'Category', 'color'),
          sortOrder: BuiltValueNullFieldError.checkNotNull(sortOrder, r'Category', 'sortOrder'),
          archived: BuiltValueNullFieldError.checkNotNull(archived, r'Category', 'archived'),
          currentBudget: currentBudget,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
