// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_reports_cost_of_living_get200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ReportsCostOfLivingGet200Response extends V1ReportsCostOfLivingGet200Response {
  @override
  final int months;
  @override
  final int total;
  @override
  final int fixed;
  @override
  final int variable;
  @override
  final BuiltList<V1ReportsCostOfLivingGet200ResponseCategoriesInner> categories;

  factory _$V1ReportsCostOfLivingGet200Response([
    void Function(V1ReportsCostOfLivingGet200ResponseBuilder)? updates,
  ]) => (V1ReportsCostOfLivingGet200ResponseBuilder()..update(updates))._build();

  _$V1ReportsCostOfLivingGet200Response._({
    required this.months,
    required this.total,
    required this.fixed,
    required this.variable,
    required this.categories,
  }) : super._();
  @override
  V1ReportsCostOfLivingGet200Response rebuild(
    void Function(V1ReportsCostOfLivingGet200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ReportsCostOfLivingGet200ResponseBuilder toBuilder() =>
      V1ReportsCostOfLivingGet200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ReportsCostOfLivingGet200Response &&
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
    return (newBuiltValueToStringHelper(r'V1ReportsCostOfLivingGet200Response')
          ..add('months', months)
          ..add('total', total)
          ..add('fixed', fixed)
          ..add('variable', variable)
          ..add('categories', categories))
        .toString();
  }
}

class V1ReportsCostOfLivingGet200ResponseBuilder
    implements
        Builder<V1ReportsCostOfLivingGet200Response, V1ReportsCostOfLivingGet200ResponseBuilder> {
  _$V1ReportsCostOfLivingGet200Response? _$v;

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

  ListBuilder<V1ReportsCostOfLivingGet200ResponseCategoriesInner>? _categories;
  ListBuilder<V1ReportsCostOfLivingGet200ResponseCategoriesInner> get categories =>
      _$this._categories ??= ListBuilder<V1ReportsCostOfLivingGet200ResponseCategoriesInner>();
  set categories(ListBuilder<V1ReportsCostOfLivingGet200ResponseCategoriesInner>? categories) =>
      _$this._categories = categories;

  V1ReportsCostOfLivingGet200ResponseBuilder() {
    V1ReportsCostOfLivingGet200Response._defaults(this);
  }

  V1ReportsCostOfLivingGet200ResponseBuilder get _$this {
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
  void replace(V1ReportsCostOfLivingGet200Response other) {
    _$v = other as _$V1ReportsCostOfLivingGet200Response;
  }

  @override
  void update(void Function(V1ReportsCostOfLivingGet200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ReportsCostOfLivingGet200Response build() => _build();

  _$V1ReportsCostOfLivingGet200Response _build() {
    _$V1ReportsCostOfLivingGet200Response _$result;
    try {
      _$result =
          _$v ??
          _$V1ReportsCostOfLivingGet200Response._(
            months: BuiltValueNullFieldError.checkNotNull(
              months,
              r'V1ReportsCostOfLivingGet200Response',
              'months',
            ),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'V1ReportsCostOfLivingGet200Response',
              'total',
            ),
            fixed: BuiltValueNullFieldError.checkNotNull(
              fixed,
              r'V1ReportsCostOfLivingGet200Response',
              'fixed',
            ),
            variable: BuiltValueNullFieldError.checkNotNull(
              variable,
              r'V1ReportsCostOfLivingGet200Response',
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
        throw BuiltValueNestedFieldError(
          r'V1ReportsCostOfLivingGet200Response',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
