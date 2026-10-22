//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_imports_post201_response_stats_rejected_inner.g.dart';

/// V1ImportsPost201ResponseStatsRejectedInner
///
/// Properties:
/// * [line]
/// * [reason]
@BuiltValue()
abstract class V1ImportsPost201ResponseStatsRejectedInner
    implements
        Built<
          V1ImportsPost201ResponseStatsRejectedInner,
          V1ImportsPost201ResponseStatsRejectedInnerBuilder
        > {
  @BuiltValueField(wireName: r'line')
  int get line;

  @BuiltValueField(wireName: r'reason')
  String get reason;

  V1ImportsPost201ResponseStatsRejectedInner._();

  factory V1ImportsPost201ResponseStatsRejectedInner([
    void updates(V1ImportsPost201ResponseStatsRejectedInnerBuilder b),
  ]) = _$V1ImportsPost201ResponseStatsRejectedInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ImportsPost201ResponseStatsRejectedInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ImportsPost201ResponseStatsRejectedInner> get serializer =>
      _$V1ImportsPost201ResponseStatsRejectedInnerSerializer();
}

class _$V1ImportsPost201ResponseStatsRejectedInnerSerializer
    implements PrimitiveSerializer<V1ImportsPost201ResponseStatsRejectedInner> {
  @override
  final Iterable<Type> types = const [
    V1ImportsPost201ResponseStatsRejectedInner,
    _$V1ImportsPost201ResponseStatsRejectedInner,
  ];

  @override
  final String wireName = r'V1ImportsPost201ResponseStatsRejectedInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ImportsPost201ResponseStatsRejectedInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'line';
    yield serializers.serialize(object.line, specifiedType: const FullType(int));
    yield r'reason';
    yield serializers.serialize(object.reason, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ImportsPost201ResponseStatsRejectedInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ImportsPost201ResponseStatsRejectedInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'line':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.line = valueDes;
          break;
        case r'reason':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1ImportsPost201ResponseStatsRejectedInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ImportsPost201ResponseStatsRejectedInnerBuilder();
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
