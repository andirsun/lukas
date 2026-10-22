// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_reports_trend_get200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ReportsTrendGet200Response extends V1ReportsTrendGet200Response {
  @override
  final BuiltList<V1ReportsTrendGet200ResponseMonthsInner> months;

  factory _$V1ReportsTrendGet200Response([
    void Function(V1ReportsTrendGet200ResponseBuilder)? updates,
  ]) => (V1ReportsTrendGet200ResponseBuilder()..update(updates))._build();

  _$V1ReportsTrendGet200Response._({required this.months}) : super._();
  @override
  V1ReportsTrendGet200Response rebuild(
    void Function(V1ReportsTrendGet200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ReportsTrendGet200ResponseBuilder toBuilder() =>
      V1ReportsTrendGet200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ReportsTrendGet200Response && months == other.months;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, months.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'V1ReportsTrendGet200Response',
    )..add('months', months)).toString();
  }
}

class V1ReportsTrendGet200ResponseBuilder
    implements Builder<V1ReportsTrendGet200Response, V1ReportsTrendGet200ResponseBuilder> {
  _$V1ReportsTrendGet200Response? _$v;

  ListBuilder<V1ReportsTrendGet200ResponseMonthsInner>? _months;
  ListBuilder<V1ReportsTrendGet200ResponseMonthsInner> get months =>
      _$this._months ??= ListBuilder<V1ReportsTrendGet200ResponseMonthsInner>();
  set months(ListBuilder<V1ReportsTrendGet200ResponseMonthsInner>? months) =>
      _$this._months = months;

  V1ReportsTrendGet200ResponseBuilder() {
    V1ReportsTrendGet200Response._defaults(this);
  }

  V1ReportsTrendGet200ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _months = $v.months.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1ReportsTrendGet200Response other) {
    _$v = other as _$V1ReportsTrendGet200Response;
  }

  @override
  void update(void Function(V1ReportsTrendGet200ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ReportsTrendGet200Response build() => _build();

  _$V1ReportsTrendGet200Response _build() {
    _$V1ReportsTrendGet200Response _$result;
    try {
      _$result = _$v ?? _$V1ReportsTrendGet200Response._(months: months.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'months';
        months.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'V1ReportsTrendGet200Response',
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
