// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_batch_post201_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1TransactionsBatchPost201Response extends V1TransactionsBatchPost201Response {
  @override
  final BuiltList<V1TransactionsGet200ResponseItemsInner> items;

  factory _$V1TransactionsBatchPost201Response([
    void Function(V1TransactionsBatchPost201ResponseBuilder)? updates,
  ]) => (V1TransactionsBatchPost201ResponseBuilder()..update(updates))._build();

  _$V1TransactionsBatchPost201Response._({required this.items}) : super._();
  @override
  V1TransactionsBatchPost201Response rebuild(
    void Function(V1TransactionsBatchPost201ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsBatchPost201ResponseBuilder toBuilder() =>
      V1TransactionsBatchPost201ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsBatchPost201Response && items == other.items;
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
      r'V1TransactionsBatchPost201Response',
    )..add('items', items)).toString();
  }
}

class V1TransactionsBatchPost201ResponseBuilder
    implements
        Builder<V1TransactionsBatchPost201Response, V1TransactionsBatchPost201ResponseBuilder> {
  _$V1TransactionsBatchPost201Response? _$v;

  ListBuilder<V1TransactionsGet200ResponseItemsInner>? _items;
  ListBuilder<V1TransactionsGet200ResponseItemsInner> get items =>
      _$this._items ??= ListBuilder<V1TransactionsGet200ResponseItemsInner>();
  set items(ListBuilder<V1TransactionsGet200ResponseItemsInner>? items) => _$this._items = items;

  V1TransactionsBatchPost201ResponseBuilder() {
    V1TransactionsBatchPost201Response._defaults(this);
  }

  V1TransactionsBatchPost201ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1TransactionsBatchPost201Response other) {
    _$v = other as _$V1TransactionsBatchPost201Response;
  }

  @override
  void update(void Function(V1TransactionsBatchPost201ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsBatchPost201Response build() => _build();

  _$V1TransactionsBatchPost201Response _build() {
    _$V1TransactionsBatchPost201Response _$result;
    try {
      _$result = _$v ?? _$V1TransactionsBatchPost201Response._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'V1TransactionsBatchPost201Response',
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
