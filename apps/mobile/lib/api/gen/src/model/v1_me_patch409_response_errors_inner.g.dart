// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_me_patch409_response_errors_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1MePatch409ResponseErrorsInner extends V1MePatch409ResponseErrorsInner {
  @override
  final String path;
  @override
  final String message;

  factory _$V1MePatch409ResponseErrorsInner([
    void Function(V1MePatch409ResponseErrorsInnerBuilder)? updates,
  ]) => (V1MePatch409ResponseErrorsInnerBuilder()..update(updates))._build();

  _$V1MePatch409ResponseErrorsInner._({required this.path, required this.message}) : super._();
  @override
  V1MePatch409ResponseErrorsInner rebuild(
    void Function(V1MePatch409ResponseErrorsInnerBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  V1MePatch409ResponseErrorsInnerBuilder toBuilder() =>
      V1MePatch409ResponseErrorsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1MePatch409ResponseErrorsInner &&
        path == other.path &&
        message == other.message;
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
    return (newBuiltValueToStringHelper(r'V1MePatch409ResponseErrorsInner')
          ..add('path', path)
          ..add('message', message))
        .toString();
  }
}

class V1MePatch409ResponseErrorsInnerBuilder
    implements Builder<V1MePatch409ResponseErrorsInner, V1MePatch409ResponseErrorsInnerBuilder> {
  _$V1MePatch409ResponseErrorsInner? _$v;

  String? _path;
  String? get path => _$this._path;
  set path(String? path) => _$this._path = path;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  V1MePatch409ResponseErrorsInnerBuilder() {
    V1MePatch409ResponseErrorsInner._defaults(this);
  }

  V1MePatch409ResponseErrorsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _path = $v.path;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1MePatch409ResponseErrorsInner other) {
    _$v = other as _$V1MePatch409ResponseErrorsInner;
  }

  @override
  void update(void Function(V1MePatch409ResponseErrorsInnerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1MePatch409ResponseErrorsInner build() => _build();

  _$V1MePatch409ResponseErrorsInner _build() {
    final _$result =
        _$v ??
        _$V1MePatch409ResponseErrorsInner._(
          path: BuiltValueNullFieldError.checkNotNull(
            path,
            r'V1MePatch409ResponseErrorsInner',
            'path',
          ),
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'V1MePatch409ResponseErrorsInner',
            'message',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
