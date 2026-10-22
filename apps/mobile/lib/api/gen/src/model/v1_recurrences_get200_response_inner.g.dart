// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_recurrences_get200_response_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1RecurrencesGet200ResponseInnerFrequencyEnum
_$v1RecurrencesGet200ResponseInnerFrequencyEnum_monthly =
    const V1RecurrencesGet200ResponseInnerFrequencyEnum._('monthly');
const V1RecurrencesGet200ResponseInnerFrequencyEnum
_$v1RecurrencesGet200ResponseInnerFrequencyEnum_yearly =
    const V1RecurrencesGet200ResponseInnerFrequencyEnum._('yearly');

V1RecurrencesGet200ResponseInnerFrequencyEnum
_$v1RecurrencesGet200ResponseInnerFrequencyEnumValueOf(String name) {
  switch (name) {
    case 'monthly':
      return _$v1RecurrencesGet200ResponseInnerFrequencyEnum_monthly;
    case 'yearly':
      return _$v1RecurrencesGet200ResponseInnerFrequencyEnum_yearly;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1RecurrencesGet200ResponseInnerFrequencyEnum>
_$v1RecurrencesGet200ResponseInnerFrequencyEnumValues =
    BuiltSet<V1RecurrencesGet200ResponseInnerFrequencyEnum>(
      const <V1RecurrencesGet200ResponseInnerFrequencyEnum>[
        _$v1RecurrencesGet200ResponseInnerFrequencyEnum_monthly,
        _$v1RecurrencesGet200ResponseInnerFrequencyEnum_yearly,
      ],
    );

Serializer<V1RecurrencesGet200ResponseInnerFrequencyEnum>
_$v1RecurrencesGet200ResponseInnerFrequencyEnumSerializer =
    _$V1RecurrencesGet200ResponseInnerFrequencyEnumSerializer();

class _$V1RecurrencesGet200ResponseInnerFrequencyEnumSerializer
    implements PrimitiveSerializer<V1RecurrencesGet200ResponseInnerFrequencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };

  @override
  final Iterable<Type> types = const <Type>[V1RecurrencesGet200ResponseInnerFrequencyEnum];
  @override
  final String wireName = 'V1RecurrencesGet200ResponseInnerFrequencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1RecurrencesGet200ResponseInnerFrequencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1RecurrencesGet200ResponseInnerFrequencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1RecurrencesGet200ResponseInnerFrequencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1RecurrencesGet200ResponseInner extends V1RecurrencesGet200ResponseInner {
  @override
  final String id;
  @override
  final String name;
  @override
  final int amount;
  @override
  final String categoryId;
  @override
  final V1RecurrencesGet200ResponseInnerFrequencyEnum frequency;
  @override
  final int dayOfMonth;
  @override
  final int? monthOfYear;
  @override
  final String startDate;
  @override
  final String? endDate;

  factory _$V1RecurrencesGet200ResponseInner([
    void Function(V1RecurrencesGet200ResponseInnerBuilder)? updates,
  ]) => (V1RecurrencesGet200ResponseInnerBuilder()..update(updates))._build();

  _$V1RecurrencesGet200ResponseInner._({
    required this.id,
    required this.name,
    required this.amount,
    required this.categoryId,
    required this.frequency,
    required this.dayOfMonth,
    this.monthOfYear,
    required this.startDate,
    this.endDate,
  }) : super._();
  @override
  V1RecurrencesGet200ResponseInner rebuild(
    void Function(V1RecurrencesGet200ResponseInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1RecurrencesGet200ResponseInnerBuilder toBuilder() =>
      V1RecurrencesGet200ResponseInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1RecurrencesGet200ResponseInner &&
        id == other.id &&
        name == other.name &&
        amount == other.amount &&
        categoryId == other.categoryId &&
        frequency == other.frequency &&
        dayOfMonth == other.dayOfMonth &&
        monthOfYear == other.monthOfYear &&
        startDate == other.startDate &&
        endDate == other.endDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, frequency.hashCode);
    _$hash = $jc(_$hash, dayOfMonth.hashCode);
    _$hash = $jc(_$hash, monthOfYear.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1RecurrencesGet200ResponseInner')
          ..add('id', id)
          ..add('name', name)
          ..add('amount', amount)
          ..add('categoryId', categoryId)
          ..add('frequency', frequency)
          ..add('dayOfMonth', dayOfMonth)
          ..add('monthOfYear', monthOfYear)
          ..add('startDate', startDate)
          ..add('endDate', endDate))
        .toString();
  }
}

class V1RecurrencesGet200ResponseInnerBuilder
    implements Builder<V1RecurrencesGet200ResponseInner, V1RecurrencesGet200ResponseInnerBuilder> {
  _$V1RecurrencesGet200ResponseInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  V1RecurrencesGet200ResponseInnerFrequencyEnum? _frequency;
  V1RecurrencesGet200ResponseInnerFrequencyEnum? get frequency => _$this._frequency;
  set frequency(V1RecurrencesGet200ResponseInnerFrequencyEnum? frequency) =>
      _$this._frequency = frequency;

  int? _dayOfMonth;
  int? get dayOfMonth => _$this._dayOfMonth;
  set dayOfMonth(int? dayOfMonth) => _$this._dayOfMonth = dayOfMonth;

  int? _monthOfYear;
  int? get monthOfYear => _$this._monthOfYear;
  set monthOfYear(int? monthOfYear) => _$this._monthOfYear = monthOfYear;

  String? _startDate;
  String? get startDate => _$this._startDate;
  set startDate(String? startDate) => _$this._startDate = startDate;

  String? _endDate;
  String? get endDate => _$this._endDate;
  set endDate(String? endDate) => _$this._endDate = endDate;

  V1RecurrencesGet200ResponseInnerBuilder() {
    V1RecurrencesGet200ResponseInner._defaults(this);
  }

  V1RecurrencesGet200ResponseInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _amount = $v.amount;
      _categoryId = $v.categoryId;
      _frequency = $v.frequency;
      _dayOfMonth = $v.dayOfMonth;
      _monthOfYear = $v.monthOfYear;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1RecurrencesGet200ResponseInner other) {
    _$v = other as _$V1RecurrencesGet200ResponseInner;
  }

  @override
  void update(void Function(V1RecurrencesGet200ResponseInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1RecurrencesGet200ResponseInner build() => _build();

  _$V1RecurrencesGet200ResponseInner _build() {
    final _$result =
        _$v ??
        _$V1RecurrencesGet200ResponseInner._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'V1RecurrencesGet200ResponseInner', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'V1RecurrencesGet200ResponseInner',
            'name',
          ),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'V1RecurrencesGet200ResponseInner',
            'amount',
          ),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1RecurrencesGet200ResponseInner',
            'categoryId',
          ),
          frequency: BuiltValueNullFieldError.checkNotNull(
            frequency,
            r'V1RecurrencesGet200ResponseInner',
            'frequency',
          ),
          dayOfMonth: BuiltValueNullFieldError.checkNotNull(
            dayOfMonth,
            r'V1RecurrencesGet200ResponseInner',
            'dayOfMonth',
          ),
          monthOfYear: monthOfYear,
          startDate: BuiltValueNullFieldError.checkNotNull(
            startDate,
            r'V1RecurrencesGet200ResponseInner',
            'startDate',
          ),
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
