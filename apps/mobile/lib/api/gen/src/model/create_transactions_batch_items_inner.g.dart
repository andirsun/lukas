// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_transactions_batch_items_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateTransactionsBatchItemsInnerStatusEnum
_$createTransactionsBatchItemsInnerStatusEnum_paid =
    const CreateTransactionsBatchItemsInnerStatusEnum._('paid');
const CreateTransactionsBatchItemsInnerStatusEnum
_$createTransactionsBatchItemsInnerStatusEnum_pending =
    const CreateTransactionsBatchItemsInnerStatusEnum._('pending');

CreateTransactionsBatchItemsInnerStatusEnum _$createTransactionsBatchItemsInnerStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'paid':
      return _$createTransactionsBatchItemsInnerStatusEnum_paid;
    case 'pending':
      return _$createTransactionsBatchItemsInnerStatusEnum_pending;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateTransactionsBatchItemsInnerStatusEnum>
_$createTransactionsBatchItemsInnerStatusEnumValues =
    BuiltSet<CreateTransactionsBatchItemsInnerStatusEnum>(
      const <CreateTransactionsBatchItemsInnerStatusEnum>[
        _$createTransactionsBatchItemsInnerStatusEnum_paid,
        _$createTransactionsBatchItemsInnerStatusEnum_pending,
      ],
    );

const CreateTransactionsBatchItemsInnerSource_Enum
_$createTransactionsBatchItemsInnerSourceEnum_app =
    const CreateTransactionsBatchItemsInnerSource_Enum._('app');
const CreateTransactionsBatchItemsInnerSource_Enum
_$createTransactionsBatchItemsInnerSourceEnum_web =
    const CreateTransactionsBatchItemsInnerSource_Enum._('web');
const CreateTransactionsBatchItemsInnerSource_Enum
_$createTransactionsBatchItemsInnerSourceEnum_widget =
    const CreateTransactionsBatchItemsInnerSource_Enum._('widget');
const CreateTransactionsBatchItemsInnerSource_Enum
_$createTransactionsBatchItemsInnerSourceEnum_mcp =
    const CreateTransactionsBatchItemsInnerSource_Enum._('mcp');

CreateTransactionsBatchItemsInnerSource_Enum _$createTransactionsBatchItemsInnerSourceEnumValueOf(
  String name,
) {
  switch (name) {
    case 'app':
      return _$createTransactionsBatchItemsInnerSourceEnum_app;
    case 'web':
      return _$createTransactionsBatchItemsInnerSourceEnum_web;
    case 'widget':
      return _$createTransactionsBatchItemsInnerSourceEnum_widget;
    case 'mcp':
      return _$createTransactionsBatchItemsInnerSourceEnum_mcp;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateTransactionsBatchItemsInnerSource_Enum>
_$createTransactionsBatchItemsInnerSourceEnumValues =
    BuiltSet<CreateTransactionsBatchItemsInnerSource_Enum>(
      const <CreateTransactionsBatchItemsInnerSource_Enum>[
        _$createTransactionsBatchItemsInnerSourceEnum_app,
        _$createTransactionsBatchItemsInnerSourceEnum_web,
        _$createTransactionsBatchItemsInnerSourceEnum_widget,
        _$createTransactionsBatchItemsInnerSourceEnum_mcp,
      ],
    );

Serializer<CreateTransactionsBatchItemsInnerStatusEnum>
_$createTransactionsBatchItemsInnerStatusEnumSerializer =
    _$CreateTransactionsBatchItemsInnerStatusEnumSerializer();
Serializer<CreateTransactionsBatchItemsInnerSource_Enum>
_$createTransactionsBatchItemsInnerSourceEnumSerializer =
    _$CreateTransactionsBatchItemsInnerSource_EnumSerializer();

class _$CreateTransactionsBatchItemsInnerStatusEnumSerializer
    implements PrimitiveSerializer<CreateTransactionsBatchItemsInnerStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'paid': 'paid',
    'pending': 'pending',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'paid': 'paid',
    'pending': 'pending',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateTransactionsBatchItemsInnerStatusEnum];
  @override
  final String wireName = 'CreateTransactionsBatchItemsInnerStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionsBatchItemsInnerStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateTransactionsBatchItemsInnerStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateTransactionsBatchItemsInnerStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateTransactionsBatchItemsInnerSource_EnumSerializer
    implements PrimitiveSerializer<CreateTransactionsBatchItemsInnerSource_Enum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'app': 'app',
    'web': 'web',
    'widget': 'widget',
    'mcp': 'mcp',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'app': 'app',
    'web': 'web',
    'widget': 'widget',
    'mcp': 'mcp',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateTransactionsBatchItemsInnerSource_Enum];
  @override
  final String wireName = 'CreateTransactionsBatchItemsInnerSource_Enum';

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionsBatchItemsInnerSource_Enum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateTransactionsBatchItemsInnerSource_Enum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateTransactionsBatchItemsInnerSource_Enum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateTransactionsBatchItemsInner extends CreateTransactionsBatchItemsInner {
  @override
  final String name;
  @override
  final int amount;
  @override
  final String categoryId;
  @override
  final String date;
  @override
  final CreateTransactionsBatchItemsInnerStatusEnum? status;
  @override
  final String? note;
  @override
  final CreateTransactionsBatchItemsInnerSource_Enum? source_;

  factory _$CreateTransactionsBatchItemsInner([
    void Function(CreateTransactionsBatchItemsInnerBuilder)? updates,
  ]) => (CreateTransactionsBatchItemsInnerBuilder()..update(updates))._build();

  _$CreateTransactionsBatchItemsInner._({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.status,
    this.note,
    this.source_,
  }) : super._();
  @override
  CreateTransactionsBatchItemsInner rebuild(
    void Function(CreateTransactionsBatchItemsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateTransactionsBatchItemsInnerBuilder toBuilder() =>
      CreateTransactionsBatchItemsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTransactionsBatchItemsInner &&
        name == other.name &&
        amount == other.amount &&
        categoryId == other.categoryId &&
        date == other.date &&
        status == other.status &&
        note == other.note &&
        source_ == other.source_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, date.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTransactionsBatchItemsInner')
          ..add('name', name)
          ..add('amount', amount)
          ..add('categoryId', categoryId)
          ..add('date', date)
          ..add('status', status)
          ..add('note', note)
          ..add('source_', source_))
        .toString();
  }
}

class CreateTransactionsBatchItemsInnerBuilder
    implements
        Builder<CreateTransactionsBatchItemsInner, CreateTransactionsBatchItemsInnerBuilder> {
  _$CreateTransactionsBatchItemsInner? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  String? _date;
  String? get date => _$this._date;
  set date(String? date) => _$this._date = date;

  CreateTransactionsBatchItemsInnerStatusEnum? _status;
  CreateTransactionsBatchItemsInnerStatusEnum? get status => _$this._status;
  set status(CreateTransactionsBatchItemsInnerStatusEnum? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  CreateTransactionsBatchItemsInnerSource_Enum? _source_;
  CreateTransactionsBatchItemsInnerSource_Enum? get source_ => _$this._source_;
  set source_(CreateTransactionsBatchItemsInnerSource_Enum? source_) => _$this._source_ = source_;

  CreateTransactionsBatchItemsInnerBuilder() {
    CreateTransactionsBatchItemsInner._defaults(this);
  }

  CreateTransactionsBatchItemsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _amount = $v.amount;
      _categoryId = $v.categoryId;
      _date = $v.date;
      _status = $v.status;
      _note = $v.note;
      _source_ = $v.source_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTransactionsBatchItemsInner other) {
    _$v = other as _$CreateTransactionsBatchItemsInner;
  }

  @override
  void update(void Function(CreateTransactionsBatchItemsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTransactionsBatchItemsInner build() => _build();

  _$CreateTransactionsBatchItemsInner _build() {
    final _$result =
        _$v ??
        _$CreateTransactionsBatchItemsInner._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'CreateTransactionsBatchItemsInner',
            'name',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'CreateTransactionsBatchItemsInner',
            'amount',
          ),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'CreateTransactionsBatchItemsInner',
            'categoryId',
          ),
          date: BuiltValueNullFieldError.checkNotNull(
            date,
            r'CreateTransactionsBatchItemsInner',
            'date',
          ),
          status: status,
          note: note,
          source_: source_,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
