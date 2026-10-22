// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_imports_post201_response_stats_average_window.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ImportsPost201ResponseStatsAverageWindow
    extends V1ImportsPost201ResponseStatsAverageWindow {
  @override
  final String from;
  @override
  final String to;
  @override
  final int months;

  factory _$V1ImportsPost201ResponseStatsAverageWindow([
    void Function(V1ImportsPost201ResponseStatsAverageWindowBuilder)? updates,
  ]) => (V1ImportsPost201ResponseStatsAverageWindowBuilder()..update(updates))._build();

  _$V1ImportsPost201ResponseStatsAverageWindow._({
    required this.from,
    required this.to,
    required this.months,
  }) : super._();
  @override
  V1ImportsPost201ResponseStatsAverageWindow rebuild(
    void Function(V1ImportsPost201ResponseStatsAverageWindowBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ImportsPost201ResponseStatsAverageWindowBuilder toBuilder() =>
      V1ImportsPost201ResponseStatsAverageWindowBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ImportsPost201ResponseStatsAverageWindow &&
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
    return (newBuiltValueToStringHelper(r'V1ImportsPost201ResponseStatsAverageWindow')
          ..add('from', from)
          ..add('to', to)
          ..add('months', months))
        .toString();
  }
}

class V1ImportsPost201ResponseStatsAverageWindowBuilder
    implements
        Builder<
          V1ImportsPost201ResponseStatsAverageWindow,
          V1ImportsPost201ResponseStatsAverageWindowBuilder
        > {
  _$V1ImportsPost201ResponseStatsAverageWindow? _$v;

  String? _from;
  String? get from => _$this._from;
  set from(String? from) => _$this._from = from;

  String? _to;
  String? get to => _$this._to;
  set to(String? to) => _$this._to = to;

  int? _months;
  int? get months => _$this._months;
  set months(int? months) => _$this._months = months;

  V1ImportsPost201ResponseStatsAverageWindowBuilder() {
    V1ImportsPost201ResponseStatsAverageWindow._defaults(this);
  }

  V1ImportsPost201ResponseStatsAverageWindowBuilder get _$this {
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
  void replace(V1ImportsPost201ResponseStatsAverageWindow other) {
    _$v = other as _$V1ImportsPost201ResponseStatsAverageWindow;
  }

  @override
  void update(void Function(V1ImportsPost201ResponseStatsAverageWindowBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ImportsPost201ResponseStatsAverageWindow build() => _build();

  _$V1ImportsPost201ResponseStatsAverageWindow _build() {
    final _$result =
        _$v ??
        _$V1ImportsPost201ResponseStatsAverageWindow._(
          from: BuiltValueNullFieldError.checkNotNull(
            from,
            r'V1ImportsPost201ResponseStatsAverageWindow',
            'from',
          ),
          to: BuiltValueNullFieldError.checkNotNull(
            to,
            r'V1ImportsPost201ResponseStatsAverageWindow',
            'to',
          ),
          months: BuiltValueNullFieldError.checkNotNull(
            months,
            r'V1ImportsPost201ResponseStatsAverageWindow',
            'months',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
