// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_email_send.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ClaimEmailSend extends ClaimEmailSend {
  @override
  final String email;

  factory _$ClaimEmailSend([void Function(ClaimEmailSendBuilder)? updates]) =>
      (ClaimEmailSendBuilder()..update(updates))._build();

  _$ClaimEmailSend._({required this.email}) : super._();
  @override
  ClaimEmailSend rebuild(void Function(ClaimEmailSendBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ClaimEmailSendBuilder toBuilder() => ClaimEmailSendBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ClaimEmailSend && email == other.email;
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
    return (newBuiltValueToStringHelper(r'ClaimEmailSend')..add('email', email)).toString();
  }
}

class ClaimEmailSendBuilder implements Builder<ClaimEmailSend, ClaimEmailSendBuilder> {
  _$ClaimEmailSend? _$v;

  String? _email;
  String? get email => _$this._email;
  set email(String? email) => _$this._email = email;

  ClaimEmailSendBuilder() {
    ClaimEmailSend._defaults(this);
  }

  ClaimEmailSendBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _email = $v.email;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ClaimEmailSend other) {
    _$v = other as _$ClaimEmailSend;
  }

  @override
  void update(void Function(ClaimEmailSendBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ClaimEmailSend build() => _build();

  _$ClaimEmailSend _build() {
    final _$result =
        _$v ??
        _$ClaimEmailSend._(
          email: BuiltValueNullFieldError.checkNotNull(email, r'ClaimEmailSend', 'email'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
