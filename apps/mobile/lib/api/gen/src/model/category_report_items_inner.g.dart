// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_report_items_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CategoryReportItemsInner extends CategoryReportItemsInner {
  @override
  final String categoryId;
  @override
  final String name;
  @override
  final String icon;
  @override
  final String color;
  @override
  final int total;
  @override
  final num share;

  factory _$CategoryReportItemsInner([void Function(CategoryReportItemsInnerBuilder)? updates]) =>
      (CategoryReportItemsInnerBuilder()..update(updates))._build();

  _$CategoryReportItemsInner._({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.share,
  }) : super._();
  @override
  CategoryReportItemsInner rebuild(void Function(CategoryReportItemsInnerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CategoryReportItemsInnerBuilder toBuilder() => CategoryReportItemsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CategoryReportItemsInner &&
        categoryId == other.categoryId &&
        name == other.name &&
        icon == other.icon &&
        color == other.color &&
        total == other.total &&
        share == other.share;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, icon.hashCode);
    _$hash = $jc(_$hash, color.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, share.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CategoryReportItemsInner')
          ..add('categoryId', categoryId)
          ..add('name', name)
          ..add('icon', icon)
          ..add('color', color)
          ..add('total', total)
          ..add('share', share))
        .toString();
  }
}

class CategoryReportItemsInnerBuilder
    implements Builder<CategoryReportItemsInner, CategoryReportItemsInnerBuilder> {
  _$CategoryReportItemsInner? _$v;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _icon;
  String? get icon => _$this._icon;
  set icon(String? icon) => _$this._icon = icon;

  String? _color;
  String? get color => _$this._color;
  set color(String? color) => _$this._color = color;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  num? _share;
  num? get share => _$this._share;
  set share(num? share) => _$this._share = share;

  CategoryReportItemsInnerBuilder() {
    CategoryReportItemsInner._defaults(this);
  }

  CategoryReportItemsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categoryId = $v.categoryId;
      _name = $v.name;
      _icon = $v.icon;
      _color = $v.color;
      _total = $v.total;
      _share = $v.share;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CategoryReportItemsInner other) {
    _$v = other as _$CategoryReportItemsInner;
  }

  @override
  void update(void Function(CategoryReportItemsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CategoryReportItemsInner build() => _build();

  _$CategoryReportItemsInner _build() {
    final _$result =
        _$v ??
        _$CategoryReportItemsInner._(
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'CategoryReportItemsInner',
            'categoryId',
          ),
          name: BuiltValueNullFieldError.checkNotNull(name, r'CategoryReportItemsInner', 'name'),
          icon: BuiltValueNullFieldError.checkNotNull(icon, r'CategoryReportItemsInner', 'icon'),
          color: BuiltValueNullFieldError.checkNotNull(color, r'CategoryReportItemsInner', 'color'),
          total: BuiltValueNullFieldError.checkNotNull(total, r'CategoryReportItemsInner', 'total'),
          share: BuiltValueNullFieldError.checkNotNull(share, r'CategoryReportItemsInner', 'share'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
