// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_me_get200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1MeGet200Response extends V1MeGet200Response {
  @override
  final String id;
  @override
  final String email;
  @override
  final String timezone;
  @override
  final String locale;
  @override
  final String? onboardingCompletedAt;
  @override
  final String currency;
  @override
  final bool isAnonymous;

  factory _$V1MeGet200Response([void Function(V1MeGet200ResponseBuilder)? updates]) =>
      (V1MeGet200ResponseBuilder()..update(updates))._build();

  _$V1MeGet200Response._({
    required this.id,
    required this.email,
    required this.timezone,
    required this.locale,
    this.onboardingCompletedAt,
    required this.currency,
    required this.isAnonymous,
  }) : super._();
  @override
  V1MeGet200Response rebuild(void Function(V1MeGet200ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1MeGet200ResponseBuilder toBuilder() => V1MeGet200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1MeGet200Response &&
        id == other.id &&
        email == other.email &&
        timezone == other.timezone &&
        locale == other.locale &&
        onboardingCompletedAt == other.onboardingCompletedAt &&
        currency == other.currency &&
        isAnonymous == other.isAnonymous;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, locale.hashCode);
    _$hash = $jc(_$hash, onboardingCompletedAt.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, isAnonymous.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1MeGet200Response')
          ..add('id', id)
          ..add('email', email)
          ..add('timezone', timezone)
          ..add('locale', locale)
          ..add('onboardingCompletedAt', onboardingCompletedAt)
          ..add('currency', currency)
          ..add('isAnonymous', isAnonymous))
        .toString();
  }
}

class V1MeGet200ResponseBuilder implements Builder<V1MeGet200Response, V1MeGet200ResponseBuilder> {
  _$V1MeGet200Response? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  String? _locale;
  String? get locale => _$this._locale;
  set locale(String? locale) => _$this._locale = locale;

  String? _onboardingCompletedAt;
  String? get onboardingCompletedAt => _$this._onboardingCompletedAt;
  set onboardingCompletedAt(String? onboardingCompletedAt) =>
      _$this._onboardingCompletedAt = onboardingCompletedAt;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  bool? _isAnonymous;
  bool? get isAnonymous => _$this._isAnonymous;
  set isAnonymous(bool? isAnonymous) => _$this._isAnonymous = isAnonymous;

  V1MeGet200ResponseBuilder() {
    V1MeGet200Response._defaults(this);
  }

  V1MeGet200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _email = $v.email;
      _timezone = $v.timezone;
      _locale = $v.locale;
      _onboardingCompletedAt = $v.onboardingCompletedAt;
      _currency = $v.currency;
      _isAnonymous = $v.isAnonymous;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1MeGet200Response other) {
    _$v = other as _$V1MeGet200Response;
  }

  @override
  void update(void Function(V1MeGet200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1MeGet200Response build() => _build();

  _$V1MeGet200Response _build() {
    final _$result =
        _$v ??
        _$V1MeGet200Response._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'V1MeGet200Response', 'id'),
          email: BuiltValueNullFieldError.checkNotNull(email, r'V1MeGet200Response', 'email'),
          timezone: BuiltValueNullFieldError.checkNotNull(
            timezone,
            r'V1MeGet200Response',
            'timezone',
          ),
          locale: BuiltValueNullFieldError.checkNotNull(locale, r'V1MeGet200Response', 'locale'),
          onboardingCompletedAt: onboardingCompletedAt,
          currency: BuiltValueNullFieldError.checkNotNull(
            currency,
            r'V1MeGet200Response',
            'currency',
          ),
          isAnonymous: BuiltValueNullFieldError.checkNotNull(
            isAnonymous,
            r'V1MeGet200Response',
            'isAnonymous',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
