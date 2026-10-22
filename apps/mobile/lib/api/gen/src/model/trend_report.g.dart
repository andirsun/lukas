// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_report.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrendReport extends TrendReport {
  @override
  final BuiltList<TrendReportMonthsInner> months;

  factory _$TrendReport([void Function(TrendReportBuilder)? updates]) =>
      (TrendReportBuilder()..update(updates))._build();

  _$TrendReport._({required this.months}) : super._();
  @override
  TrendReport rebuild(void Function(TrendReportBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrendReportBuilder toBuilder() => TrendReportBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrendReport && months == other.months;
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
    return (newBuiltValueToStringHelper(r'TrendReport')..add('months', months)).toString();
  }
}

class TrendReportBuilder implements Builder<TrendReport, TrendReportBuilder> {
  _$TrendReport? _$v;

  ListBuilder<TrendReportMonthsInner>? _months;
  ListBuilder<TrendReportMonthsInner> get months =>
      _$this._months ??= ListBuilder<TrendReportMonthsInner>();
  set months(ListBuilder<TrendReportMonthsInner>? months) => _$this._months = months;

  TrendReportBuilder() {
    TrendReport._defaults(this);
  }

  TrendReportBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _months = $v.months.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrendReport other) {
    _$v = other as _$TrendReport;
  }

  @override
  void update(void Function(TrendReportBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrendReport build() => _build();

  _$TrendReport _build() {
    _$TrendReport _$result;
    try {
      _$result = _$v ?? _$TrendReport._(months: months.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'months';
        months.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'TrendReport', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
