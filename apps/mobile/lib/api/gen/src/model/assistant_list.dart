//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/assistant.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'assistant_list.g.dart';

/// AssistantList
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class AssistantList implements Built<AssistantList, AssistantListBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Assistant> get items;

  AssistantList._();

  factory AssistantList([void updates(AssistantListBuilder b)]) = _$AssistantList;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AssistantListBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AssistantList> get serializer => _$AssistantListSerializer();
}

class _$AssistantListSerializer implements PrimitiveSerializer<AssistantList> {
  @override
  final Iterable<Type> types = const [AssistantList, _$AssistantList];

  @override
  final String wireName = r'AssistantList';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AssistantList object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Assistant)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AssistantList object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AssistantListBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Assistant)]),
          ) as BuiltList<Assistant>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AssistantList deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssistantListBuilder();
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
