// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_suggestion.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransactionSuggestion extends TransactionSuggestion {
  @override
  final String name;
  @override
  final String categoryId;

  factory _$TransactionSuggestion([void Function(TransactionSuggestionBuilder)? updates]) =>
      (TransactionSuggestionBuilder()..update(updates))._build();

  _$TransactionSuggestion._({required this.name, required this.categoryId}) : super._();
  @override
  TransactionSuggestion rebuild(void Function(TransactionSuggestionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransactionSuggestionBuilder toBuilder() => TransactionSuggestionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransactionSuggestion && name == other.name && categoryId == other.categoryId;
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
    return (newBuiltValueToStringHelper(r'TransactionSuggestion')
          ..add('name', name)
          ..add('categoryId', categoryId))
        .toString();
  }
}

class TransactionSuggestionBuilder
    implements Builder<TransactionSuggestion, TransactionSuggestionBuilder> {
  _$TransactionSuggestion? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  TransactionSuggestionBuilder() {
    TransactionSuggestion._defaults(this);
  }

  TransactionSuggestionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _categoryId = $v.categoryId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransactionSuggestion other) {
    _$v = other as _$TransactionSuggestion;
  }

  @override
  void update(void Function(TransactionSuggestionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransactionSuggestion build() => _build();

  _$TransactionSuggestion _build() {
    final _$result =
        _$v ??
        _$TransactionSuggestion._(
          name: BuiltValueNullFieldError.checkNotNull(name, r'TransactionSuggestion', 'name'),
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'TransactionSuggestion',
            'categoryId',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
