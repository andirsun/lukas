// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_list.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AssistantList extends AssistantList {
  @override
  final BuiltList<Assistant> items;

  factory _$AssistantList([void Function(AssistantListBuilder)? updates]) =>
      (AssistantListBuilder()..update(updates))._build();

  _$AssistantList._({required this.items}) : super._();
  @override
  AssistantList rebuild(void Function(AssistantListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AssistantListBuilder toBuilder() => AssistantListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AssistantList && items == other.items;
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
    return (newBuiltValueToStringHelper(r'AssistantList')..add('items', items)).toString();
  }
}

class AssistantListBuilder implements Builder<AssistantList, AssistantListBuilder> {
  _$AssistantList? _$v;

  ListBuilder<Assistant>? _items;
  ListBuilder<Assistant> get items => _$this._items ??= ListBuilder<Assistant>();
  set items(ListBuilder<Assistant>? items) => _$this._items = items;

  AssistantListBuilder() {
    AssistantList._defaults(this);
  }

  AssistantListBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AssistantList other) {
    _$v = other as _$AssistantList;
  }

  @override
  void update(void Function(AssistantListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AssistantList build() => _build();

  _$AssistantList _build() {
    _$AssistantList _$result;
    try {
      _$result = _$v ?? _$AssistantList._(items: items.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'AssistantList', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
