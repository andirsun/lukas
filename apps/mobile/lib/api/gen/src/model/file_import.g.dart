// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_import.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FileImportStatusEnum _$fileImportStatusEnum_preview = const FileImportStatusEnum._('preview');
const FileImportStatusEnum _$fileImportStatusEnum_confirmed = const FileImportStatusEnum._(
  'confirmed',
);
const FileImportStatusEnum _$fileImportStatusEnum_reverted = const FileImportStatusEnum._(
  'reverted',
);

FileImportStatusEnum _$fileImportStatusEnumValueOf(String name) {
  switch (name) {
    case 'preview':
      return _$fileImportStatusEnum_preview;
    case 'confirmed':
      return _$fileImportStatusEnum_confirmed;
    case 'reverted':
      return _$fileImportStatusEnum_reverted;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<FileImportStatusEnum> _$fileImportStatusEnumValues = BuiltSet<FileImportStatusEnum>(
  const <FileImportStatusEnum>[
    _$fileImportStatusEnum_preview,
    _$fileImportStatusEnum_confirmed,
    _$fileImportStatusEnum_reverted,
  ],
);

Serializer<FileImportStatusEnum> _$fileImportStatusEnumSerializer =
    _$FileImportStatusEnumSerializer();

class _$FileImportStatusEnumSerializer implements PrimitiveSerializer<FileImportStatusEnum> {
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
  final Iterable<Type> types = const <Type>[FileImportStatusEnum];
  @override
  final String wireName = 'FileImportStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    FileImportStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  FileImportStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => FileImportStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$FileImport extends FileImport {
  @override
  final String id;
  @override
  final FileImportStatusEnum status;
  @override
  final ImportStats stats;

  factory _$FileImport([void Function(FileImportBuilder)? updates]) =>
      (FileImportBuilder()..update(updates))._build();

  _$FileImport._({required this.id, required this.status, required this.stats}) : super._();
  @override
  FileImport rebuild(void Function(FileImportBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FileImportBuilder toBuilder() => FileImportBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FileImport && id == other.id && status == other.status && stats == other.stats;
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
    return (newBuiltValueToStringHelper(r'FileImport')
          ..add('id', id)
          ..add('status', status)
          ..add('stats', stats))
        .toString();
  }
}

class FileImportBuilder implements Builder<FileImport, FileImportBuilder> {
  _$FileImport? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  FileImportStatusEnum? _status;
  FileImportStatusEnum? get status => _$this._status;
  set status(FileImportStatusEnum? status) => _$this._status = status;

  ImportStatsBuilder? _stats;
  ImportStatsBuilder get stats => _$this._stats ??= ImportStatsBuilder();
  set stats(ImportStatsBuilder? stats) => _$this._stats = stats;

  FileImportBuilder() {
    FileImport._defaults(this);
  }

  FileImportBuilder get _$this {
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
  void replace(FileImport other) {
    _$v = other as _$FileImport;
  }

  @override
  void update(void Function(FileImportBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FileImport build() => _build();

  _$FileImport _build() {
    _$FileImport _$result;
    try {
      _$result =
          _$v ??
          _$FileImport._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'FileImport', 'id'),
            status: BuiltValueNullFieldError.checkNotNull(status, r'FileImport', 'status'),
            stats: stats.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'stats';
        stats.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'FileImport', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
