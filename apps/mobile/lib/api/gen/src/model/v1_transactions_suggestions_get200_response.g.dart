// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_suggestions_get200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1TransactionsSuggestionsGet200Response extends V1TransactionsSuggestionsGet200Response {
  @override
  final BuiltList<V1TransactionsSuggestionsGet200ResponseItemsInner> items;

  factory _$V1TransactionsSuggestionsGet200Response([
    void Function(V1TransactionsSuggestionsGet200ResponseBuilder)? updates,
  ]) => (V1TransactionsSuggestionsGet200ResponseBuilder()..update(updates))._build();

  _$V1TransactionsSuggestionsGet200Response._({required this.items}) : super._();
  @override
  V1TransactionsSuggestionsGet200Response rebuild(
    void Function(V1TransactionsSuggestionsGet200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsSuggestionsGet200ResponseBuilder toBuilder() =>
      V1TransactionsSuggestionsGet200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsSuggestionsGet200Response && items == other.items;
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
      r'V1TransactionsSuggestionsGet200Response',
    )..add('items', items)).toString();
  }
}

class V1TransactionsSuggestionsGet200ResponseBuilder
    implements
        Builder<
          V1TransactionsSuggestionsGet200Response,
          V1TransactionsSuggestionsGet200ResponseBuilder
        > {
  _$V1TransactionsSuggestionsGet200Response? _$v;

  ListBuilder<V1TransactionsSuggestionsGet200ResponseItemsInner>? _items;
  ListBuilder<V1TransactionsSuggestionsGet200ResponseItemsInner> get items =>
      _$this._items ??= ListBuilder<V1TransactionsSuggestionsGet200ResponseItemsInner>();
  set items(ListBuilder<V1TransactionsSuggestionsGet200ResponseItemsInner>? items) =>
      _$this._items = items;

  V1TransactionsSuggestionsGet200ResponseBuilder() {
    V1TransactionsSuggestionsGet200Response._defaults(this);
  }

  V1TransactionsSuggestionsGet200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1TransactionsSuggestionsGet200Response other) {
    _$v = other as _$V1TransactionsSuggestionsGet200Response;
  }

  @override
  void update(void Function(V1TransactionsSuggestionsGet200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsSuggestionsGet200Response build() => _build();

  _$V1TransactionsSuggestionsGet200Response _build() {
    _$V1TransactionsSuggestionsGet200Response _$result;
    try {
      _$result = _$v ?? _$V1TransactionsSuggestionsGet200Response._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'V1TransactionsSuggestionsGet200Response',
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
