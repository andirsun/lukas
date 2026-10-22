// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_recurrence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateRecurrenceFrequencyEnum _$updateRecurrenceFrequencyEnum_monthly =
    const UpdateRecurrenceFrequencyEnum._('monthly');
const UpdateRecurrenceFrequencyEnum _$updateRecurrenceFrequencyEnum_yearly =
    const UpdateRecurrenceFrequencyEnum._('yearly');

UpdateRecurrenceFrequencyEnum _$updateRecurrenceFrequencyEnumValueOf(String name) {
  switch (name) {
    case 'monthly':
      return _$updateRecurrenceFrequencyEnum_monthly;
    case 'yearly':
      return _$updateRecurrenceFrequencyEnum_yearly;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateRecurrenceFrequencyEnum> _$updateRecurrenceFrequencyEnumValues =
    BuiltSet<UpdateRecurrenceFrequencyEnum>(const <UpdateRecurrenceFrequencyEnum>[
      _$updateRecurrenceFrequencyEnum_monthly,
      _$updateRecurrenceFrequencyEnum_yearly,
    ]);

Serializer<UpdateRecurrenceFrequencyEnum> _$updateRecurrenceFrequencyEnumSerializer =
    _$UpdateRecurrenceFrequencyEnumSerializer();

class _$UpdateRecurrenceFrequencyEnumSerializer
    implements PrimitiveSerializer<UpdateRecurrenceFrequencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateRecurrenceFrequencyEnum];
  @override
  final String wireName = 'UpdateRecurrenceFrequencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateRecurrenceFrequencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateRecurrenceFrequencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateRecurrenceFrequencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateRecurrence extends UpdateRecurrence {
  @override
  final String? name;
  @override
  final int? amount;
  @override
  final String? categoryId;
  @override
  final UpdateRecurrenceFrequencyEnum? frequency;
  @override
  final int? dayOfMonth;
  @override
  final int? monthOfYear;
  @override
  final String? startDate;
  @override
  final String? endDate;

  factory _$UpdateRecurrence([void Function(UpdateRecurrenceBuilder)? updates]) =>
      (UpdateRecurrenceBuilder()..update(updates))._build();

  _$UpdateRecurrence._({
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
  UpdateRecurrence rebuild(void Function(UpdateRecurrenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateRecurrenceBuilder toBuilder() => UpdateRecurrenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateRecurrence &&
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
    return (newBuiltValueToStringHelper(r'UpdateRecurrence')
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

class UpdateRecurrenceBuilder implements Builder<UpdateRecurrence, UpdateRecurrenceBuilder> {
  _$UpdateRecurrence? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  UpdateRecurrenceFrequencyEnum? _frequency;
  UpdateRecurrenceFrequencyEnum? get frequency => _$this._frequency;
  set frequency(UpdateRecurrenceFrequencyEnum? frequency) => _$this._frequency = frequency;

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

  UpdateRecurrenceBuilder() {
    UpdateRecurrence._defaults(this);
  }

  UpdateRecurrenceBuilder get _$this {
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
  void replace(UpdateRecurrence other) {
    _$v = other as _$UpdateRecurrence;
  }

  @override
  void update(void Function(UpdateRecurrenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateRecurrence build() => _build();

  _$UpdateRecurrence _build() {
    final _$result =
        _$v ??
        _$UpdateRecurrence._(
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
