// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_categories_get200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1CategoriesGet200ResponseInnerKindEnum _$v1CategoriesGet200ResponseInnerKindEnum_expense =
    const V1CategoriesGet200ResponseInnerKindEnum._('expense');
const V1CategoriesGet200ResponseInnerKindEnum _$v1CategoriesGet200ResponseInnerKindEnum_income =
    const V1CategoriesGet200ResponseInnerKindEnum._('income');

V1CategoriesGet200ResponseInnerKindEnum _$v1CategoriesGet200ResponseInnerKindEnumValueOf(
  String name,
) {
  switch (name) {
    case 'expense':
      return _$v1CategoriesGet200ResponseInnerKindEnum_expense;
    case 'income':
      return _$v1CategoriesGet200ResponseInnerKindEnum_income;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1CategoriesGet200ResponseInnerKindEnum>
_$v1CategoriesGet200ResponseInnerKindEnumValues = BuiltSet<V1CategoriesGet200ResponseInnerKindEnum>(
  const <V1CategoriesGet200ResponseInnerKindEnum>[
    _$v1CategoriesGet200ResponseInnerKindEnum_expense,
    _$v1CategoriesGet200ResponseInnerKindEnum_income,
  ],
);

Serializer<V1CategoriesGet200ResponseInnerKindEnum>
_$v1CategoriesGet200ResponseInnerKindEnumSerializer =
    _$V1CategoriesGet200ResponseInnerKindEnumSerializer();

class _$V1CategoriesGet200ResponseInnerKindEnumSerializer
    implements PrimitiveSerializer<V1CategoriesGet200ResponseInnerKindEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expense': 'expense',
    'income': 'income',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'expense': 'expense',
    'income': 'income',
  };

  @override
  final Iterable<Type> types = const <Type>[V1CategoriesGet200ResponseInnerKindEnum];
  @override
  final String wireName = 'V1CategoriesGet200ResponseInnerKindEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1CategoriesGet200ResponseInnerKindEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1CategoriesGet200ResponseInnerKindEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1CategoriesGet200ResponseInnerKindEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1CategoriesGet200ResponseInner extends V1CategoriesGet200ResponseInner {
  @override
  final String id;
  @override
  final String name;
  @override
  final V1CategoriesGet200ResponseInnerKindEnum kind;
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

  factory _$V1CategoriesGet200ResponseInner([
    void Function(V1CategoriesGet200ResponseInnerBuilder)? updates,
  ]) => (V1CategoriesGet200ResponseInnerBuilder()..update(updates))._build();

  _$V1CategoriesGet200ResponseInner._({
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
  V1CategoriesGet200ResponseInner rebuild(
    void Function(V1CategoriesGet200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1CategoriesGet200ResponseInnerBuilder toBuilder() =>
      V1CategoriesGet200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1CategoriesGet200ResponseInner &&
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
    return (newBuiltValueToStringHelper(r'V1CategoriesGet200ResponseInner')
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

class V1CategoriesGet200ResponseInnerBuilder
    implements Builder<V1CategoriesGet200ResponseInner, V1CategoriesGet200ResponseInnerBuilder> {
  _$V1CategoriesGet200ResponseInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  V1CategoriesGet200ResponseInnerKindEnum? _kind;
  V1CategoriesGet200ResponseInnerKindEnum? get kind => _$this._kind;
  set kind(V1CategoriesGet200ResponseInnerKindEnum? kind) => _$this._kind = kind;

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

  V1CategoriesGet200ResponseInnerBuilder() {
    V1CategoriesGet200ResponseInner._defaults(this);
  }

  V1CategoriesGet200ResponseInnerBuilder get _$this {
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
  void replace(V1CategoriesGet200ResponseInner other) {
    _$v = other as _$V1CategoriesGet200ResponseInner;
  }

  @override
  void update(void Function(V1CategoriesGet200ResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1CategoriesGet200ResponseInner build() => _build();

  _$V1CategoriesGet200ResponseInner _build() {
    final _$result =
        _$v ??
        _$V1CategoriesGet200ResponseInner._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'V1CategoriesGet200ResponseInner', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'V1CategoriesGet200ResponseInner',
            'name',
          ),
          kind: BuiltValueNullFieldError.checkNotNull(
            kind,
            r'V1CategoriesGet200ResponseInner',
            'kind',
          ),
          icon: BuiltValueNullFieldError.checkNotNull(
            icon,
            r'V1CategoriesGet200ResponseInner',
            'icon',
          ),
          color: BuiltValueNullFieldError.checkNotNull(
            color,
            r'V1CategoriesGet200ResponseInner',
            'color',
          ),
          sortOrder: BuiltValueNullFieldError.checkNotNull(
            sortOrder,
            r'V1CategoriesGet200ResponseInner',
            'sortOrder',
          ),
          archived: BuiltValueNullFieldError.checkNotNull(
            archived,
            r'V1CategoriesGet200ResponseInner',
            'archived',
          ),
          currentBudget: currentBudget,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
