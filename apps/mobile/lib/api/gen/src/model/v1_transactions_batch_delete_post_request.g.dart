// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_batch_delete_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1TransactionsBatchDeletePostRequest extends V1TransactionsBatchDeletePostRequest {
  @override
  final BuiltList<String> ids;

  factory _$V1TransactionsBatchDeletePostRequest([
    void Function(V1TransactionsBatchDeletePostRequestBuilder)? updates,
  ]) => (V1TransactionsBatchDeletePostRequestBuilder()..update(updates))._build();

  _$V1TransactionsBatchDeletePostRequest._({required this.ids}) : super._();
  @override
  V1TransactionsBatchDeletePostRequest rebuild(
    void Function(V1TransactionsBatchDeletePostRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsBatchDeletePostRequestBuilder toBuilder() =>
      V1TransactionsBatchDeletePostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsBatchDeletePostRequest && ids == other.ids;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ids.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'V1TransactionsBatchDeletePostRequest',
    )..add('ids', ids)).toString();
  }
}

class V1TransactionsBatchDeletePostRequestBuilder
    implements
        Builder<V1TransactionsBatchDeletePostRequest, V1TransactionsBatchDeletePostRequestBuilder> {
  _$V1TransactionsBatchDeletePostRequest? _$v;

  ListBuilder<String>? _ids;
  ListBuilder<String> get ids => _$this._ids ??= ListBuilder<String>();
  set ids(ListBuilder<String>? ids) => _$this._ids = ids;

  V1TransactionsBatchDeletePostRequestBuilder() {
    V1TransactionsBatchDeletePostRequest._defaults(this);
  }

  V1TransactionsBatchDeletePostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ids = $v.ids.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1TransactionsBatchDeletePostRequest other) {
    _$v = other as _$V1TransactionsBatchDeletePostRequest;
  }

  @override
  void update(void Function(V1TransactionsBatchDeletePostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsBatchDeletePostRequest build() => _build();

  _$V1TransactionsBatchDeletePostRequest _build() {
    _$V1TransactionsBatchDeletePostRequest _$result;
    try {
      _$result = _$v ?? _$V1TransactionsBatchDeletePostRequest._(ids: ids.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ids';
        ids.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'V1TransactionsBatchDeletePostRequest',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
