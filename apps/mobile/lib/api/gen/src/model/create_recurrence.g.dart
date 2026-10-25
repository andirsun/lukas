// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_recurrence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateRecurrenceFrequencyEnum _$createRecurrenceFrequencyEnum_monthly =
    const CreateRecurrenceFrequencyEnum._('monthly');
const CreateRecurrenceFrequencyEnum _$createRecurrenceFrequencyEnum_yearly =
    const CreateRecurrenceFrequencyEnum._('yearly');

CreateRecurrenceFrequencyEnum _$createRecurrenceFrequencyEnumValueOf(String name) {
  switch (name) {
    case 'monthly':
      return _$createRecurrenceFrequencyEnum_monthly;
    case 'yearly':
      return _$createRecurrenceFrequencyEnum_yearly;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateRecurrenceFrequencyEnum> _$createRecurrenceFrequencyEnumValues =
    BuiltSet<CreateRecurrenceFrequencyEnum>(const <CreateRecurrenceFrequencyEnum>[
      _$createRecurrenceFrequencyEnum_monthly,
      _$createRecurrenceFrequencyEnum_yearly,
    ]);

Serializer<CreateRecurrenceFrequencyEnum> _$createRecurrenceFrequencyEnumSerializer =
    _$CreateRecurrenceFrequencyEnumSerializer();

class _$CreateRecurrenceFrequencyEnumSerializer
    implements PrimitiveSerializer<CreateRecurrenceFrequencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateRecurrenceFrequencyEnum];
  @override
  final String wireName = 'CreateRecurrenceFrequencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateRecurrenceFrequencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateRecurrenceFrequencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateRecurrenceFrequencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateRecurrence extends CreateRecurrence {
  @override
  final String name;
  @override
  final int amount;
  @override
  final String categoryId;
  @override
  final CreateRecurrenceFrequencyEnum frequency;
  @override
  final int dayOfMonth;
  @override
  final int? monthOfYear;
  @override
  final String startDate;
  @override
  final String? endDate;

  factory _$CreateRecurrence([void Function(CreateRecurrenceBuilder)? updates]) =>
      (CreateRecurrenceBuilder()..update(updates))._build();

  _$CreateRecurrence._({
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
  CreateRecurrence rebuild(void Function(CreateRecurrenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateRecurrenceBuilder toBuilder() => CreateRecurrenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateRecurrence &&
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
    return (newBuiltValueToStringHelper(r'CreateRecurrence')
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

class CreateRecurrenceBuilder implements Builder<CreateRecurrence, CreateRecurrenceBuilder> {
  _$CreateRecurrence? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  int? _amount;
  int? get amount => _$this._amount;
  set amount(int? amount) => _$this._amount = amount;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  CreateRecurrenceFrequencyEnum? _frequency;
  CreateRecurrenceFrequencyEnum? get frequency => _$this._frequency;
  set frequency(CreateRecurrenceFrequencyEnum? frequency) => _$this._frequency = frequency;

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

  CreateRecurrenceBuilder() {
    CreateRecurrence._defaults(this);
  }

  CreateRecurrenceBuilder get _$this {
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
  void replace(CreateRecurrence other) {
    _$v = other as _$CreateRecurrence;
  }

  @override
  void update(void Function(CreateRecurrenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateRecurrence build() => _build();

  _$CreateRecurrence _build() {
    final _$result =
        _$v ??
        _$CreateRecurrence._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'CreateRecurrence', 'name'),
          amount: BuiltValueNullFieldError.checkNotNull(amount, r'CreateRecurrence', 'amount'),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'CreateRecurrence',
            'categoryId',
          ),
          frequency: BuiltValueNullFieldError.checkNotNull(
            frequency,
            r'CreateRecurrence',
            'frequency',
          ),
          dayOfMonth: BuiltValueNullFieldError.checkNotNull(
            dayOfMonth,
            r'CreateRecurrence',
            'dayOfMonth',
          ),
          monthOfYear: monthOfYear,
          startDate: BuiltValueNullFieldError.checkNotNull(
            startDate,
            r'CreateRecurrence',
            'startDate',
          ),
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
