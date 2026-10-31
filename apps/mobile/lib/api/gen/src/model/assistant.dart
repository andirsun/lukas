//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'assistant.g.dart';

/// Assistant
///
/// Properties:
/// * [clientId]
/// * [name]
/// * [icon]
/// * [uri]
/// * [domain]
/// * [scopes]
/// * [connectedAt]
/// * [lastUsedAt]
@BuiltValue()
abstract class Assistant implements Built<Assistant, AssistantBuilder> {
  @BuiltValueField(wireName: r'clientId')
  String get clientId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'icon')
  String? get icon;

  @BuiltValueField(wireName: r'uri')
  String? get uri;

  @BuiltValueField(wireName: r'domain')
  String? get domain;

  @BuiltValueField(wireName: r'scopes')
  BuiltList<String> get scopes;

  @BuiltValueField(wireName: r'connectedAt')
  String get connectedAt;

  @BuiltValueField(wireName: r'lastUsedAt')
  String? get lastUsedAt;

  Assistant._();

  factory Assistant([void updates(AssistantBuilder b)]) = _$Assistant;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AssistantBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Assistant> get serializer => _$AssistantSerializer();
}

class _$AssistantSerializer implements PrimitiveSerializer<Assistant> {
  @override
  final Iterable<Type> types = const [Assistant, _$Assistant];

  @override
  final String wireName = r'Assistant';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Assistant object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'clientId';
    yield serializers.serialize(object.clientId, specifiedType: const FullType(String));
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'icon';
    yield object.icon == null
        ? null
        : serializers.serialize(object.icon, specifiedType: const FullType.nullable(String));
    yield r'uri';
    yield object.uri == null
        ? null
        : serializers.serialize(object.uri, specifiedType: const FullType.nullable(String));
    yield r'domain';
    yield object.domain == null
        ? null
        : serializers.serialize(object.domain, specifiedType: const FullType.nullable(String));
    yield r'scopes';
    yield serializers.serialize(
      object.scopes,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'connectedAt';
    yield serializers.serialize(object.connectedAt, specifiedType: const FullType(String));
    yield r'lastUsedAt';
    yield object.lastUsedAt == null
        ? null
        : serializers.serialize(object.lastUsedAt, specifiedType: const FullType.nullable(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    Assistant object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AssistantBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'clientId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.clientId = valueDes;
          break;
        case r'name':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.name = valueDes;
          break;
        case r'icon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.icon = valueDes;
          break;
        case r'uri':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.uri = valueDes;
          break;
        case r'domain':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.domain = valueDes;
          break;
        case r'scopes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.scopes.replace(valueDes);
          break;
        case r'connectedAt':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.connectedAt = valueDes;
          break;
        case r'lastUsedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastUsedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Assistant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssistantBuilder();
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
