// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransactionList extends TransactionList {
  @override
  final BuiltList<Transaction> items;

  factory _$TransactionList([void Function(TransactionListBuilder)? updates]) =>
      (TransactionListBuilder()..update(updates))._build();

  _$TransactionList._({required this.items}) : super._();
  @override
  TransactionList rebuild(void Function(TransactionListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransactionListBuilder toBuilder() => TransactionListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransactionList && items == other.items;
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
    return (newBuiltValueToStringHelper(r'TransactionList')..add('items', items)).toString();
  }
}

class TransactionListBuilder implements Builder<TransactionList, TransactionListBuilder> {
  _$TransactionList? _$v;

  ListBuilder<Transaction>? _items;
  ListBuilder<Transaction> get items => _$this._items ??= ListBuilder<Transaction>();
  set items(ListBuilder<Transaction>? items) => _$this._items = items;

  TransactionListBuilder() {
    TransactionList._defaults(this);
  }

  TransactionListBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransactionList other) {
    _$v = other as _$TransactionList;
  }

  @override
  void update(void Function(TransactionListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransactionList build() => _build();

  _$TransactionList _build() {
    _$TransactionList _$result;
    try {
      _$result = _$v ?? _$TransactionList._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'TransactionList', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
