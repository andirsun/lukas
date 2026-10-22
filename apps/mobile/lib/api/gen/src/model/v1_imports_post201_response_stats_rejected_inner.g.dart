// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_imports_post201_response_stats_rejected_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1ImportsPost201ResponseStatsRejectedInner
    extends V1ImportsPost201ResponseStatsRejectedInner {
  @override
  final int line;
  @override
  final String reason;

  factory _$V1ImportsPost201ResponseStatsRejectedInner([
    void Function(V1ImportsPost201ResponseStatsRejectedInnerBuilder)? updates,
  ]) => (V1ImportsPost201ResponseStatsRejectedInnerBuilder()..update(updates))._build();

  _$V1ImportsPost201ResponseStatsRejectedInner._({required this.line, required this.reason})
    : super._();
  @override
  V1ImportsPost201ResponseStatsRejectedInner rebuild(
    void Function(V1ImportsPost201ResponseStatsRejectedInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1ImportsPost201ResponseStatsRejectedInnerBuilder toBuilder() =>
      V1ImportsPost201ResponseStatsRejectedInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ImportsPost201ResponseStatsRejectedInner &&
        line == other.line &&
        reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, line.hashCode);
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1ImportsPost201ResponseStatsRejectedInner')
          ..add('line', line)
          ..add('reason', reason))
        .toString();
  }
}

class V1ImportsPost201ResponseStatsRejectedInnerBuilder
    implements
        Builder<
          V1ImportsPost201ResponseStatsRejectedInner,
          V1ImportsPost201ResponseStatsRejectedInnerBuilder
        > {
  _$V1ImportsPost201ResponseStatsRejectedInner? _$v;

  int? _line;
  int? get line => _$this._line;
  set line(int? line) => _$this._line = line;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  V1ImportsPost201ResponseStatsRejectedInnerBuilder() {
    V1ImportsPost201ResponseStatsRejectedInner._defaults(this);
  }

  V1ImportsPost201ResponseStatsRejectedInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _line = $v.line;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1ImportsPost201ResponseStatsRejectedInner other) {
    _$v = other as _$V1ImportsPost201ResponseStatsRejectedInner;
  }

  @override
  void update(void Function(V1ImportsPost201ResponseStatsRejectedInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ImportsPost201ResponseStatsRejectedInner build() => _build();

  _$V1ImportsPost201ResponseStatsRejectedInner _build() {
    final _$result =
        _$v ??
        _$V1ImportsPost201ResponseStatsRejectedInner._(
          line: BuiltValueNullFieldError.checkNotNull(
            line,
            r'V1ImportsPost201ResponseStatsRejectedInner',
            'line',
          ),
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'V1ImportsPost201ResponseStatsRejectedInner',
            'reason',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
