// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Profile extends Profile {
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

  factory _$Profile([void Function(ProfileBuilder)? updates]) =>
      (ProfileBuilder()..update(updates))._build();

  _$Profile._({
    required this.id,
    required this.email,
    required this.timezone,
    required this.locale,
    this.onboardingCompletedAt,
    required this.currency,
    required this.isAnonymous,
  }) : super._();
  @override
  Profile rebuild(void Function(ProfileBuilder) updates) => (toBuilder()..update(updates)).build();

  @override
  ProfileBuilder toBuilder() => ProfileBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Profile &&
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
    return (newBuiltValueToStringHelper(r'Profile')
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

class ProfileBuilder implements Builder<Profile, ProfileBuilder> {
  _$Profile? _$v;

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

  ProfileBuilder() {
    Profile._defaults(this);
  }

  ProfileBuilder get _$this {
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
  void replace(Profile other) {
    _$v = other as _$Profile;
  }

  @override
  void update(void Function(ProfileBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Profile build() => _build();

  _$Profile _build() {
    final _$result =
        _$v ??
        _$Profile._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Profile', 'id'),
          email: BuiltValueNullFieldError.checkNotNull(email, r'Profile', 'email'),
          timezone: BuiltValueNullFieldError.checkNotNull(timezone, r'Profile', 'timezone'),
          locale: BuiltValueNullFieldError.checkNotNull(locale, r'Profile', 'locale'),
          onboardingCompletedAt: onboardingCompletedAt,
          currency: BuiltValueNullFieldError.checkNotNull(currency, r'Profile', 'currency'),
          isAnonymous: BuiltValueNullFieldError.checkNotNull(
            isAnonymous,
            r'Profile',
            'isAnonymous',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
