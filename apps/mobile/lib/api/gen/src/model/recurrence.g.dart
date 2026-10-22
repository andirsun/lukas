// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RecurrenceFrequencyEnum _$recurrenceFrequencyEnum_monthly = const RecurrenceFrequencyEnum._(
  'monthly',
);
const RecurrenceFrequencyEnum _$recurrenceFrequencyEnum_yearly = const RecurrenceFrequencyEnum._(
  'yearly',
);

RecurrenceFrequencyEnum _$recurrenceFrequencyEnumValueOf(String name) {
  switch (name) {
    case 'monthly':
      return _$recurrenceFrequencyEnum_monthly;
    case 'yearly':
      return _$recurrenceFrequencyEnum_yearly;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RecurrenceFrequencyEnum> _$recurrenceFrequencyEnumValues =
    BuiltSet<RecurrenceFrequencyEnum>(const <RecurrenceFrequencyEnum>[
      _$recurrenceFrequencyEnum_monthly,
      _$recurrenceFrequencyEnum_yearly,
    ]);

Serializer<RecurrenceFrequencyEnum> _$recurrenceFrequencyEnumSerializer =
    _$RecurrenceFrequencyEnumSerializer();

class _$RecurrenceFrequencyEnumSerializer implements PrimitiveSerializer<RecurrenceFrequencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };

  @override
  final Iterable<Type> types = const <Type>[RecurrenceFrequencyEnum];
  @override
  final String wireName = 'RecurrenceFrequencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    RecurrenceFrequencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RecurrenceFrequencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RecurrenceFrequencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$Recurrence extends Recurrence {
  @override
  final String id;
  @override
  final String name;
  @override
  final int amount;
  @override
  final String categoryId;
  @override
  final RecurrenceFrequencyEnum frequency;
  @override
  final int dayOfMonth;
  @override
  final int? monthOfYear;
  @override
  final String startDate;
  @override
  final String? endDate;

  factory _$Recurrence([void Function(RecurrenceBuilder)? updates]) =>
      (RecurrenceBuilder()..update(updates))._build();

  _$Recurrence._({
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
  Recurrence rebuild(void Function(RecurrenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecurrenceBuilder toBuilder() => RecurrenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Recurrence &&
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
    return (newBuiltValueToStringHelper(r'Recurrence')
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

class RecurrenceBuilder implements Builder<Recurrence, RecurrenceBuilder> {
  _$Recurrence? _$v;

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

  RecurrenceFrequencyEnum? _frequency;
  RecurrenceFrequencyEnum? get frequency => _$this._frequency;
  set frequency(RecurrenceFrequencyEnum? frequency) => _$this._frequency = frequency;

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

  RecurrenceBuilder() {
    Recurrence._defaults(this);
  }

  RecurrenceBuilder get _$this {
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
  void replace(Recurrence other) {
    _$v = other as _$Recurrence;
  }

  @override
  void update(void Function(RecurrenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Recurrence build() => _build();

  _$Recurrence _build() {
    final _$result =
        _$v ??
        _$Recurrence._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Recurrence', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Recurrence', 'name'),
          amount: BuiltValueNullFieldError.checkNotNull(amount, r'Recurrence', 'amount'),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'Recurrence',
            'categoryId',
          ),
          frequency: BuiltValueNullFieldError.checkNotNull(frequency, r'Recurrence', 'frequency'),
          dayOfMonth: BuiltValueNullFieldError.checkNotNull(
            dayOfMonth,
            r'Recurrence',
            'dayOfMonth',
          ),
          monthOfYear: monthOfYear,
          startDate: BuiltValueNullFieldError.checkNotNull(startDate, r'Recurrence', 'startDate'),
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
