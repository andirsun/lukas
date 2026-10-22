// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_imports_id_confirm_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ImportsIdConfirmPostRequest extends V1ImportsIdConfirmPostRequest {
  @override
  final bool? adoptFileCurrency;

  factory _$V1ImportsIdConfirmPostRequest([
    void Function(V1ImportsIdConfirmPostRequestBuilder)? updates,
  ]) => (V1ImportsIdConfirmPostRequestBuilder()..update(updates))._build();

  _$V1ImportsIdConfirmPostRequest._({this.adoptFileCurrency}) : super._();
  @override
  V1ImportsIdConfirmPostRequest rebuild(
    void Function(V1ImportsIdConfirmPostRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ImportsIdConfirmPostRequestBuilder toBuilder() =>
      V1ImportsIdConfirmPostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ImportsIdConfirmPostRequest && adoptFileCurrency == other.adoptFileCurrency;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adoptFileCurrency.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'V1ImportsIdConfirmPostRequest',
    )..add('adoptFileCurrency', adoptFileCurrency)).toString();
  }
}

class V1ImportsIdConfirmPostRequestBuilder
    implements Builder<V1ImportsIdConfirmPostRequest, V1ImportsIdConfirmPostRequestBuilder> {
  _$V1ImportsIdConfirmPostRequest? _$v;

  bool? _adoptFileCurrency;
  bool? get adoptFileCurrency => _$this._adoptFileCurrency;
  set adoptFileCurrency(bool? adoptFileCurrency) => _$this._adoptFileCurrency = adoptFileCurrency;

  V1ImportsIdConfirmPostRequestBuilder() {
    V1ImportsIdConfirmPostRequest._defaults(this);
  }

  V1ImportsIdConfirmPostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adoptFileCurrency = $v.adoptFileCurrency;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1ImportsIdConfirmPostRequest other) {
    _$v = other as _$V1ImportsIdConfirmPostRequest;
  }

  @override
  void update(void Function(V1ImportsIdConfirmPostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ImportsIdConfirmPostRequest build() => _build();

  _$V1ImportsIdConfirmPostRequest _build() {
    final _$result = _$v ?? _$V1ImportsIdConfirmPostRequest._(adoptFileCurrency: adoptFileCurrency);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
