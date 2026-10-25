// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_of_living_report.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CostOfLivingReport extends CostOfLivingReport {
  @override
  final int months;
  @override
  final int total;
  @override
  final int fixed;
  @override
  final int variable;
  @override
  final BuiltList<CostOfLivingReportCategoriesInner> categories;

  factory _$CostOfLivingReport([void Function(CostOfLivingReportBuilder)? updates]) =>
      (CostOfLivingReportBuilder()..update(updates))._build();

  _$CostOfLivingReport._({
    required this.months,
    required this.total,
    required this.fixed,
    required this.variable,
    required this.categories,
  }) : super._();
  @override
  CostOfLivingReport rebuild(void Function(CostOfLivingReportBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CostOfLivingReportBuilder toBuilder() => CostOfLivingReportBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CostOfLivingReport &&
        months == other.months &&
        total == other.total &&
        fixed == other.fixed &&
        variable == other.variable &&
        categories == other.categories;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, months.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, fixed.hashCode);
    _$hash = $jc(_$hash, variable.hashCode);
    _$hash = $jc(_$hash, categories.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CostOfLivingReport')
          ..add('months', months)
          ..add('total', total)
          ..add('fixed', fixed)
          ..add('variable', variable)
          ..add('categories', categories))
        .toString();
  }
}

class CostOfLivingReportBuilder implements Builder<CostOfLivingReport, CostOfLivingReportBuilder> {
  _$CostOfLivingReport? _$v;

  int? _months;
  int? get months => _$this._months;
  set months(int? months) => _$this._months = months;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  int? _fixed;
  int? get fixed => _$this._fixed;
  set fixed(int? fixed) => _$this._fixed = fixed;

  int? _variable;
  int? get variable => _$this._variable;
  set variable(int? variable) => _$this._variable = variable;

  ListBuilder<CostOfLivingReportCategoriesInner>? _categories;
  ListBuilder<CostOfLivingReportCategoriesInner> get categories =>
      _$this._categories ??= ListBuilder<CostOfLivingReportCategoriesInner>();
  set categories(ListBuilder<CostOfLivingReportCategoriesInner>? categories) =>
      _$this._categories = categories;

  CostOfLivingReportBuilder() {
    CostOfLivingReport._defaults(this);
  }

  CostOfLivingReportBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _months = $v.months;
      _total = $v.total;
      _fixed = $v.fixed;
      _variable = $v.variable;
      _categories = $v.categories.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CostOfLivingReport other) {
    _$v = other as _$CostOfLivingReport;
  }

  @override
  void update(void Function(CostOfLivingReportBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CostOfLivingReport build() => _build();

  _$CostOfLivingReport _build() {
    _$CostOfLivingReport _$result;
    try {
      _$result =
          _$v ??
          _$CostOfLivingReport._(
            months: BuiltValueNullFieldError.checkNotNull(months, r'CostOfLivingReport', 'months'),
            total: BuiltValueNullFieldError.checkNotNull(total, r'CostOfLivingReport', 'total'),
            fixed: BuiltValueNullFieldError.checkNotNull(fixed, r'CostOfLivingReport', 'fixed'),
            variable: BuiltValueNullFieldError.checkNotNull(
              variable,
              r'CostOfLivingReport',
              'variable',
            ),
            categories: categories.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'categories';
        categories.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'CostOfLivingReport', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
