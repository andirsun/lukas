// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1TransactionsPostRequestStatusEnum _$v1TransactionsPostRequestStatusEnum_paid =
    const V1TransactionsPostRequestStatusEnum._('paid');
const V1TransactionsPostRequestStatusEnum _$v1TransactionsPostRequestStatusEnum_pending =
    const V1TransactionsPostRequestStatusEnum._('pending');

V1TransactionsPostRequestStatusEnum _$v1TransactionsPostRequestStatusEnumValueOf(String name) {
  switch (name) {
    case 'paid':
      return _$v1TransactionsPostRequestStatusEnum_paid;
    case 'pending':
      return _$v1TransactionsPostRequestStatusEnum_pending;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1TransactionsPostRequestStatusEnum> _$v1TransactionsPostRequestStatusEnumValues =
    BuiltSet<V1TransactionsPostRequestStatusEnum>(const <V1TransactionsPostRequestStatusEnum>[
      _$v1TransactionsPostRequestStatusEnum_paid,
      _$v1TransactionsPostRequestStatusEnum_pending,
    ]);

const V1TransactionsPostRequestSource_Enum _$v1TransactionsPostRequestSourceEnum_app =
    const V1TransactionsPostRequestSource_Enum._('app');
const V1TransactionsPostRequestSource_Enum _$v1TransactionsPostRequestSourceEnum_web =
    const V1TransactionsPostRequestSource_Enum._('web');
const V1TransactionsPostRequestSource_Enum _$v1TransactionsPostRequestSourceEnum_widget =
    const V1TransactionsPostRequestSource_Enum._('widget');
const V1TransactionsPostRequestSource_Enum _$v1TransactionsPostRequestSourceEnum_mcp =
    const V1TransactionsPostRequestSource_Enum._('mcp');

V1TransactionsPostRequestSource_Enum _$v1TransactionsPostRequestSourceEnumValueOf(String name) {
  switch (name) {
    case 'app':
      return _$v1TransactionsPostRequestSourceEnum_app;
    case 'web':
      return _$v1TransactionsPostRequestSourceEnum_web;
    case 'widget':
      return _$v1TransactionsPostRequestSourceEnum_widget;
    case 'mcp':
      return _$v1TransactionsPostRequestSourceEnum_mcp;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1TransactionsPostRequestSource_Enum> _$v1TransactionsPostRequestSourceEnumValues =
    BuiltSet<V1TransactionsPostRequestSource_Enum>(const <V1TransactionsPostRequestSource_Enum>[
      _$v1TransactionsPostRequestSourceEnum_app,
      _$v1TransactionsPostRequestSourceEnum_web,
      _$v1TransactionsPostRequestSourceEnum_widget,
      _$v1TransactionsPostRequestSourceEnum_mcp,
    ]);

Serializer<V1TransactionsPostRequestStatusEnum> _$v1TransactionsPostRequestStatusEnumSerializer =
    _$V1TransactionsPostRequestStatusEnumSerializer();
Serializer<V1TransactionsPostRequestSource_Enum> _$v1TransactionsPostRequestSourceEnumSerializer =
    _$V1TransactionsPostRequestSource_EnumSerializer();

class _$V1TransactionsPostRequestStatusEnumSerializer
    implements PrimitiveSerializer<V1TransactionsPostRequestStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'paid': 'paid',
    'pending': 'pending',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'paid': 'paid',
    'pending': 'pending',
  };

  @override
  final Iterable<Type> types = const <Type>[V1TransactionsPostRequestStatusEnum];
  @override
  final String wireName = 'V1TransactionsPostRequestStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsPostRequestStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1TransactionsPostRequestStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1TransactionsPostRequestStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1TransactionsPostRequestSource_EnumSerializer
    implements PrimitiveSerializer<V1TransactionsPostRequestSource_Enum> {
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
  final Iterable<Type> types = const <Type>[V1TransactionsPostRequestSource_Enum];
  @override
  final String wireName = 'V1TransactionsPostRequestSource_Enum';

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsPostRequestSource_Enum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1TransactionsPostRequestSource_Enum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1TransactionsPostRequestSource_Enum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1TransactionsPostRequest extends V1TransactionsPostRequest {
  @override
  final String name;
  @override
  final int amount;
  @override
  final String categoryId;
  @override
  final String date;
  @override
  final V1TransactionsPostRequestStatusEnum? status;
  @override
  final String? note;
  @override
  final V1TransactionsPostRequestSource_Enum? source_;

  factory _$V1TransactionsPostRequest([void Function(V1TransactionsPostRequestBuilder)? updates]) =>
      (V1TransactionsPostRequestBuilder()..update(updates))._build();

  _$V1TransactionsPostRequest._({
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.status,
    this.note,
    this.source_,
  }) : super._();
  @override
  V1TransactionsPostRequest rebuild(void Function(V1TransactionsPostRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1TransactionsPostRequestBuilder toBuilder() => V1TransactionsPostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsPostRequest &&
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
    return (newBuiltValueToStringHelper(r'V1TransactionsPostRequest')
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

class V1TransactionsPostRequestBuilder
    implements Builder<V1TransactionsPostRequest, V1TransactionsPostRequestBuilder> {
  _$V1TransactionsPostRequest? _$v;

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

  V1TransactionsPostRequestStatusEnum? _status;
  V1TransactionsPostRequestStatusEnum? get status => _$this._status;
  set status(V1TransactionsPostRequestStatusEnum? status) => _$this._status = status;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  V1TransactionsPostRequestSource_Enum? _source_;
  V1TransactionsPostRequestSource_Enum? get source_ => _$this._source_;
  set source_(V1TransactionsPostRequestSource_Enum? source_) => _$this._source_ = source_;

  V1TransactionsPostRequestBuilder() {
    V1TransactionsPostRequest._defaults(this);
  }

  V1TransactionsPostRequestBuilder get _$this {
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
  void replace(V1TransactionsPostRequest other) {
    _$v = other as _$V1TransactionsPostRequest;
  }

  @override
  void update(void Function(V1TransactionsPostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsPostRequest build() => _build();

  _$V1TransactionsPostRequest _build() {
    final _$result =
        _$v ??
        _$V1TransactionsPostRequest._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'V1TransactionsPostRequest', 'name'),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'V1TransactionsPostRequest',
            'amount',
          ),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1TransactionsPostRequest',
            'categoryId',
          ),
          date: BuiltValueNullFieldError.checkNotNull(date, r'V1TransactionsPostRequest', 'date'),
          status: status,
          note: note,
          source_: source_,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
