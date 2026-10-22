// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_get200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1TransactionsGet200Response extends V1TransactionsGet200Response {
  @override
  final BuiltList<V1TransactionsGet200ResponseItemsInner> items;
  @override
  final String? nextCursor;

  factory _$V1TransactionsGet200Response([
    void Function(V1TransactionsGet200ResponseBuilder)? updates,
  ]) => (V1TransactionsGet200ResponseBuilder()..update(updates))._build();

  _$V1TransactionsGet200Response._({required this.items, this.nextCursor}) : super._();
  @override
  V1TransactionsGet200Response rebuild(
    void Function(V1TransactionsGet200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsGet200ResponseBuilder toBuilder() =>
      V1TransactionsGet200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsGet200Response &&
        items == other.items &&
        nextCursor == other.nextCursor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, nextCursor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1TransactionsGet200Response')
          ..add('items', items)
          ..add('nextCursor', nextCursor))
        .toString();
  }
}

class V1TransactionsGet200ResponseBuilder
    implements Builder<V1TransactionsGet200Response, V1TransactionsGet200ResponseBuilder> {
  _$V1TransactionsGet200Response? _$v;

  ListBuilder<V1TransactionsGet200ResponseItemsInner>? _items;
  ListBuilder<V1TransactionsGet200ResponseItemsInner> get items =>
      _$this._items ??= ListBuilder<V1TransactionsGet200ResponseItemsInner>();
  set items(ListBuilder<V1TransactionsGet200ResponseItemsInner>? items) => _$this._items = items;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  V1TransactionsGet200ResponseBuilder() {
    V1TransactionsGet200Response._defaults(this);
  }

  V1TransactionsGet200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _nextCursor = $v.nextCursor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1TransactionsGet200Response other) {
    _$v = other as _$V1TransactionsGet200Response;
  }

  @override
  void update(void Function(V1TransactionsGet200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsGet200Response build() => _build();

  _$V1TransactionsGet200Response _build() {
    _$V1TransactionsGet200Response _$result;
    try {
      _$result =
          _$v ?? _$V1TransactionsGet200Response._(items: items.build(), nextCursor: nextCursor);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'V1TransactionsGet200Response',
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
