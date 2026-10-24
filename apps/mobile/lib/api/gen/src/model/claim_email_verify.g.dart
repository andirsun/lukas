// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_email_verify.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ClaimEmailVerify extends ClaimEmailVerify {
  @override
  final String email;
  @override
  final String code;

  factory _$ClaimEmailVerify([void Function(ClaimEmailVerifyBuilder)? updates]) =>
      (ClaimEmailVerifyBuilder()..update(updates))._build();

  _$ClaimEmailVerify._({required this.email, required this.code}) : super._();
  @override
  ClaimEmailVerify rebuild(void Function(ClaimEmailVerifyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ClaimEmailVerifyBuilder toBuilder() => ClaimEmailVerifyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ClaimEmailVerify && email == other.email && code == other.code;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ClaimEmailVerify')
          ..add('email', email)
          ..add('code', code))
        .toString();
  }
}

class ClaimEmailVerifyBuilder implements Builder<ClaimEmailVerify, ClaimEmailVerifyBuilder> {
  _$ClaimEmailVerify? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  ClaimEmailVerifyBuilder() {
    ClaimEmailVerify._defaults(this);
  }

  ClaimEmailVerifyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _code = $v.code;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ClaimEmailVerify other) {
    _$v = other as _$ClaimEmailVerify;
  }

  @override
  void update(void Function(ClaimEmailVerifyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ClaimEmailVerify build() => _build();

  _$ClaimEmailVerify _build() {
    final _$result =
        _$v ??
        _$ClaimEmailVerify._(
          email: BuiltValueNullFieldError.checkNotNull(email, r'ClaimEmailVerify', 'email'),
          code: BuiltValueNullFieldError.checkNotNull(code, r'ClaimEmailVerify', 'code'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
