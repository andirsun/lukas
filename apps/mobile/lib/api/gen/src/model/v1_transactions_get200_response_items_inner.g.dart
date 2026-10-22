// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_get200_response_items_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1TransactionsGet200ResponseItemsInnerStatusEnum
_$v1TransactionsGet200ResponseItemsInnerStatusEnum_paid =
    const V1TransactionsGet200ResponseItemsInnerStatusEnum._('paid');
const V1TransactionsGet200ResponseItemsInnerStatusEnum
_$v1TransactionsGet200ResponseItemsInnerStatusEnum_pending =
    const V1TransactionsGet200ResponseItemsInnerStatusEnum._('pending');

V1TransactionsGet200ResponseItemsInnerStatusEnum
_$v1TransactionsGet200ResponseItemsInnerStatusEnumValueOf(String name) {
  switch (name) {
    case 'paid':
      return _$v1TransactionsGet200ResponseItemsInnerStatusEnum_paid;
    case 'pending':
      return _$v1TransactionsGet200ResponseItemsInnerStatusEnum_pending;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1TransactionsGet200ResponseItemsInnerStatusEnum>
_$v1TransactionsGet200ResponseItemsInnerStatusEnumValues =
    BuiltSet<V1TransactionsGet200ResponseItemsInnerStatusEnum>(
      const <V1TransactionsGet200ResponseItemsInnerStatusEnum>[
        _$v1TransactionsGet200ResponseItemsInnerStatusEnum_paid,
        _$v1TransactionsGet200ResponseItemsInnerStatusEnum_pending,
      ],
    );

const V1TransactionsGet200ResponseItemsInnerSource_Enum
_$v1TransactionsGet200ResponseItemsInnerSourceEnum_app =
    const V1TransactionsGet200ResponseItemsInnerSource_Enum._('app');
const V1TransactionsGet200ResponseItemsInnerSource_Enum
_$v1TransactionsGet200ResponseItemsInnerSourceEnum_web =
    const V1TransactionsGet200ResponseItemsInnerSource_Enum._('web');
const V1TransactionsGet200ResponseItemsInnerSource_Enum
_$v1TransactionsGet200ResponseItemsInnerSourceEnum_widget =
    const V1TransactionsGet200ResponseItemsInnerSource_Enum._('widget');
const V1TransactionsGet200ResponseItemsInnerSource_Enum
_$v1TransactionsGet200ResponseItemsInnerSourceEnum_mcp =
    const V1TransactionsGet200ResponseItemsInnerSource_Enum._('mcp');
const V1TransactionsGet200ResponseItemsInnerSource_Enum
_$v1TransactionsGet200ResponseItemsInnerSourceEnum_import_ =
    const V1TransactionsGet200ResponseItemsInnerSource_Enum._('import_');
const V1TransactionsGet200ResponseItemsInnerSource_Enum
_$v1TransactionsGet200ResponseItemsInnerSourceEnum_recurrence =
    const V1TransactionsGet200ResponseItemsInnerSource_Enum._('recurrence');

V1TransactionsGet200ResponseItemsInnerSource_Enum
_$v1TransactionsGet200ResponseItemsInnerSourceEnumValueOf(String name) {
  switch (name) {
    case 'app':
      return _$v1TransactionsGet200ResponseItemsInnerSourceEnum_app;
    case 'web':
      return _$v1TransactionsGet200ResponseItemsInnerSourceEnum_web;
    case 'widget':
      return _$v1TransactionsGet200ResponseItemsInnerSourceEnum_widget;
    case 'mcp':
      return _$v1TransactionsGet200ResponseItemsInnerSourceEnum_mcp;
    case 'import_':
      return _$v1TransactionsGet200ResponseItemsInnerSourceEnum_import_;
    case 'recurrence':
      return _$v1TransactionsGet200ResponseItemsInnerSourceEnum_recurrence;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1TransactionsGet200ResponseItemsInnerSource_Enum>
_$v1TransactionsGet200ResponseItemsInnerSourceEnumValues =
    BuiltSet<V1TransactionsGet200ResponseItemsInnerSource_Enum>(
      const <V1TransactionsGet200ResponseItemsInnerSource_Enum>[
        _$v1TransactionsGet200ResponseItemsInnerSourceEnum_app,
        _$v1TransactionsGet200ResponseItemsInnerSourceEnum_web,
        _$v1TransactionsGet200ResponseItemsInnerSourceEnum_widget,
        _$v1TransactionsGet200ResponseItemsInnerSourceEnum_mcp,
        _$v1TransactionsGet200ResponseItemsInnerSourceEnum_import_,
        _$v1TransactionsGet200ResponseItemsInnerSourceEnum_recurrence,
      ],
    );

Serializer<V1TransactionsGet200ResponseItemsInnerStatusEnum>
_$v1TransactionsGet200ResponseItemsInnerStatusEnumSerializer =
    _$V1TransactionsGet200ResponseItemsInnerStatusEnumSerializer();
Serializer<V1TransactionsGet200ResponseItemsInnerSource_Enum>
_$v1TransactionsGet200ResponseItemsInnerSourceEnumSerializer =
    _$V1TransactionsGet200ResponseItemsInnerSource_EnumSerializer();

class _$V1TransactionsGet200ResponseItemsInnerStatusEnumSerializer
    implements PrimitiveSerializer<V1TransactionsGet200ResponseItemsInnerStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'paid': 'paid',
    'pending': 'pending',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'paid': 'paid',
    'pending': 'pending',
  };

  @override
  final Iterable<Type> types = const <Type>[V1TransactionsGet200ResponseItemsInnerStatusEnum];
  @override
  final String wireName = 'V1TransactionsGet200ResponseItemsInnerStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsGet200ResponseItemsInnerStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1TransactionsGet200ResponseItemsInnerStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1TransactionsGet200ResponseItemsInnerStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1TransactionsGet200ResponseItemsInnerSource_EnumSerializer
    implements PrimitiveSerializer<V1TransactionsGet200ResponseItemsInnerSource_Enum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'app': 'app',
    'web': 'web',
    'widget': 'widget',
    'mcp': 'mcp',
    'import_': 'import',
    'recurrence': 'recurrence',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'app': 'app',
    'web': 'web',
    'widget': 'widget',
    'mcp': 'mcp',
    'import': 'import_',
    'recurrence': 'recurrence',
  };

  @override
  final Iterable<Type> types = const <Type>[V1TransactionsGet200ResponseItemsInnerSource_Enum];
  @override
  final String wireName = 'V1TransactionsGet200ResponseItemsInnerSource_Enum';

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsGet200ResponseItemsInnerSource_Enum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1TransactionsGet200ResponseItemsInnerSource_Enum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1TransactionsGet200ResponseItemsInnerSource_Enum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1TransactionsGet200ResponseItemsInner extends V1TransactionsGet200ResponseItemsInner {
  @override
  final String id;
  @override
  final String name;
  @override
  final int amount;
  @override
  final String currency;
  @override
  final String date;
  @override
  final V1TransactionsGet200ResponseItemsInnerStatusEnum status;
  @override
  final String? note;
  @override
  final String categoryId;
  @override
  final String? recurrenceId;
  @override
  final String? importId;
  @override
  final V1TransactionsGet200ResponseItemsInnerSource_Enum source_;
  @override
  final String createdAt;
  @override
  final String updatedAt;

  factory _$V1TransactionsGet200ResponseItemsInner([
    void Function(V1TransactionsGet200ResponseItemsInnerBuilder)? updates,
  ]) => (V1TransactionsGet200ResponseItemsInnerBuilder()..update(updates))._build();

  _$V1TransactionsGet200ResponseItemsInner._({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.date,
    required this.status,
    this.note,
    required this.categoryId,
    this.recurrenceId,
    this.importId,
    required this.source_,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  V1TransactionsGet200ResponseItemsInner rebuild(
    void Function(V1TransactionsGet200ResponseItemsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsGet200ResponseItemsInnerBuilder toBuilder() =>
      V1TransactionsGet200ResponseItemsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsGet200ResponseItemsInner &&
        id == other.id &&
        name == other.name &&
        amount == other.amount &&
        currency == other.currency &&
        date == other.date &&
        status == other.status &&
        note == other.note &&
        categoryId == other.categoryId &&
        recurrenceId == other.recurrenceId &&
        importId == other.importId &&
        source_ == other.source_ &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, date.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, recurrenceId.hashCode);
    _$hash = $jc(_$hash, importId.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1TransactionsGet200ResponseItemsInner')
          ..add('id', id)
          ..add('name', name)
          ..add('amount', amount)
          ..add('currency', currency)
          ..add('date', date)
          ..add('status', status)
          ..add('note', note)
          ..add('categoryId', categoryId)
          ..add('recurrenceId', recurrenceId)
          ..add('importId', importId)
          ..add('source_', source_)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class V1TransactionsGet200ResponseItemsInnerBuilder
    implements
        Builder<
          V1TransactionsGet200ResponseItemsInner,
          V1TransactionsGet200ResponseItemsInnerBuilder
        > {
  _$V1TransactionsGet200ResponseItemsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  String? _date;
  String? get date => _$this._date;
  set date(String? date) => _$this._date = date;

  V1TransactionsGet200ResponseItemsInnerStatusEnum? _status;
  V1TransactionsGet200ResponseItemsInnerStatusEnum? get status => _$this._status;
  set status(V1TransactionsGet200ResponseItemsInnerStatusEnum? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  String? _recurrenceId;
  String? get recurrenceId => _$this._recurrenceId;
  set recurrenceId(String? recurrenceId) => _$this._recurrenceId = recurrenceId;

  String? _importId;
  String? get importId => _$this._importId;
  set importId(String? importId) => _$this._importId = importId;

  V1TransactionsGet200ResponseItemsInnerSource_Enum? _source_;
  V1TransactionsGet200ResponseItemsInnerSource_Enum? get source_ => _$this._source_;
  set source_(V1TransactionsGet200ResponseItemsInnerSource_Enum? source_) =>
      _$this._source_ = source_;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  String? _updatedAt;
  String? get updatedAt => _$this._updatedAt;
  set updatedAt(String? updatedAt) => _$this._updatedAt = updatedAt;

  V1TransactionsGet200ResponseItemsInnerBuilder() {
    V1TransactionsGet200ResponseItemsInner._defaults(this);
  }

  V1TransactionsGet200ResponseItemsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _amount = $v.amount;
      _currency = $v.currency;
      _date = $v.date;
      _status = $v.status;
      _note = $v.note;
      _categoryId = $v.categoryId;
      _recurrenceId = $v.recurrenceId;
      _importId = $v.importId;
      _source_ = $v.source_;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1TransactionsGet200ResponseItemsInner other) {
    _$v = other as _$V1TransactionsGet200ResponseItemsInner;
  }

  @override
  void update(void Function(V1TransactionsGet200ResponseItemsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsGet200ResponseItemsInner build() => _build();

  _$V1TransactionsGet200ResponseItemsInner _build() {
    final _$result =
        _$v ??
        _$V1TransactionsGet200ResponseItemsInner._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'V1TransactionsGet200ResponseItemsInner',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'V1TransactionsGet200ResponseItemsInner',
            'name',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'V1TransactionsGet200ResponseItemsInner',
            'amount',
          ),
          currency: BuiltValueNullFieldError.checkNotNull(
            currency,
            r'V1TransactionsGet200ResponseItemsInner',
            'currency',
          ),
          date: BuiltValueNullFieldError.checkNotNull(
            date,
            r'V1TransactionsGet200ResponseItemsInner',
            'date',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'V1TransactionsGet200ResponseItemsInner',
            'status',
          ),
          note: note,
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1TransactionsGet200ResponseItemsInner',
            'categoryId',
          ),
          recurrenceId: recurrenceId,
          importId: importId,
          source_: BuiltValueNullFieldError.checkNotNull(
            source_,
            r'V1TransactionsGet200ResponseItemsInner',
            'source_',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'V1TransactionsGet200ResponseItemsInner',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'V1TransactionsGet200ResponseItemsInner',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
