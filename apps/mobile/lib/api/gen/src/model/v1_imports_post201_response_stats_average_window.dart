//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_imports_post201_response_stats_average_window.g.dart';

/// V1ImportsPost201ResponseStatsAverageWindow
///
/// Properties:
/// * [from]
/// * [to]
/// * [months]
@BuiltValue()
abstract class V1ImportsPost201ResponseStatsAverageWindow
    implements
        Built<
          V1ImportsPost201ResponseStatsAverageWindow,
          V1ImportsPost201ResponseStatsAverageWindowBuilder
        > {
  @BuiltValueField(wireName: r'from')
  String get from;

  @BuiltValueField(wireName: r'to')
  String get to;

  @BuiltValueField(wireName: r'months')
  int get months;

  V1ImportsPost201ResponseStatsAverageWindow._();

  factory V1ImportsPost201ResponseStatsAverageWindow([
    void updates(V1ImportsPost201ResponseStatsAverageWindowBuilder b),
  ]) = _$V1ImportsPost201ResponseStatsAverageWindow;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ImportsPost201ResponseStatsAverageWindowBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ImportsPost201ResponseStatsAverageWindow> get serializer =>
      _$V1ImportsPost201ResponseStatsAverageWindowSerializer();
}

class _$V1ImportsPost201ResponseStatsAverageWindowSerializer
    implements PrimitiveSerializer<V1ImportsPost201ResponseStatsAverageWindow> {
  @override
  final Iterable<Type> types = const [
    V1ImportsPost201ResponseStatsAverageWindow,
    _$V1ImportsPost201ResponseStatsAverageWindow,
  ];

  @override
  final String wireName = r'V1ImportsPost201ResponseStatsAverageWindow';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ImportsPost201ResponseStatsAverageWindow object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'from';
    yield serializers.serialize(object.from, specifiedType: const FullType(String));
    yield r'to';
    yield serializers.serialize(object.to, specifiedType: const FullType(String));
    yield r'months';
    yield serializers.serialize(object.months, specifiedType: const FullType(int));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ImportsPost201ResponseStatsAverageWindow object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ImportsPost201ResponseStatsAverageWindowBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'from':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.from = valueDes;
          break;
        case r'to':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.to = valueDes;
          break;
        case r'months':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.months = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1ImportsPost201ResponseStatsAverageWindow deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ImportsPost201ResponseStatsAverageWindowBuilder();
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
