// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_recurrences_id_patch_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1RecurrencesIdPatchRequestFrequencyEnum _$v1RecurrencesIdPatchRequestFrequencyEnum_monthly =
    const V1RecurrencesIdPatchRequestFrequencyEnum._('monthly');
const V1RecurrencesIdPatchRequestFrequencyEnum _$v1RecurrencesIdPatchRequestFrequencyEnum_yearly =
    const V1RecurrencesIdPatchRequestFrequencyEnum._('yearly');

V1RecurrencesIdPatchRequestFrequencyEnum _$v1RecurrencesIdPatchRequestFrequencyEnumValueOf(
  String name,
) {
  switch (name) {
    case 'monthly':
      return _$v1RecurrencesIdPatchRequestFrequencyEnum_monthly;
    case 'yearly':
      return _$v1RecurrencesIdPatchRequestFrequencyEnum_yearly;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1RecurrencesIdPatchRequestFrequencyEnum>
_$v1RecurrencesIdPatchRequestFrequencyEnumValues =
    BuiltSet<V1RecurrencesIdPatchRequestFrequencyEnum>(
      const <V1RecurrencesIdPatchRequestFrequencyEnum>[
        _$v1RecurrencesIdPatchRequestFrequencyEnum_monthly,
        _$v1RecurrencesIdPatchRequestFrequencyEnum_yearly,
      ],
    );

Serializer<V1RecurrencesIdPatchRequestFrequencyEnum>
_$v1RecurrencesIdPatchRequestFrequencyEnumSerializer =
    _$V1RecurrencesIdPatchRequestFrequencyEnumSerializer();

class _$V1RecurrencesIdPatchRequestFrequencyEnumSerializer
    implements PrimitiveSerializer<V1RecurrencesIdPatchRequestFrequencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };

  @override
  final Iterable<Type> types = const <Type>[V1RecurrencesIdPatchRequestFrequencyEnum];
  @override
  final String wireName = 'V1RecurrencesIdPatchRequestFrequencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1RecurrencesIdPatchRequestFrequencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1RecurrencesIdPatchRequestFrequencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1RecurrencesIdPatchRequestFrequencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1RecurrencesIdPatchRequest extends V1RecurrencesIdPatchRequest {
  @override
  final String? name;
  @override
  final int? amount;
  @override
  final String? categoryId;
  @override
  final V1RecurrencesIdPatchRequestFrequencyEnum? frequency;
  @override
  final int? dayOfMonth;
  @override
  final int? monthOfYear;
  @override
  final String? startDate;
  @override
  final String? endDate;

  factory _$V1RecurrencesIdPatchRequest([
    void Function(V1RecurrencesIdPatchRequestBuilder)? updates,
  ]) => (V1RecurrencesIdPatchRequestBuilder()..update(updates))._build();

  _$V1RecurrencesIdPatchRequest._({
    this.name,
    this.amount,
    this.categoryId,
    this.frequency,
    this.dayOfMonth,
    this.monthOfYear,
    this.startDate,
    this.endDate,
  }) : super._();
  @override
  V1RecurrencesIdPatchRequest rebuild(void Function(V1RecurrencesIdPatchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1RecurrencesIdPatchRequestBuilder toBuilder() =>
      V1RecurrencesIdPatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1RecurrencesIdPatchRequest &&
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
    return (newBuiltValueToStringHelper(r'V1RecurrencesIdPatchRequest')
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

class V1RecurrencesIdPatchRequestBuilder
    implements Builder<V1RecurrencesIdPatchRequest, V1RecurrencesIdPatchRequestBuilder> {
  _$V1RecurrencesIdPatchRequest? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  V1RecurrencesIdPatchRequestFrequencyEnum? _frequency;
  V1RecurrencesIdPatchRequestFrequencyEnum? get frequency => _$this._frequency;
  set frequency(V1RecurrencesIdPatchRequestFrequencyEnum? frequency) =>
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

  V1RecurrencesIdPatchRequestBuilder() {
    V1RecurrencesIdPatchRequest._defaults(this);
  }

  V1RecurrencesIdPatchRequestBuilder get _$this {
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
  void replace(V1RecurrencesIdPatchRequest other) {
    _$v = other as _$V1RecurrencesIdPatchRequest;
  }

  @override
  void update(void Function(V1RecurrencesIdPatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1RecurrencesIdPatchRequest build() => _build();

  _$V1RecurrencesIdPatchRequest _build() {
    final _$result =
        _$v ??
        _$V1RecurrencesIdPatchRequest._(
          name: name,
          amount: amount,
          categoryId: categoryId,
          frequency: frequency,
          dayOfMonth: dayOfMonth,
          monthOfYear: monthOfYear,
          startDate: startDate,
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
