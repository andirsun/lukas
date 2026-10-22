// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_me_claim_email_send_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1MeClaimEmailSendPostRequest extends V1MeClaimEmailSendPostRequest {
  @override
  final String email;

  factory _$V1MeClaimEmailSendPostRequest([
    void Function(V1MeClaimEmailSendPostRequestBuilder)? updates,
  ]) => (V1MeClaimEmailSendPostRequestBuilder()..update(updates))._build();

  _$V1MeClaimEmailSendPostRequest._({required this.email}) : super._();
  @override
  V1MeClaimEmailSendPostRequest rebuild(
    void Function(V1MeClaimEmailSendPostRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1MeClaimEmailSendPostRequestBuilder toBuilder() =>
      V1MeClaimEmailSendPostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1MeClaimEmailSendPostRequest && email == other.email;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, email.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'V1MeClaimEmailSendPostRequest',
    )..add('email', email)).toString();
  }
}

class V1MeClaimEmailSendPostRequestBuilder
    implements Builder<V1MeClaimEmailSendPostRequest, V1MeClaimEmailSendPostRequestBuilder> {
  _$V1MeClaimEmailSendPostRequest? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  V1MeClaimEmailSendPostRequestBuilder() {
    V1MeClaimEmailSendPostRequest._defaults(this);
  }

  V1MeClaimEmailSendPostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1MeClaimEmailSendPostRequest other) {
    _$v = other as _$V1MeClaimEmailSendPostRequest;
  }

  @override
  void update(void Function(V1MeClaimEmailSendPostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1MeClaimEmailSendPostRequest build() => _build();

  _$V1MeClaimEmailSendPostRequest _build() {
    final _$result =
        _$v ??
        _$V1MeClaimEmailSendPostRequest._(
          email: BuiltValueNullFieldError.checkNotNull(
            email,
            r'V1MeClaimEmailSendPostRequest',
            'email',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
