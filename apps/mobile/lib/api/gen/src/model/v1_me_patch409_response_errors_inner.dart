//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_me_patch409_response_errors_inner.g.dart';

/// V1MePatch409ResponseErrorsInner
///
/// Properties:
/// * [path]
/// * [message]
@BuiltValue()
abstract class V1MePatch409ResponseErrorsInner
    implements Built<V1MePatch409ResponseErrorsInner, V1MePatch409ResponseErrorsInnerBuilder> {
  @BuiltValueField(wireName: r'path')
  String get path;

  @BuiltValueField(wireName: r'message')
  String get message;

  V1MePatch409ResponseErrorsInner._();

  factory V1MePatch409ResponseErrorsInner([
    void updates(V1MePatch409ResponseErrorsInnerBuilder b),
  ]) = _$V1MePatch409ResponseErrorsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1MePatch409ResponseErrorsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1MePatch409ResponseErrorsInner> get serializer =>
      _$V1MePatch409ResponseErrorsInnerSerializer();
}

class _$V1MePatch409ResponseErrorsInnerSerializer
    implements PrimitiveSerializer<V1MePatch409ResponseErrorsInner> {
  @override
  final Iterable<Type> types = const [
    V1MePatch409ResponseErrorsInner,
    _$V1MePatch409ResponseErrorsInner,
  ];

  @override
  final String wireName = r'V1MePatch409ResponseErrorsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1MePatch409ResponseErrorsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'path';
    yield serializers.serialize(object.path, specifiedType: const FullType(String));
    yield r'message';
    yield serializers.serialize(object.message, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1MePatch409ResponseErrorsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1MePatch409ResponseErrorsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'path':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.path = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.message = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1MePatch409ResponseErrorsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1MePatch409ResponseErrorsInnerBuilder();
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
