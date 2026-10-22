// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_transactions_batch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeleteTransactionsBatch extends DeleteTransactionsBatch {
  @override
  final BuiltList<String> ids;

  factory _$DeleteTransactionsBatch([void Function(DeleteTransactionsBatchBuilder)? updates]) =>
      (DeleteTransactionsBatchBuilder()..update(updates))._build();

  _$DeleteTransactionsBatch._({required this.ids}) : super._();
  @override
  DeleteTransactionsBatch rebuild(void Function(DeleteTransactionsBatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeleteTransactionsBatchBuilder toBuilder() => DeleteTransactionsBatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeleteTransactionsBatch && ids == other.ids;
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
    return (newBuiltValueToStringHelper(r'DeleteTransactionsBatch')..add('ids', ids)).toString();
  }
}

class DeleteTransactionsBatchBuilder
    implements Builder<DeleteTransactionsBatch, DeleteTransactionsBatchBuilder> {
  _$DeleteTransactionsBatch? _$v;

  ListBuilder<String>? _ids;
  ListBuilder<String> get ids => _$this._ids ??= ListBuilder<String>();
  set ids(ListBuilder<String>? ids) => _$this._ids = ids;

  DeleteTransactionsBatchBuilder() {
    DeleteTransactionsBatch._defaults(this);
  }

  DeleteTransactionsBatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ids = $v.ids.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeleteTransactionsBatch other) {
    _$v = other as _$DeleteTransactionsBatch;
  }

  @override
  void update(void Function(DeleteTransactionsBatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeleteTransactionsBatch build() => _build();

  _$DeleteTransactionsBatch _build() {
    _$DeleteTransactionsBatch _$result;
    try {
      _$result = _$v ?? _$DeleteTransactionsBatch._(ids: ids.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ids';
        ids.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'DeleteTransactionsBatch', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
