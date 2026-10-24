//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:lukitas/api/gen/src/model/import_stats.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'file_import.g.dart';

/// FileImport
///
/// Properties:
/// * [id]
/// * [status]
/// * [stats]
@BuiltValue()
abstract class FileImport implements Built<FileImport, FileImportBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  FileImportStatusEnum get status;
  // enum statusEnum {  preview,  confirmed,  reverted,  };

  @BuiltValueField(wireName: r'stats')
  ImportStats get stats;

  FileImport._();

  factory FileImport([void updates(FileImportBuilder b)]) = _$FileImport;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FileImportBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FileImport> get serializer => _$FileImportSerializer();
}

class _$FileImportSerializer implements PrimitiveSerializer<FileImport> {
  @override
  final Iterable<Type> types = const [FileImport, _$FileImport];

  @override
  final String wireName = r'FileImport';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FileImport object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(object.id, specifiedType: const FullType(String));
    yield r'status';
    yield serializers.serialize(object.status, specifiedType: const FullType(FileImportStatusEnum));
    yield r'stats';
    yield serializers.serialize(object.stats, specifiedType: const FullType(ImportStats));
  }

  @override
  Object serialize(
    Serializers serializers,
    FileImport object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FileImportBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.id = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(FileImportStatusEnum),
          ) as FileImportStatusEnum;
          result.status = valueDes;
          break;
        case r'stats':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ImportStats),
          ) as ImportStats;
          result.stats.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FileImport deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FileImportBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class FileImportStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'preview')
  static const FileImportStatusEnum preview = _$fileImportStatusEnum_preview;
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const FileImportStatusEnum confirmed = _$fileImportStatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'reverted')
  static const FileImportStatusEnum reverted = _$fileImportStatusEnum_reverted;

  static Serializer<FileImportStatusEnum> get serializer => _$fileImportStatusEnumSerializer;

  const FileImportStatusEnum._(String name) : super(name);

  static BuiltSet<FileImportStatusEnum> get values => _$fileImportStatusEnumValues;
  static FileImportStatusEnum valueOf(String name) => _$fileImportStatusEnumValueOf(name);
}
