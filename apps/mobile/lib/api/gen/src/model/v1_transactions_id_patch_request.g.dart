// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_id_patch_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1TransactionsIdPatchRequestStatusEnum _$v1TransactionsIdPatchRequestStatusEnum_paid =
    const V1TransactionsIdPatchRequestStatusEnum._('paid');
const V1TransactionsIdPatchRequestStatusEnum _$v1TransactionsIdPatchRequestStatusEnum_pending =
    const V1TransactionsIdPatchRequestStatusEnum._('pending');

V1TransactionsIdPatchRequestStatusEnum _$v1TransactionsIdPatchRequestStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'paid':
      return _$v1TransactionsIdPatchRequestStatusEnum_paid;
    case 'pending':
      return _$v1TransactionsIdPatchRequestStatusEnum_pending;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1TransactionsIdPatchRequestStatusEnum>
_$v1TransactionsIdPatchRequestStatusEnumValues = BuiltSet<V1TransactionsIdPatchRequestStatusEnum>(
  const <V1TransactionsIdPatchRequestStatusEnum>[
    _$v1TransactionsIdPatchRequestStatusEnum_paid,
    _$v1TransactionsIdPatchRequestStatusEnum_pending,
  ],
);

Serializer<V1TransactionsIdPatchRequestStatusEnum>
_$v1TransactionsIdPatchRequestStatusEnumSerializer =
    _$V1TransactionsIdPatchRequestStatusEnumSerializer();

class _$V1TransactionsIdPatchRequestStatusEnumSerializer
    implements PrimitiveSerializer<V1TransactionsIdPatchRequestStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'paid': 'paid',
    'pending': 'pending',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'paid': 'paid',
    'pending': 'pending',
  };

  @override
  final Iterable<Type> types = const <Type>[V1TransactionsIdPatchRequestStatusEnum];
  @override
  final String wireName = 'V1TransactionsIdPatchRequestStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsIdPatchRequestStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1TransactionsIdPatchRequestStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1TransactionsIdPatchRequestStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1TransactionsIdPatchRequest extends V1TransactionsIdPatchRequest {
  @override
  final String? name;
  @override
  final int? amount;
  @override
  final String? categoryId;
  @override
  final String? date;
  @override
  final V1TransactionsIdPatchRequestStatusEnum? status;
  @override
  final String? note;

  factory _$V1TransactionsIdPatchRequest([
    void Function(V1TransactionsIdPatchRequestBuilder)? updates,
  ]) => (V1TransactionsIdPatchRequestBuilder()..update(updates))._build();

  _$V1TransactionsIdPatchRequest._({
    this.name,
    this.amount,
    this.categoryId,
    this.date,
    this.status,
    this.note,
  }) : super._();
  @override
  V1TransactionsIdPatchRequest rebuild(
    void Function(V1TransactionsIdPatchRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsIdPatchRequestBuilder toBuilder() =>
      V1TransactionsIdPatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsIdPatchRequest &&
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
    return (newBuiltValueToStringHelper(r'V1TransactionsIdPatchRequest')
          ..add('name', name)
          ..add('amount', amount)
          ..add('categoryId', categoryId)
          ..add('date', date)
          ..add('status', status)
          ..add('note', note))
        .toString();
  }
}

class V1TransactionsIdPatchRequestBuilder
    implements Builder<V1TransactionsIdPatchRequest, V1TransactionsIdPatchRequestBuilder> {
  _$V1TransactionsIdPatchRequest? _$v;

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

  V1TransactionsIdPatchRequestStatusEnum? _status;
  V1TransactionsIdPatchRequestStatusEnum? get status => _$this._status;
  set status(V1TransactionsIdPatchRequestStatusEnum? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  V1TransactionsIdPatchRequestBuilder() {
    V1TransactionsIdPatchRequest._defaults(this);
  }

  V1TransactionsIdPatchRequestBuilder get _$this {
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
  void replace(V1TransactionsIdPatchRequest other) {
    _$v = other as _$V1TransactionsIdPatchRequest;
  }

  @override
  void update(void Function(V1TransactionsIdPatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsIdPatchRequest build() => _build();

  _$V1TransactionsIdPatchRequest _build() {
    final _$result =
        _$v ??
        _$V1TransactionsIdPatchRequest._(
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
