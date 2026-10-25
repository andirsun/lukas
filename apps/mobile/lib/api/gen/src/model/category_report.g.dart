// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_report.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CategoryReport extends CategoryReport {
  @override
  final int total;
  @override
  final BuiltList<CategoryReportItemsInner> items;

  factory _$CategoryReport([void Function(CategoryReportBuilder)? updates]) =>
      (CategoryReportBuilder()..update(updates))._build();

  _$CategoryReport._({required this.total, required this.items}) : super._();
  @override
  CategoryReport rebuild(void Function(CategoryReportBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CategoryReportBuilder toBuilder() => CategoryReportBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CategoryReport && total == other.total && items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CategoryReport')
          ..add('total', total)
          ..add('items', items))
        .toString();
  }
}

class CategoryReportBuilder implements Builder<CategoryReport, CategoryReportBuilder> {
  _$CategoryReport? _$v;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  ListBuilder<CategoryReportItemsInner>? _items;
  ListBuilder<CategoryReportItemsInner> get items =>
      _$this._items ??= ListBuilder<CategoryReportItemsInner>();
  set items(ListBuilder<CategoryReportItemsInner>? items) => _$this._items = items;

  CategoryReportBuilder() {
    CategoryReport._defaults(this);
  }

  CategoryReportBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _total = $v.total;
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CategoryReport other) {
    _$v = other as _$CategoryReport;
  }

  @override
  void update(void Function(CategoryReportBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CategoryReport build() => _build();

  _$CategoryReport _build() {
    _$CategoryReport _$result;
    try {
      _$result =
          _$v ??
          _$CategoryReport._(
            total: BuiltValueNullFieldError.checkNotNull(total, r'CategoryReport', 'total'),
            items: items.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'CategoryReport', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
