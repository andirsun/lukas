// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateTransactionStatusEnum _$createTransactionStatusEnum_paid =
    const CreateTransactionStatusEnum._('paid');
const CreateTransactionStatusEnum _$createTransactionStatusEnum_pending =
    const CreateTransactionStatusEnum._('pending');

CreateTransactionStatusEnum _$createTransactionStatusEnumValueOf(String name) {
  switch (name) {
    case 'paid':
      return _$createTransactionStatusEnum_paid;
    case 'pending':
      return _$createTransactionStatusEnum_pending;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateTransactionStatusEnum> _$createTransactionStatusEnumValues =
    BuiltSet<CreateTransactionStatusEnum>(const <CreateTransactionStatusEnum>[
      _$createTransactionStatusEnum_paid,
      _$createTransactionStatusEnum_pending,
    ]);

const CreateTransactionSource_Enum _$createTransactionSourceEnum_app =
    const CreateTransactionSource_Enum._('app');
const CreateTransactionSource_Enum _$createTransactionSourceEnum_web =
    const CreateTransactionSource_Enum._('web');
const CreateTransactionSource_Enum _$createTransactionSourceEnum_widget =
    const CreateTransactionSource_Enum._('widget');
const CreateTransactionSource_Enum _$createTransactionSourceEnum_mcp =
    const CreateTransactionSource_Enum._('mcp');

CreateTransactionSource_Enum _$createTransactionSourceEnumValueOf(String name) {
  switch (name) {
    case 'app':
      return _$createTransactionSourceEnum_app;
    case 'web':
      return _$createTransactionSourceEnum_web;
    case 'widget':
      return _$createTransactionSourceEnum_widget;
    case 'mcp':
      return _$createTransactionSourceEnum_mcp;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateTransactionSource_Enum> _$createTransactionSourceEnumValues =
    BuiltSet<CreateTransactionSource_Enum>(const <CreateTransactionSource_Enum>[
      _$createTransactionSourceEnum_app,
      _$createTransactionSourceEnum_web,
      _$createTransactionSourceEnum_widget,
      _$createTransactionSourceEnum_mcp,
    ]);

Serializer<CreateTransactionStatusEnum> _$createTransactionStatusEnumSerializer =
    _$CreateTransactionStatusEnumSerializer();
Serializer<CreateTransactionSource_Enum> _$createTransactionSourceEnumSerializer =
    _$CreateTransactionSource_EnumSerializer();

class _$CreateTransactionStatusEnumSerializer
    implements PrimitiveSerializer<CreateTransactionStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'paid': 'paid',
    'pending': 'pending',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'paid': 'paid',
    'pending': 'pending',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateTransactionStatusEnum];
  @override
  final String wireName = 'CreateTransactionStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateTransactionStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateTransactionStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateTransactionSource_EnumSerializer
    implements PrimitiveSerializer<CreateTransactionSource_Enum> {
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
  final Iterable<Type> types = const <Type>[CreateTransactionSource_Enum];
  @override
  final String wireName = 'CreateTransactionSource_Enum';

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionSource_Enum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateTransactionSource_Enum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateTransactionSource_Enum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateTransaction extends CreateTransaction {
  @override
  final String name;
  @override
  final int amount;
  @override
  final String categoryId;
  @override
  final String date;
  @override
  final CreateTransactionStatusEnum? status;
  @override
  final String? note;
  @override
  final CreateTransactionSource_Enum? source_;
  @override
  final CreateTransactionRepeat? repeat;

  factory _$CreateTransaction([void Function(CreateTransactionBuilder)? updates]) =>
      (CreateTransactionBuilder()..update(updates))._build();

  _$CreateTransaction._({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.status,
    this.note,
    this.source_,
    this.repeat,
  }) : super._();
  @override
  CreateTransaction rebuild(void Function(CreateTransactionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTransactionBuilder toBuilder() => CreateTransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTransaction &&
        name == other.name &&
        amount == other.amount &&
        categoryId == other.categoryId &&
        date == other.date &&
        status == other.status &&
        note == other.note &&
        source_ == other.source_ &&
        repeat == other.repeat;
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
    _$hash = $jc(_$hash, repeat.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTransaction')
          ..add('name', name)
          ..add('amount', amount)
          ..add('categoryId', categoryId)
          ..add('date', date)
          ..add('status', status)
          ..add('note', note)
          ..add('source_', source_)
          ..add('repeat', repeat))
        .toString();
  }
}

class CreateTransactionBuilder implements Builder<CreateTransaction, CreateTransactionBuilder> {
  _$CreateTransaction? _$v;

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

  CreateTransactionStatusEnum? _status;
  CreateTransactionStatusEnum? get status => _$this._status;
  set status(CreateTransactionStatusEnum? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  CreateTransactionSource_Enum? _source_;
  CreateTransactionSource_Enum? get source_ => _$this._source_;
  set source_(CreateTransactionSource_Enum? source_) => _$this._source_ = source_;

  CreateTransactionRepeatBuilder? _repeat;
  CreateTransactionRepeatBuilder get repeat => _$this._repeat ??= CreateTransactionRepeatBuilder();
  set repeat(CreateTransactionRepeatBuilder? repeat) => _$this._repeat = repeat;

  CreateTransactionBuilder() {
    CreateTransaction._defaults(this);
  }

  CreateTransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _amount = $v.amount;
      _categoryId = $v.categoryId;
      _date = $v.date;
      _status = $v.status;
      _note = $v.note;
      _source_ = $v.source_;
      _repeat = $v.repeat?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTransaction other) {
    _$v = other as _$CreateTransaction;
  }

  @override
  void update(void Function(CreateTransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTransaction build() => _build();

  _$CreateTransaction _build() {
    _$CreateTransaction _$result;
    try {
      _$result =
          _$v ??
          _$CreateTransaction._(
            name: BuiltValueNullFieldError.checkNotNull(name, r'CreateTransaction', 'name'),
            amount: BuiltValueNullFieldError.checkNotNull(amount, r'CreateTransaction', 'amount'),
            categoryId: BuiltValueNullFieldError.checkNotNull(
              categoryId,
              r'CreateTransaction',
              'categoryId',
            ),
            date: BuiltValueNullFieldError.checkNotNull(date, r'CreateTransaction', 'date'),
            status: status,
            note: note,
            source_: source_,
            repeat: _repeat?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'repeat';
        _repeat?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'CreateTransaction', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
