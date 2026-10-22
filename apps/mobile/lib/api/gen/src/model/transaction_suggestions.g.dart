// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_suggestions.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransactionSuggestions extends TransactionSuggestions {
  @override
  final BuiltList<TransactionSuggestion> items;

  factory _$TransactionSuggestions([void Function(TransactionSuggestionsBuilder)? updates]) =>
      (TransactionSuggestionsBuilder()..update(updates))._build();

  _$TransactionSuggestions._({required this.items}) : super._();
  @override
  TransactionSuggestions rebuild(void Function(TransactionSuggestionsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransactionSuggestionsBuilder toBuilder() => TransactionSuggestionsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransactionSuggestions && items == other.items;
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
    return (newBuiltValueToStringHelper(r'TransactionSuggestions')..add('items', items)).toString();
  }
}

class TransactionSuggestionsBuilder
    implements Builder<TransactionSuggestions, TransactionSuggestionsBuilder> {
  _$TransactionSuggestions? _$v;

  ListBuilder<TransactionSuggestion>? _items;
  ListBuilder<TransactionSuggestion> get items =>
      _$this._items ??= ListBuilder<TransactionSuggestion>();
  set items(ListBuilder<TransactionSuggestion>? items) => _$this._items = items;

  TransactionSuggestionsBuilder() {
    TransactionSuggestions._defaults(this);
  }

  TransactionSuggestionsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransactionSuggestions other) {
    _$v = other as _$TransactionSuggestions;
  }

  @override
  void update(void Function(TransactionSuggestionsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransactionSuggestions build() => _build();

  _$TransactionSuggestions _build() {
    _$TransactionSuggestions _$result;
    try {
      _$result = _$v ?? _$TransactionSuggestions._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'TransactionSuggestions', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
