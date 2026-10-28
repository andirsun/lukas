// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_transaction_repeat.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateTransactionRepeatFrequencyEnum _$createTransactionRepeatFrequencyEnum_monthly =
    const CreateTransactionRepeatFrequencyEnum._('monthly');
const CreateTransactionRepeatFrequencyEnum _$createTransactionRepeatFrequencyEnum_yearly =
    const CreateTransactionRepeatFrequencyEnum._('yearly');

CreateTransactionRepeatFrequencyEnum _$createTransactionRepeatFrequencyEnumValueOf(String name) {
  switch (name) {
    case 'monthly':
      return _$createTransactionRepeatFrequencyEnum_monthly;
    case 'yearly':
      return _$createTransactionRepeatFrequencyEnum_yearly;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateTransactionRepeatFrequencyEnum> _$createTransactionRepeatFrequencyEnumValues =
    BuiltSet<CreateTransactionRepeatFrequencyEnum>(const <CreateTransactionRepeatFrequencyEnum>[
      _$createTransactionRepeatFrequencyEnum_monthly,
      _$createTransactionRepeatFrequencyEnum_yearly,
    ]);

Serializer<CreateTransactionRepeatFrequencyEnum> _$createTransactionRepeatFrequencyEnumSerializer =
    _$CreateTransactionRepeatFrequencyEnumSerializer();

class _$CreateTransactionRepeatFrequencyEnumSerializer
    implements PrimitiveSerializer<CreateTransactionRepeatFrequencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'monthly': 'monthly',
    'yearly': 'yearly',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateTransactionRepeatFrequencyEnum];
  @override
  final String wireName = 'CreateTransactionRepeatFrequencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionRepeatFrequencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateTransactionRepeatFrequencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateTransactionRepeatFrequencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateTransactionRepeat extends CreateTransactionRepeat {
  @override
  final CreateTransactionRepeatFrequencyEnum frequency;
  @override
  final String? endDate;

  factory _$CreateTransactionRepeat([void Function(CreateTransactionRepeatBuilder)? updates]) =>
      (CreateTransactionRepeatBuilder()..update(updates))._build();

  _$CreateTransactionRepeat._({required this.frequency, this.endDate}) : super._();
  @override
  CreateTransactionRepeat rebuild(void Function(CreateTransactionRepeatBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTransactionRepeatBuilder toBuilder() => CreateTransactionRepeatBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTransactionRepeat &&
        frequency == other.frequency &&
        endDate == other.endDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, frequency.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTransactionRepeat')
          ..add('frequency', frequency)
          ..add('endDate', endDate))
        .toString();
  }
}

class CreateTransactionRepeatBuilder
    implements Builder<CreateTransactionRepeat, CreateTransactionRepeatBuilder> {
  _$CreateTransactionRepeat? _$v;

  CreateTransactionRepeatFrequencyEnum? _frequency;
  CreateTransactionRepeatFrequencyEnum? get frequency => _$this._frequency;
  set frequency(CreateTransactionRepeatFrequencyEnum? frequency) => _$this._frequency = frequency;

  String? _endDate;
  String? get endDate => _$this._endDate;
  set endDate(String? endDate) => _$this._endDate = endDate;

  CreateTransactionRepeatBuilder() {
    CreateTransactionRepeat._defaults(this);
  }

  CreateTransactionRepeatBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _frequency = $v.frequency;
      _endDate = $v.endDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTransactionRepeat other) {
    _$v = other as _$CreateTransactionRepeat;
  }

  @override
  void update(void Function(CreateTransactionRepeatBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTransactionRepeat build() => _build();

  _$CreateTransactionRepeat _build() {
    final _$result =
        _$v ??
        _$CreateTransactionRepeat._(
          frequency: BuiltValueNullFieldError.checkNotNull(
            frequency,
            r'CreateTransactionRepeat',
            'frequency',
          ),
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
