// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_stats_average_window.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ImportStatsAverageWindow extends ImportStatsAverageWindow {
  @override
  final String from;
  @override
  final String to;
  @override
  final int months;

  factory _$ImportStatsAverageWindow([void Function(ImportStatsAverageWindowBuilder)? updates]) =>
      (ImportStatsAverageWindowBuilder()..update(updates))._build();

  _$ImportStatsAverageWindow._({required this.from, required this.to, required this.months})
    : super._();
  @override
  ImportStatsAverageWindow rebuild(void Function(ImportStatsAverageWindowBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ImportStatsAverageWindowBuilder toBuilder() => ImportStatsAverageWindowBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportStatsAverageWindow &&
        from == other.from &&
        to == other.to &&
        months == other.months;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, from.hashCode);
    _$hash = $jc(_$hash, to.hashCode);
    _$hash = $jc(_$hash, months.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImportStatsAverageWindow')
          ..add('from', from)
          ..add('to', to)
          ..add('months', months))
        .toString();
  }
}

class ImportStatsAverageWindowBuilder
    implements Builder<ImportStatsAverageWindow, ImportStatsAverageWindowBuilder> {
  _$ImportStatsAverageWindow? _$v;

  String? _from;
  String? get from => _$this._from;
  set from(String? from) => _$this._from = from;

  String? _to;
  String? get to => _$this._to;
  set to(String? to) => _$this._to = to;

  int? _months;
  int? get months => _$this._months;
  set months(int? months) => _$this._months = months;

  ImportStatsAverageWindowBuilder() {
    ImportStatsAverageWindow._defaults(this);
  }

  ImportStatsAverageWindowBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _from = $v.from;
      _to = $v.to;
      _months = $v.months;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportStatsAverageWindow other) {
    _$v = other as _$ImportStatsAverageWindow;
  }

  @override
  void update(void Function(ImportStatsAverageWindowBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportStatsAverageWindow build() => _build();

  _$ImportStatsAverageWindow _build() {
    final _$result =
        _$v ??
        _$ImportStatsAverageWindow._(
          from: BuiltValueNullFieldError.checkNotNull(from, r'ImportStatsAverageWindow', 'from'),
          to: BuiltValueNullFieldError.checkNotNull(to, r'ImportStatsAverageWindow', 'to'),
          months: BuiltValueNullFieldError.checkNotNull(
            months,
            r'ImportStatsAverageWindow',
            'months',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
