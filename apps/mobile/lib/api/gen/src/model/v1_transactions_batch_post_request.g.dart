// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_batch_post_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1TransactionsBatchPostRequest extends V1TransactionsBatchPostRequest {
  @override
  final BuiltList<V1TransactionsPostRequest> items;

  factory _$V1TransactionsBatchPostRequest([
    void Function(V1TransactionsBatchPostRequestBuilder)? updates,
  ]) => (V1TransactionsBatchPostRequestBuilder()..update(updates))._build();

  _$V1TransactionsBatchPostRequest._({required this.items}) : super._();
  @override
  V1TransactionsBatchPostRequest rebuild(
    void Function(V1TransactionsBatchPostRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsBatchPostRequestBuilder toBuilder() =>
      V1TransactionsBatchPostRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsBatchPostRequest && items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'V1TransactionsBatchPostRequest',
    )..add('items', items)).toString();
  }
}

class V1TransactionsBatchPostRequestBuilder
    implements Builder<V1TransactionsBatchPostRequest, V1TransactionsBatchPostRequestBuilder> {
  _$V1TransactionsBatchPostRequest? _$v;

  ListBuilder<V1TransactionsPostRequest>? _items;
  ListBuilder<V1TransactionsPostRequest> get items =>
      _$this._items ??= ListBuilder<V1TransactionsPostRequest>();
  set items(ListBuilder<V1TransactionsPostRequest>? items) => _$this._items = items;

  V1TransactionsBatchPostRequestBuilder() {
    V1TransactionsBatchPostRequest._defaults(this);
  }

  V1TransactionsBatchPostRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1TransactionsBatchPostRequest other) {
    _$v = other as _$V1TransactionsBatchPostRequest;
  }

  @override
  void update(void Function(V1TransactionsBatchPostRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsBatchPostRequest build() => _build();

  _$V1TransactionsBatchPostRequest _build() {
    _$V1TransactionsBatchPostRequest _$result;
    try {
      _$result = _$v ?? _$V1TransactionsBatchPostRequest._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'V1TransactionsBatchPostRequest',
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
