// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_me_claim_email_verify_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1MeClaimEmailVerifyPostRequest extends V1MeClaimEmailVerifyPostRequest {
  @override
  final String email;
  @override
  final String code;

  factory _$V1MeClaimEmailVerifyPostRequest([
    void Function(V1MeClaimEmailVerifyPostRequestBuilder)? updates,
  ]) => (V1MeClaimEmailVerifyPostRequestBuilder()..update(updates))._build();

  _$V1MeClaimEmailVerifyPostRequest._({required this.email, required this.code}) : super._();
  @override
  V1MeClaimEmailVerifyPostRequest rebuild(
    void Function(V1MeClaimEmailVerifyPostRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1MeClaimEmailVerifyPostRequestBuilder toBuilder() =>
      V1MeClaimEmailVerifyPostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1MeClaimEmailVerifyPostRequest && email == other.email && code == other.code;
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
    return (newBuiltValueToStringHelper(r'V1MeClaimEmailVerifyPostRequest')
          ..add('email', email)
          ..add('code', code))
        .toString();
  }
}

class V1MeClaimEmailVerifyPostRequestBuilder
    implements Builder<V1MeClaimEmailVerifyPostRequest, V1MeClaimEmailVerifyPostRequestBuilder> {
  _$V1MeClaimEmailVerifyPostRequest? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  V1MeClaimEmailVerifyPostRequestBuilder() {
    V1MeClaimEmailVerifyPostRequest._defaults(this);
  }

  V1MeClaimEmailVerifyPostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _code = $v.code;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1MeClaimEmailVerifyPostRequest other) {
    _$v = other as _$V1MeClaimEmailVerifyPostRequest;
  }

  @override
  void update(void Function(V1MeClaimEmailVerifyPostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1MeClaimEmailVerifyPostRequest build() => _build();

  _$V1MeClaimEmailVerifyPostRequest _build() {
    final _$result =
        _$v ??
        _$V1MeClaimEmailVerifyPostRequest._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'V1MeClaimEmailVerifyPostRequest',
            'email',
          ),
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'V1MeClaimEmailVerifyPostRequest',
            'code',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
