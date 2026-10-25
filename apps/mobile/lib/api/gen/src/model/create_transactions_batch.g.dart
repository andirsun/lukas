// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_transactions_batch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateTransactionsBatch extends CreateTransactionsBatch {
  @override
  final BuiltList<CreateTransaction> items;

  factory _$CreateTransactionsBatch([void Function(CreateTransactionsBatchBuilder)? updates]) =>
      (CreateTransactionsBatchBuilder()..update(updates))._build();

  _$CreateTransactionsBatch._({required this.items}) : super._();
  @override
  CreateTransactionsBatch rebuild(void Function(CreateTransactionsBatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTransactionsBatchBuilder toBuilder() => CreateTransactionsBatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTransactionsBatch && items == other.items;
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
      r'CreateTransactionsBatch',
    )..add('items', items)).toString();
  }
}

class CreateTransactionsBatchBuilder
    implements Builder<CreateTransactionsBatch, CreateTransactionsBatchBuilder> {
  _$CreateTransactionsBatch? _$v;

  ListBuilder<CreateTransaction>? _items;
  ListBuilder<CreateTransaction> get items => _$this._items ??= ListBuilder<CreateTransaction>();
  set items(ListBuilder<CreateTransaction>? items) => _$this._items = items;

  CreateTransactionsBatchBuilder() {
    CreateTransactionsBatch._defaults(this);
  }

  CreateTransactionsBatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTransactionsBatch other) {
    _$v = other as _$CreateTransactionsBatch;
  }

  @override
  void update(void Function(CreateTransactionsBatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTransactionsBatch build() => _build();

  _$CreateTransactionsBatch _build() {
    _$CreateTransactionsBatch _$result;
    try {
      _$result = _$v ?? _$CreateTransactionsBatch._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'CreateTransactionsBatch', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
