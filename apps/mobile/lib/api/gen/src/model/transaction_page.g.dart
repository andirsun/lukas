// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransactionPage extends TransactionPage {
  @override
  final BuiltList<Transaction> items;
  @override
  final String? nextCursor;

  factory _$TransactionPage([void Function(TransactionPageBuilder)? updates]) =>
      (TransactionPageBuilder()..update(updates))._build();

  _$TransactionPage._({required this.items, this.nextCursor}) : super._();
  @override
  TransactionPage rebuild(void Function(TransactionPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransactionPageBuilder toBuilder() => TransactionPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransactionPage && items == other.items && nextCursor == other.nextCursor;
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
    return (newBuiltValueToStringHelper(r'TransactionPage')
          ..add('items', items)
          ..add('nextCursor', nextCursor))
        .toString();
  }
}

class TransactionPageBuilder implements Builder<TransactionPage, TransactionPageBuilder> {
  _$TransactionPage? _$v;

  ListBuilder<Transaction>? _items;
  ListBuilder<Transaction> get items => _$this._items ??= ListBuilder<Transaction>();
  set items(ListBuilder<Transaction>? items) => _$this._items = items;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  TransactionPageBuilder() {
    TransactionPage._defaults(this);
  }

  TransactionPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _nextCursor = $v.nextCursor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransactionPage other) {
    _$v = other as _$TransactionPage;
  }

  @override
  void update(void Function(TransactionPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransactionPage build() => _build();

  _$TransactionPage _build() {
    _$TransactionPage _$result;
    try {
      _$result = _$v ?? _$TransactionPage._(items: items.build(), nextCursor: nextCursor);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'TransactionPage', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
