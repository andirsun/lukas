// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_recurrences_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1RecurrencesPostRequestFrequencyEnum _$v1RecurrencesPostRequestFrequencyEnum_monthly =
    const V1RecurrencesPostRequestFrequencyEnum._('monthly');
const V1RecurrencesPostRequestFrequencyEnum _$v1RecurrencesPostRequestFrequencyEnum_yearly =
    const V1RecurrencesPostRequestFrequencyEnum._('yearly');

V1RecurrencesPostRequestFrequencyEnum _$v1RecurrencesPostRequestFrequencyEnumValueOf(String name) {
  switch (name) {
    case 'monthly':
      return _$v1RecurrencesPostRequestFrequencyEnum_monthly;
    case 'yearly':
      return _$v1RecurrencesPostRequestFrequencyEnum_yearly;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1RecurrencesPostRequestFrequencyEnum>
_$v1RecurrencesPostRequestFrequencyEnumValues = BuiltSet<V1RecurrencesPostRequestFrequencyEnum>(
  const <V1RecurrencesPostRequestFrequencyEnum>[
    _$v1RecurrencesPostRequestFrequencyEnum_monthly,
    _$v1RecurrencesPostRequestFrequencyEnum_yearly,
  ],
);

Serializer<V1RecurrencesPostRequestFrequencyEnum>
_$v1RecurrencesPostRequestFrequencyEnumSerializer =
    _$V1RecurrencesPostRequestFrequencyEnumSerializer();

class _$V1RecurrencesPostRequestFrequencyEnumSerializer
    implements PrimitiveSerializer<V1RecurrencesPostRequestFrequencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };

  @override
  final Iterable<Type> types = const <Type>[V1RecurrencesPostRequestFrequencyEnum];
  @override
  final String wireName = 'V1RecurrencesPostRequestFrequencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1RecurrencesPostRequestFrequencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1RecurrencesPostRequestFrequencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1RecurrencesPostRequestFrequencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1RecurrencesPostRequest extends V1RecurrencesPostRequest {
  @override
  final String name;
  @override
  final int amount;
  @override
  final String categoryId;
  @override
  final V1RecurrencesPostRequestFrequencyEnum frequency;
  @override
  final int dayOfMonth;
  @override
  final int? monthOfYear;
  @override
  final String startDate;
  @override
  final String? endDate;

  factory _$V1RecurrencesPostRequest([void Function(V1RecurrencesPostRequestBuilder)? updates]) =>
      (V1RecurrencesPostRequestBuilder()..update(updates))._build();

  _$V1RecurrencesPostRequest._({
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
  V1RecurrencesPostRequest rebuild(void Function(V1RecurrencesPostRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1RecurrencesPostRequestBuilder toBuilder() => V1RecurrencesPostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1RecurrencesPostRequest &&
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
    return (newBuiltValueToStringHelper(r'V1RecurrencesPostRequest')
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

class V1RecurrencesPostRequestBuilder
    implements Builder<V1RecurrencesPostRequest, V1RecurrencesPostRequestBuilder> {
  _$V1RecurrencesPostRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  V1RecurrencesPostRequestFrequencyEnum? _frequency;
  V1RecurrencesPostRequestFrequencyEnum? get frequency => _$this._frequency;
  set frequency(V1RecurrencesPostRequestFrequencyEnum? frequency) => _$this._frequency = frequency;

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

  V1RecurrencesPostRequestBuilder() {
    V1RecurrencesPostRequest._defaults(this);
  }

  V1RecurrencesPostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
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
  void replace(V1RecurrencesPostRequest other) {
    _$v = other as _$V1RecurrencesPostRequest;
  }

  @override
  void update(void Function(V1RecurrencesPostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1RecurrencesPostRequest build() => _build();

  _$V1RecurrencesPostRequest _build() {
    final _$result =
        _$v ??
        _$V1RecurrencesPostRequest._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'V1RecurrencesPostRequest', 'name'),
          amount: BuiltValueNullFieldError.checkNotNull(
            amount,
            r'V1RecurrencesPostRequest',
            'amount',
          ),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1RecurrencesPostRequest',
            'categoryId',
          ),
          frequency: BuiltValueNullFieldError.checkNotNull(
            frequency,
            r'V1RecurrencesPostRequest',
            'frequency',
          ),
          dayOfMonth: BuiltValueNullFieldError.checkNotNull(
            dayOfMonth,
            r'V1RecurrencesPostRequest',
            'dayOfMonth',
          ),
          monthOfYear: monthOfYear,
          startDate: BuiltValueNullFieldError.checkNotNull(
            startDate,
            r'V1RecurrencesPostRequest',
            'startDate',
          ),
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
