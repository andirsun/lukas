// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_transactions_suggestions_get200_response_items_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1TransactionsSuggestionsGet200ResponseItemsInner
    extends V1TransactionsSuggestionsGet200ResponseItemsInner {
  @override
  final String name;
  @override
  final String categoryId;

  factory _$V1TransactionsSuggestionsGet200ResponseItemsInner([
    void Function(V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder)? updates,
  ]) => (V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder()..update(updates))._build();

  _$V1TransactionsSuggestionsGet200ResponseItemsInner._({
    required this.name,
    required this.categoryId,
  }) : super._();
  @override
  V1TransactionsSuggestionsGet200ResponseItemsInner rebuild(
    void Function(V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder toBuilder() =>
      V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1TransactionsSuggestionsGet200ResponseItemsInner &&
        name == other.name &&
        categoryId == other.categoryId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1TransactionsSuggestionsGet200ResponseItemsInner')
          ..add('name', name)
          ..add('categoryId', categoryId))
        .toString();
  }
}

class V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder
    implements
        Builder<
          V1TransactionsSuggestionsGet200ResponseItemsInner,
          V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder
        > {
  _$V1TransactionsSuggestionsGet200ResponseItemsInner? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder() {
    V1TransactionsSuggestionsGet200ResponseItemsInner._defaults(this);
  }

  V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _categoryId = $v.categoryId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1TransactionsSuggestionsGet200ResponseItemsInner other) {
    _$v = other as _$V1TransactionsSuggestionsGet200ResponseItemsInner;
  }

  @override
  void update(void Function(V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1TransactionsSuggestionsGet200ResponseItemsInner build() => _build();

  _$V1TransactionsSuggestionsGet200ResponseItemsInner _build() {
    final _$result =
        _$v ??
        _$V1TransactionsSuggestionsGet200ResponseItemsInner._(
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'V1TransactionsSuggestionsGet200ResponseItemsInner',
            'name',
          ),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1TransactionsSuggestionsGet200ResponseItemsInner',
            'categoryId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
