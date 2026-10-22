// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'v1_imports_post201_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const V1ImportsPost201ResponseStatusEnum _$v1ImportsPost201ResponseStatusEnum_preview =
    const V1ImportsPost201ResponseStatusEnum._('preview');
const V1ImportsPost201ResponseStatusEnum _$v1ImportsPost201ResponseStatusEnum_confirmed =
    const V1ImportsPost201ResponseStatusEnum._('confirmed');
const V1ImportsPost201ResponseStatusEnum _$v1ImportsPost201ResponseStatusEnum_reverted =
    const V1ImportsPost201ResponseStatusEnum._('reverted');

V1ImportsPost201ResponseStatusEnum _$v1ImportsPost201ResponseStatusEnumValueOf(String name) {
  switch (name) {
    case 'preview':
      return _$v1ImportsPost201ResponseStatusEnum_preview;
    case 'confirmed':
      return _$v1ImportsPost201ResponseStatusEnum_confirmed;
    case 'reverted':
      return _$v1ImportsPost201ResponseStatusEnum_reverted;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<V1ImportsPost201ResponseStatusEnum> _$v1ImportsPost201ResponseStatusEnumValues =
    BuiltSet<V1ImportsPost201ResponseStatusEnum>(const <V1ImportsPost201ResponseStatusEnum>[
      _$v1ImportsPost201ResponseStatusEnum_preview,
      _$v1ImportsPost201ResponseStatusEnum_confirmed,
      _$v1ImportsPost201ResponseStatusEnum_reverted,
    ]);

Serializer<V1ImportsPost201ResponseStatusEnum> _$v1ImportsPost201ResponseStatusEnumSerializer =
    _$V1ImportsPost201ResponseStatusEnumSerializer();

class _$V1ImportsPost201ResponseStatusEnumSerializer
    implements PrimitiveSerializer<V1ImportsPost201ResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'preview': 'preview',
    'confirmed': 'confirmed',
    'reverted': 'reverted',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'preview': 'preview',
    'confirmed': 'confirmed',
    'reverted': 'reverted',
  };

  @override
  final Iterable<Type> types = const <Type>[V1ImportsPost201ResponseStatusEnum];
  @override
  final String wireName = 'V1ImportsPost201ResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    V1ImportsPost201ResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  V1ImportsPost201ResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => V1ImportsPost201ResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$V1ImportsPost201Response extends V1ImportsPost201Response {
  @override
  final String id;
  @override
  final V1ImportsPost201ResponseStatusEnum status;
  @override
  final V1ImportsPost201ResponseStats stats;

  factory _$V1ImportsPost201Response([void Function(V1ImportsPost201ResponseBuilder)? updates]) =>
      (V1ImportsPost201ResponseBuilder()..update(updates))._build();

  _$V1ImportsPost201Response._({required this.id, required this.status, required this.stats})
    : super._();
  @override
  V1ImportsPost201Response rebuild(void Function(V1ImportsPost201ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  V1ImportsPost201ResponseBuilder toBuilder() => V1ImportsPost201ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is V1ImportsPost201Response &&
        id == other.id &&
        status == other.status &&
        stats == other.stats;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, stats.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'V1ImportsPost201Response')
          ..add('id', id)
          ..add('status', status)
          ..add('stats', stats))
        .toString();
  }
}

class V1ImportsPost201ResponseBuilder
    implements Builder<V1ImportsPost201Response, V1ImportsPost201ResponseBuilder> {
  _$V1ImportsPost201Response? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  V1ImportsPost201ResponseStatusEnum? _status;
  V1ImportsPost201ResponseStatusEnum? get status => _$this._status;
  set status(V1ImportsPost201ResponseStatusEnum? status) => _$this._status = status;

  V1ImportsPost201ResponseStatsBuilder? _stats;
  V1ImportsPost201ResponseStatsBuilder get stats =>
      _$this._stats ??= V1ImportsPost201ResponseStatsBuilder();
  set stats(V1ImportsPost201ResponseStatsBuilder? stats) => _$this._stats = stats;

  V1ImportsPost201ResponseBuilder() {
    V1ImportsPost201Response._defaults(this);
  }

  V1ImportsPost201ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _status = $v.status;
      _stats = $v.stats.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(V1ImportsPost201Response other) {
    _$v = other as _$V1ImportsPost201Response;
  }

  @override
  void update(void Function(V1ImportsPost201ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  V1ImportsPost201Response build() => _build();

  _$V1ImportsPost201Response _build() {
    _$V1ImportsPost201Response _$result;
    try {
      _$result =
          _$v ??
          _$V1ImportsPost201Response._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'V1ImportsPost201Response', 'id'),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'V1ImportsPost201Response',
              'status',
            ),
            stats: stats.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'stats';
        stats.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'V1ImportsPost201Response', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
