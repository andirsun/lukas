// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_reports_by_category_get200_response_items_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ReportsByCategoryGet200ResponseItemsInner
    extends V1ReportsByCategoryGet200ResponseItemsInner {
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

  factory _$V1ReportsByCategoryGet200ResponseItemsInner([
    void Function(V1ReportsByCategoryGet200ResponseItemsInnerBuilder)? updates,
  ]) => (V1ReportsByCategoryGet200ResponseItemsInnerBuilder()..update(updates))._build();

  _$V1ReportsByCategoryGet200ResponseItemsInner._({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.share,
  }) : super._();
  @override
  V1ReportsByCategoryGet200ResponseItemsInner rebuild(
    void Function(V1ReportsByCategoryGet200ResponseItemsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ReportsByCategoryGet200ResponseItemsInnerBuilder toBuilder() =>
      V1ReportsByCategoryGet200ResponseItemsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ReportsByCategoryGet200ResponseItemsInner &&
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
    return (newBuiltValueToStringHelper(r'V1ReportsByCategoryGet200ResponseItemsInner')
          ..add('categoryId', categoryId)
          ..add('name', name)
          ..add('icon', icon)
          ..add('color', color)
          ..add('total', total)
          ..add('share', share))
        .toString();
  }
}

class V1ReportsByCategoryGet200ResponseItemsInnerBuilder
    implements
        Builder<
          V1ReportsByCategoryGet200ResponseItemsInner,
          V1ReportsByCategoryGet200ResponseItemsInnerBuilder
        > {
  _$V1ReportsByCategoryGet200ResponseItemsInner? _$v;

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

  V1ReportsByCategoryGet200ResponseItemsInnerBuilder() {
    V1ReportsByCategoryGet200ResponseItemsInner._defaults(this);
  }

  V1ReportsByCategoryGet200ResponseItemsInnerBuilder get _$this {
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
  void replace(V1ReportsByCategoryGet200ResponseItemsInner other) {
    _$v = other as _$V1ReportsByCategoryGet200ResponseItemsInner;
  }

  @override
  void update(void Function(V1ReportsByCategoryGet200ResponseItemsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ReportsByCategoryGet200ResponseItemsInner build() => _build();

  _$V1ReportsByCategoryGet200ResponseItemsInner _build() {
    final _$result =
        _$v ??
        _$V1ReportsByCategoryGet200ResponseItemsInner._(
          categoryId: BuiltValueNullFieldError.checkNotNull(
            categoryId,
            r'V1ReportsByCategoryGet200ResponseItemsInner',
            'categoryId',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'V1ReportsByCategoryGet200ResponseItemsInner',
            'name',
          ),
          icon: BuiltValueNullFieldError.checkNotNull(
            icon,
            r'V1ReportsByCategoryGet200ResponseItemsInner',
            'icon',
          ),
          color: BuiltValueNullFieldError.checkNotNull(
            color,
            r'V1ReportsByCategoryGet200ResponseItemsInner',
            'color',
          ),
          total: BuiltValueNullFieldError.checkNotNull(
            total,
            r'V1ReportsByCategoryGet200ResponseItemsInner',
            'total',
          ),
          share: BuiltValueNullFieldError.checkNotNull(
            share,
            r'V1ReportsByCategoryGet200ResponseItemsInner',
            'share',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
