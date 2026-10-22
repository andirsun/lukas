// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_me_patch409_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$V1MePatch409Response extends V1MePatch409Response {
  @override
  final String type;
  @override
  final String title;
  @override
  final int status;
  @override
  final String code;
  @override
  final String? detail;
  @override
  final BuiltList<V1MePatch409ResponseErrorsInner>? errors;

  factory _$V1MePatch409Response([void Function(V1MePatch409ResponseBuilder)? updates]) =>
      (V1MePatch409ResponseBuilder()..update(updates))._build();

  _$V1MePatch409Response._({
    required this.type,
    required this.title,
    required this.status,
    required this.code,
    this.detail,
    this.errors,
  }) : super._();
  @override
  V1MePatch409Response rebuild(void Function(V1MePatch409ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1MePatch409ResponseBuilder toBuilder() => V1MePatch409ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1MePatch409Response &&
        type == other.type &&
        title == other.title &&
        status == other.status &&
        code == other.code &&
        detail == other.detail &&
        errors == other.errors;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, detail.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1MePatch409Response')
          ..add('type', type)
          ..add('title', title)
          ..add('status', status)
          ..add('code', code)
          ..add('detail', detail)
          ..add('errors', errors))
        .toString();
  }
}

class V1MePatch409ResponseBuilder
    implements Builder<V1MePatch409Response, V1MePatch409ResponseBuilder> {
  _$V1MePatch409Response? _$v;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  int? _status;
  int? get status => _$this._status;
  set status(int? status) => _$this._status = status;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _detail;
  String? get detail => _$this._detail;
  set detail(String? detail) => _$this._detail = detail;

  ListBuilder<V1MePatch409ResponseErrorsInner>? _errors;
  ListBuilder<V1MePatch409ResponseErrorsInner> get errors =>
      _$this._errors ??= ListBuilder<V1MePatch409ResponseErrorsInner>();
  set errors(ListBuilder<V1MePatch409ResponseErrorsInner>? errors) => _$this._errors = errors;

  V1MePatch409ResponseBuilder() {
    V1MePatch409Response._defaults(this);
  }

  V1MePatch409ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _title = $v.title;
      _status = $v.status;
      _code = $v.code;
      _detail = $v.detail;
      _errors = $v.errors?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1MePatch409Response other) {
    _$v = other as _$V1MePatch409Response;
  }

  @override
  void update(void Function(V1MePatch409ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1MePatch409Response build() => _build();

  _$V1MePatch409Response _build() {
    _$V1MePatch409Response _$result;
    try {
      _$result =
          _$v ??
          _$V1MePatch409Response._(
            type: BuiltValueNullFieldError.checkNotNull(type, r'V1MePatch409Response', 'type'),
            title: BuiltValueNullFieldError.checkNotNull(title, r'V1MePatch409Response', 'title'),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'V1MePatch409Response',
              'status',
            ),
            code: BuiltValueNullFieldError.checkNotNull(code, r'V1MePatch409Response', 'code'),
            detail: detail,
            errors: _errors?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'errors';
        _errors?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'V1MePatch409Response', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
