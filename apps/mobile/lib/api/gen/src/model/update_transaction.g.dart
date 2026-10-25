// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTransactionStatusEnum _$updateTransactionStatusEnum_paid =
    const UpdateTransactionStatusEnum._('paid');
const UpdateTransactionStatusEnum _$updateTransactionStatusEnum_pending =
    const UpdateTransactionStatusEnum._('pending');

UpdateTransactionStatusEnum _$updateTransactionStatusEnumValueOf(String name) {
  switch (name) {
    case 'paid':
      return _$updateTransactionStatusEnum_paid;
    case 'pending':
      return _$updateTransactionStatusEnum_pending;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateTransactionStatusEnum> _$updateTransactionStatusEnumValues =
    BuiltSet<UpdateTransactionStatusEnum>(const <UpdateTransactionStatusEnum>[
      _$updateTransactionStatusEnum_paid,
      _$updateTransactionStatusEnum_pending,
    ]);

Serializer<UpdateTransactionStatusEnum> _$updateTransactionStatusEnumSerializer =
    _$UpdateTransactionStatusEnumSerializer();

class _$UpdateTransactionStatusEnumSerializer
    implements PrimitiveSerializer<UpdateTransactionStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'paid': 'paid',
    'pending': 'pending',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'paid': 'paid',
    'pending': 'pending',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateTransactionStatusEnum];
  @override
  final String wireName = 'UpdateTransactionStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateTransactionStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateTransactionStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateTransactionStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateTransaction extends UpdateTransaction {
  @override
  final String? name;
  @override
  final int? amount;
  @override
  final String? categoryId;
  @override
  final String? date;
  @override
  final UpdateTransactionStatusEnum? status;
  @override
  final String? note;

  factory _$UpdateTransaction([void Function(UpdateTransactionBuilder)? updates]) =>
      (UpdateTransactionBuilder()..update(updates))._build();

  _$UpdateTransaction._({
    this.name,
    this.amount,
    this.categoryId,
    this.date,
    this.status,
    this.note,
  }) : super._();
  @override
  UpdateTransaction rebuild(void Function(UpdateTransactionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTransactionBuilder toBuilder() => UpdateTransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTransaction &&
        name == other.name &&
        amount == other.amount &&
        categoryId == other.categoryId &&
        date == other.date &&
        status == other.status &&
        note == other.note;
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
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTransaction')
          ..add('name', name)
          ..add('amount', amount)
          ..add('categoryId', categoryId)
          ..add('date', date)
          ..add('status', status)
          ..add('note', note))
        .toString();
  }
}

class UpdateTransactionBuilder implements Builder<UpdateTransaction, UpdateTransactionBuilder> {
  _$UpdateTransaction? _$v;

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

  UpdateTransactionStatusEnum? _status;
  UpdateTransactionStatusEnum? get status => _$this._status;
  set status(UpdateTransactionStatusEnum? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  UpdateTransactionBuilder() {
    UpdateTransaction._defaults(this);
  }

  UpdateTransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _amount = $v.amount;
      _categoryId = $v.categoryId;
      _date = $v.date;
      _status = $v.status;
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTransaction other) {
    _$v = other as _$UpdateTransaction;
  }

  @override
  void update(void Function(UpdateTransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTransaction build() => _build();

  _$UpdateTransaction _build() {
    final _$result =
        _$v ??
        _$UpdateTransaction._(
          name: name,
          amount: amount,
          categoryId: categoryId,
          date: date,
          status: status,
          note: note,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
