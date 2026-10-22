// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_stats_rejected_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ImportStatsRejectedInner extends ImportStatsRejectedInner {
  @override
  final int line;
  @override
  final String reason;

  factory _$ImportStatsRejectedInner([void Function(ImportStatsRejectedInnerBuilder)? updates]) =>
      (ImportStatsRejectedInnerBuilder()..update(updates))._build();

  _$ImportStatsRejectedInner._({required this.line, required this.reason}) : super._();
  @override
  ImportStatsRejectedInner rebuild(void Function(ImportStatsRejectedInnerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ImportStatsRejectedInnerBuilder toBuilder() => ImportStatsRejectedInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportStatsRejectedInner && line == other.line && reason == other.reason;
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
    return (newBuiltValueToStringHelper(r'ImportStatsRejectedInner')
          ..add('line', line)
          ..add('reason', reason))
        .toString();
  }
}

class ImportStatsRejectedInnerBuilder
    implements Builder<ImportStatsRejectedInner, ImportStatsRejectedInnerBuilder> {
  _$ImportStatsRejectedInner? _$v;

  int? _line;
  int? get line => _$this._line;
  set line(int? line) => _$this._line = line;

  String? _reason;
  String? get reason => _$this._reason;
  set reason(String? reason) => _$this._reason = reason;

  ImportStatsRejectedInnerBuilder() {
    ImportStatsRejectedInner._defaults(this);
  }

  ImportStatsRejectedInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _line = $v.line;
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportStatsRejectedInner other) {
    _$v = other as _$ImportStatsRejectedInner;
  }

  @override
  void update(void Function(ImportStatsRejectedInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportStatsRejectedInner build() => _build();

  _$ImportStatsRejectedInner _build() {
    final _$result =
        _$v ??
        _$ImportStatsRejectedInner._(
          line: BuiltValueNullFieldError.checkNotNull(line, r'ImportStatsRejectedInner', 'line'),
          reason: BuiltValueNullFieldError.checkNotNull(
            reason,
            r'ImportStatsRejectedInner',
            'reason',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
