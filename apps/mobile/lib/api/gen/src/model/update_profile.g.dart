// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateProfileLocaleEnum _$updateProfileLocaleEnum_es = const UpdateProfileLocaleEnum._('es');
const UpdateProfileLocaleEnum _$updateProfileLocaleEnum_en = const UpdateProfileLocaleEnum._('en');

UpdateProfileLocaleEnum _$updateProfileLocaleEnumValueOf(String name) {
  switch (name) {
    case 'es':
      return _$updateProfileLocaleEnum_es;
    case 'en':
      return _$updateProfileLocaleEnum_en;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateProfileLocaleEnum> _$updateProfileLocaleEnumValues =
    BuiltSet<UpdateProfileLocaleEnum>(const <UpdateProfileLocaleEnum>[
      _$updateProfileLocaleEnum_es,
      _$updateProfileLocaleEnum_en,
    ]);

const UpdateProfileCurrencyEnum _$updateProfileCurrencyEnum_COP = const UpdateProfileCurrencyEnum._(
  'COP',
);
const UpdateProfileCurrencyEnum _$updateProfileCurrencyEnum_USD = const UpdateProfileCurrencyEnum._(
  'USD',
);
const UpdateProfileCurrencyEnum _$updateProfileCurrencyEnum_EUR = const UpdateProfileCurrencyEnum._(
  'EUR',
);

UpdateProfileCurrencyEnum _$updateProfileCurrencyEnumValueOf(String name) {
  switch (name) {
    case 'COP':
      return _$updateProfileCurrencyEnum_COP;
    case 'USD':
      return _$updateProfileCurrencyEnum_USD;
    case 'EUR':
      return _$updateProfileCurrencyEnum_EUR;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateProfileCurrencyEnum> _$updateProfileCurrencyEnumValues =
    BuiltSet<UpdateProfileCurrencyEnum>(const <UpdateProfileCurrencyEnum>[
      _$updateProfileCurrencyEnum_COP,
      _$updateProfileCurrencyEnum_USD,
      _$updateProfileCurrencyEnum_EUR,
    ]);

const UpdateProfileOnboardingCompletedEnum _$updateProfileOnboardingCompletedEnum_true_ =
    const UpdateProfileOnboardingCompletedEnum._('true_');

UpdateProfileOnboardingCompletedEnum _$updateProfileOnboardingCompletedEnumValueOf(String name) {
  switch (name) {
    case 'true_':
      return _$updateProfileOnboardingCompletedEnum_true_;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateProfileOnboardingCompletedEnum> _$updateProfileOnboardingCompletedEnumValues =
    BuiltSet<UpdateProfileOnboardingCompletedEnum>(const <UpdateProfileOnboardingCompletedEnum>[
      _$updateProfileOnboardingCompletedEnum_true_,
    ]);

Serializer<UpdateProfileLocaleEnum> _$updateProfileLocaleEnumSerializer =
    _$UpdateProfileLocaleEnumSerializer();
Serializer<UpdateProfileCurrencyEnum> _$updateProfileCurrencyEnumSerializer =
    _$UpdateProfileCurrencyEnumSerializer();
Serializer<UpdateProfileOnboardingCompletedEnum> _$updateProfileOnboardingCompletedEnumSerializer =
    _$UpdateProfileOnboardingCompletedEnumSerializer();

class _$UpdateProfileLocaleEnumSerializer implements PrimitiveSerializer<UpdateProfileLocaleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'es': 'es', 'en': 'en'};
  static const Map<Object, String> _fromWire = const <Object, String>{'es': 'es', 'en': 'en'};

  @override
  final Iterable<Type> types = const <Type>[UpdateProfileLocaleEnum];
  @override
  final String wireName = 'UpdateProfileLocaleEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateProfileLocaleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateProfileLocaleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateProfileLocaleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateProfileCurrencyEnumSerializer
    implements PrimitiveSerializer<UpdateProfileCurrencyEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'COP': 'COP',
    'USD': 'USD',
    'EUR': 'EUR',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'COP': 'COP',
    'USD': 'USD',
    'EUR': 'EUR',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateProfileCurrencyEnum];
  @override
  final String wireName = 'UpdateProfileCurrencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateProfileCurrencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateProfileCurrencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateProfileCurrencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateProfileOnboardingCompletedEnumSerializer
    implements PrimitiveSerializer<UpdateProfileOnboardingCompletedEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'true_': 'true'};
  static const Map<Object, String> _fromWire = const <Object, String>{'true': 'true_'};

  @override
  final Iterable<Type> types = const <Type>[UpdateProfileOnboardingCompletedEnum];
  @override
  final String wireName = 'UpdateProfileOnboardingCompletedEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateProfileOnboardingCompletedEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateProfileOnboardingCompletedEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateProfileOnboardingCompletedEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateProfile extends UpdateProfile {
  @override
  final String? timezone;
  @override
  final UpdateProfileLocaleEnum? locale;
  @override
  final UpdateProfileCurrencyEnum? currency;
  @override
  final UpdateProfileOnboardingCompletedEnum? onboardingCompleted;

  factory _$UpdateProfile([void Function(UpdateProfileBuilder)? updates]) =>
      (UpdateProfileBuilder()..update(updates))._build();

  _$UpdateProfile._({this.timezone, this.locale, this.currency, this.onboardingCompleted})
    : super._();
  @override
  UpdateProfile rebuild(void Function(UpdateProfileBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateProfileBuilder toBuilder() => UpdateProfileBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateProfile &&
        timezone == other.timezone &&
        locale == other.locale &&
        currency == other.currency &&
        onboardingCompleted == other.onboardingCompleted;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, onboardingCompleted.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateProfile')
          ..add('timezone', timezone)
          ..add('locale', locale)
          ..add('currency', currency)
          ..add('onboardingCompleted', onboardingCompleted))
        .toString();
  }
}

class UpdateProfileBuilder implements Builder<UpdateProfile, UpdateProfileBuilder> {
  _$UpdateProfile? _$v;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  UpdateProfileLocaleEnum? _locale;
  UpdateProfileLocaleEnum? get locale => _$this._locale;
  set locale(UpdateProfileLocaleEnum? locale) => _$this._locale = locale;

  UpdateProfileCurrencyEnum? _currency;
  UpdateProfileCurrencyEnum? get currency => _$this._currency;
  set currency(UpdateProfileCurrencyEnum? currency) => _$this._currency = currency;

  UpdateProfileOnboardingCompletedEnum? _onboardingCompleted;
  UpdateProfileOnboardingCompletedEnum? get onboardingCompleted => _$this._onboardingCompleted;
  set onboardingCompleted(UpdateProfileOnboardingCompletedEnum? onboardingCompleted) =>
      _$this._onboardingCompleted = onboardingCompleted;

  UpdateProfileBuilder() {
    UpdateProfile._defaults(this);
  }

  UpdateProfileBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _timezone = $v.timezone;
      _locale = $v.locale;
      _currency = $v.currency;
      _onboardingCompleted = $v.onboardingCompleted;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateProfile other) {
    _$v = other as _$UpdateProfile;
  }

  @override
  void update(void Function(UpdateProfileBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateProfile build() => _build();

  _$UpdateProfile _build() {
    final _$result =
        _$v ??
        _$UpdateProfile._(
          timezone: timezone,
          locale: locale,
          currency: currency,
          onboardingCompleted: onboardingCompleted,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
