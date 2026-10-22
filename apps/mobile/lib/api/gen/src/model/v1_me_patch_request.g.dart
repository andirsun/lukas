// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_me_patch_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1MePatchRequestLocaleEnum _$v1MePatchRequestLocaleEnum_es =
    const V1MePatchRequestLocaleEnum._('es');
const V1MePatchRequestLocaleEnum _$v1MePatchRequestLocaleEnum_en =
    const V1MePatchRequestLocaleEnum._('en');

V1MePatchRequestLocaleEnum _$v1MePatchRequestLocaleEnumValueOf(String name) {
  switch (name) {
    case 'es':
      return _$v1MePatchRequestLocaleEnum_es;
    case 'en':
      return _$v1MePatchRequestLocaleEnum_en;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1MePatchRequestLocaleEnum> _$v1MePatchRequestLocaleEnumValues =
    BuiltSet<V1MePatchRequestLocaleEnum>(const <V1MePatchRequestLocaleEnum>[
      _$v1MePatchRequestLocaleEnum_es,
      _$v1MePatchRequestLocaleEnum_en,
    ]);

const V1MePatchRequestCurrencyEnum _$v1MePatchRequestCurrencyEnum_COP =
    const V1MePatchRequestCurrencyEnum._('COP');
const V1MePatchRequestCurrencyEnum _$v1MePatchRequestCurrencyEnum_USD =
    const V1MePatchRequestCurrencyEnum._('USD');
const V1MePatchRequestCurrencyEnum _$v1MePatchRequestCurrencyEnum_EUR =
    const V1MePatchRequestCurrencyEnum._('EUR');

V1MePatchRequestCurrencyEnum _$v1MePatchRequestCurrencyEnumValueOf(String name) {
  switch (name) {
    case 'COP':
      return _$v1MePatchRequestCurrencyEnum_COP;
    case 'USD':
      return _$v1MePatchRequestCurrencyEnum_USD;
    case 'EUR':
      return _$v1MePatchRequestCurrencyEnum_EUR;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1MePatchRequestCurrencyEnum> _$v1MePatchRequestCurrencyEnumValues =
    BuiltSet<V1MePatchRequestCurrencyEnum>(const <V1MePatchRequestCurrencyEnum>[
      _$v1MePatchRequestCurrencyEnum_COP,
      _$v1MePatchRequestCurrencyEnum_USD,
      _$v1MePatchRequestCurrencyEnum_EUR,
    ]);

const V1MePatchRequestOnboardingCompletedEnum _$v1MePatchRequestOnboardingCompletedEnum_true_ =
    const V1MePatchRequestOnboardingCompletedEnum._('true_');

V1MePatchRequestOnboardingCompletedEnum _$v1MePatchRequestOnboardingCompletedEnumValueOf(
  String name,
) {
  switch (name) {
    case 'true_':
      return _$v1MePatchRequestOnboardingCompletedEnum_true_;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1MePatchRequestOnboardingCompletedEnum>
_$v1MePatchRequestOnboardingCompletedEnumValues = BuiltSet<V1MePatchRequestOnboardingCompletedEnum>(
  const <V1MePatchRequestOnboardingCompletedEnum>[_$v1MePatchRequestOnboardingCompletedEnum_true_],
);

Serializer<V1MePatchRequestLocaleEnum> _$v1MePatchRequestLocaleEnumSerializer =
    _$V1MePatchRequestLocaleEnumSerializer();
Serializer<V1MePatchRequestCurrencyEnum> _$v1MePatchRequestCurrencyEnumSerializer =
    _$V1MePatchRequestCurrencyEnumSerializer();
Serializer<V1MePatchRequestOnboardingCompletedEnum>
_$v1MePatchRequestOnboardingCompletedEnumSerializer =
    _$V1MePatchRequestOnboardingCompletedEnumSerializer();

class _$V1MePatchRequestLocaleEnumSerializer
    implements PrimitiveSerializer<V1MePatchRequestLocaleEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'es': 'es', 'en': 'en'};
  static const Map<Object, String> _fromWire = const <Object, String>{'es': 'es', 'en': 'en'};

  @override
  final Iterable<Type> types = const <Type>[V1MePatchRequestLocaleEnum];
  @override
  final String wireName = 'V1MePatchRequestLocaleEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1MePatchRequestLocaleEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1MePatchRequestLocaleEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1MePatchRequestLocaleEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1MePatchRequestCurrencyEnumSerializer
    implements PrimitiveSerializer<V1MePatchRequestCurrencyEnum> {
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
  final Iterable<Type> types = const <Type>[V1MePatchRequestCurrencyEnum];
  @override
  final String wireName = 'V1MePatchRequestCurrencyEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1MePatchRequestCurrencyEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1MePatchRequestCurrencyEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1MePatchRequestCurrencyEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1MePatchRequestOnboardingCompletedEnumSerializer
    implements PrimitiveSerializer<V1MePatchRequestOnboardingCompletedEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'true_': 'true'};
  static const Map<Object, String> _fromWire = const <Object, String>{'true': 'true_'};

  @override
  final Iterable<Type> types = const <Type>[V1MePatchRequestOnboardingCompletedEnum];
  @override
  final String wireName = 'V1MePatchRequestOnboardingCompletedEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1MePatchRequestOnboardingCompletedEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1MePatchRequestOnboardingCompletedEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1MePatchRequestOnboardingCompletedEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1MePatchRequest extends V1MePatchRequest {
  @override
  final String? timezone;
  @override
  final V1MePatchRequestLocaleEnum? locale;
  @override
  final V1MePatchRequestCurrencyEnum? currency;
  @override
  final V1MePatchRequestOnboardingCompletedEnum? onboardingCompleted;

  factory _$V1MePatchRequest([void Function(V1MePatchRequestBuilder)? updates]) =>
      (V1MePatchRequestBuilder()..update(updates))._build();

  _$V1MePatchRequest._({this.timezone, this.locale, this.currency, this.onboardingCompleted})
    : super._();
  @override
  V1MePatchRequest rebuild(void Function(V1MePatchRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1MePatchRequestBuilder toBuilder() => V1MePatchRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1MePatchRequest &&
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
    return (newBuiltValueToStringHelper(r'V1MePatchRequest')
          ..add('timezone', timezone)
          ..add('locale', locale)
          ..add('currency', currency)
          ..add('onboardingCompleted', onboardingCompleted))
        .toString();
  }
}

class V1MePatchRequestBuilder implements Builder<V1MePatchRequest, V1MePatchRequestBuilder> {
  _$V1MePatchRequest? _$v;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  V1MePatchRequestLocaleEnum? _locale;
  V1MePatchRequestLocaleEnum? get locale => _$this._locale;
  set locale(V1MePatchRequestLocaleEnum? locale) => _$this._locale = locale;

  V1MePatchRequestCurrencyEnum? _currency;
  V1MePatchRequestCurrencyEnum? get currency => _$this._currency;
  set currency(V1MePatchRequestCurrencyEnum? currency) => _$this._currency = currency;

  V1MePatchRequestOnboardingCompletedEnum? _onboardingCompleted;
  V1MePatchRequestOnboardingCompletedEnum? get onboardingCompleted => _$this._onboardingCompleted;
  set onboardingCompleted(V1MePatchRequestOnboardingCompletedEnum? onboardingCompleted) =>
      _$this._onboardingCompleted = onboardingCompleted;

  V1MePatchRequestBuilder() {
    V1MePatchRequest._defaults(this);
  }

  V1MePatchRequestBuilder get _$this {
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
  void replace(V1MePatchRequest other) {
    _$v = other as _$V1MePatchRequest;
  }

  @override
  void update(void Function(V1MePatchRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1MePatchRequest build() => _build();

  _$V1MePatchRequest _build() {
    final _$result =
        _$v ??
        _$V1MePatchRequest._(
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
