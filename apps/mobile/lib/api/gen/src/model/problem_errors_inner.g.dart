// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_errors_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProblemErrorsInner extends ProblemErrorsInner {
  @override
  final String path;
  @override
  final String message;

  factory _$ProblemErrorsInner([void Function(ProblemErrorsInnerBuilder)? updates]) =>
      (ProblemErrorsInnerBuilder()..update(updates))._build();

  _$ProblemErrorsInner._({required this.path, required this.message}) : super._();
  @override
  ProblemErrorsInner rebuild(void Function(ProblemErrorsInnerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProblemErrorsInnerBuilder toBuilder() => ProblemErrorsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProblemErrorsInner && path == other.path && message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, path.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProblemErrorsInner')
          ..add('path', path)
          ..add('message', message))
        .toString();
  }
}

class ProblemErrorsInnerBuilder implements Builder<ProblemErrorsInner, ProblemErrorsInnerBuilder> {
  _$ProblemErrorsInner? _$v;

  String? _path;
  String? get path => _$this._path;
  set path(String? path) => _$this._path = path;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  ProblemErrorsInnerBuilder() {
    ProblemErrorsInner._defaults(this);
  }

  ProblemErrorsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _path = $v.path;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProblemErrorsInner other) {
    _$v = other as _$ProblemErrorsInner;
  }

  @override
  void update(void Function(ProblemErrorsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProblemErrorsInner build() => _build();

  _$ProblemErrorsInner _build() {
    final _$result =
        _$v ??
        _$ProblemErrorsInner._(
          path: BuiltValueNullFieldError.checkNotNull(path, r'ProblemErrorsInner', 'path'),
          message: BuiltValueNullFieldError.checkNotNull(message, r'ProblemErrorsInner', 'message'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
