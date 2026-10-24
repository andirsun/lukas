//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'import_stats_average_window.g.dart';

/// ImportStatsAverageWindow
///
/// Properties:
/// * [from]
/// * [to]
/// * [months]
@BuiltValue()
abstract class ImportStatsAverageWindow
    implements Built<ImportStatsAverageWindow, ImportStatsAverageWindowBuilder> {
  @BuiltValueField(wireName: r'from')
  String get from;

  @BuiltValueField(wireName: r'to')
  String get to;

  @BuiltValueField(wireName: r'months')
  int get months;

  ImportStatsAverageWindow._();

  factory ImportStatsAverageWindow([void updates(ImportStatsAverageWindowBuilder b)]) =
      _$ImportStatsAverageWindow;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ImportStatsAverageWindowBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ImportStatsAverageWindow> get serializer =>
      _$ImportStatsAverageWindowSerializer();
}

class _$ImportStatsAverageWindowSerializer
    implements PrimitiveSerializer<ImportStatsAverageWindow> {
  @override
  final Iterable<Type> types = const [ImportStatsAverageWindow, _$ImportStatsAverageWindow];

  @override
  final String wireName = r'ImportStatsAverageWindow';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ImportStatsAverageWindow object, {
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
    ImportStatsAverageWindow object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ImportStatsAverageWindowBuilder result,
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
  ImportStatsAverageWindow deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ImportStatsAverageWindowBuilder();
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
