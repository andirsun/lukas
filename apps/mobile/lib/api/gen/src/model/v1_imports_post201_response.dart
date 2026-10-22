//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_imports_post201_response_stats.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_imports_post201_response.g.dart';

/// V1ImportsPost201Response
///
/// Properties:
/// * [id]
/// * [status]
/// * [stats]
@BuiltValue()
abstract class V1ImportsPost201Response
    implements Built<V1ImportsPost201Response, V1ImportsPost201ResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  V1ImportsPost201ResponseStatusEnum get status;
  // enum statusEnum {  preview,  confirmed,  reverted,  };

  @BuiltValueField(wireName: r'stats')
  V1ImportsPost201ResponseStats get stats;

  V1ImportsPost201Response._();

  factory V1ImportsPost201Response([void updates(V1ImportsPost201ResponseBuilder b)]) =
      _$V1ImportsPost201Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ImportsPost201ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ImportsPost201Response> get serializer =>
      _$V1ImportsPost201ResponseSerializer();
}

class _$V1ImportsPost201ResponseSerializer
    implements PrimitiveSerializer<V1ImportsPost201Response> {
  @override
  final Iterable<Type> types = const [V1ImportsPost201Response, _$V1ImportsPost201Response];

  @override
  final String wireName = r'V1ImportsPost201Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ImportsPost201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(object.id, specifiedType: const FullType(String));
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(V1ImportsPost201ResponseStatusEnum),
    );
    yield r'stats';
    yield serializers.serialize(
      object.stats,
      specifiedType: const FullType(V1ImportsPost201ResponseStats),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ImportsPost201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ImportsPost201ResponseBuilder result,
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
            specifiedType: const FullType(V1ImportsPost201ResponseStatusEnum),
          ) as V1ImportsPost201ResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'stats':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1ImportsPost201ResponseStats),
          ) as V1ImportsPost201ResponseStats;
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
  V1ImportsPost201Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ImportsPost201ResponseBuilder();
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

class V1ImportsPost201ResponseStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'preview')
  static const V1ImportsPost201ResponseStatusEnum preview =
      _$v1ImportsPost201ResponseStatusEnum_preview;
  @BuiltValueEnumConst(wireName: r'confirmed')
  static const V1ImportsPost201ResponseStatusEnum confirmed =
      _$v1ImportsPost201ResponseStatusEnum_confirmed;
  @BuiltValueEnumConst(wireName: r'reverted')
  static const V1ImportsPost201ResponseStatusEnum reverted =
      _$v1ImportsPost201ResponseStatusEnum_reverted;

  static Serializer<V1ImportsPost201ResponseStatusEnum> get serializer =>
      _$v1ImportsPost201ResponseStatusEnumSerializer;

  const V1ImportsPost201ResponseStatusEnum._(String name) : super(name);

  static BuiltSet<V1ImportsPost201ResponseStatusEnum> get values =>
      _$v1ImportsPost201ResponseStatusEnumValues;
  static V1ImportsPost201ResponseStatusEnum valueOf(String name) =>
      _$v1ImportsPost201ResponseStatusEnumValueOf(name);
}
