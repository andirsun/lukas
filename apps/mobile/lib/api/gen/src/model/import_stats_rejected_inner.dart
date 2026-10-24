//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'import_stats_rejected_inner.g.dart';

/// ImportStatsRejectedInner
///
/// Properties:
/// * [line]
/// * [reason]
@BuiltValue()
abstract class ImportStatsRejectedInner
    implements Built<ImportStatsRejectedInner, ImportStatsRejectedInnerBuilder> {
  @BuiltValueField(wireName: r'line')
  int get line;

  @BuiltValueField(wireName: r'reason')
  String get reason;

  ImportStatsRejectedInner._();

  factory ImportStatsRejectedInner([void updates(ImportStatsRejectedInnerBuilder b)]) =
      _$ImportStatsRejectedInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ImportStatsRejectedInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ImportStatsRejectedInner> get serializer =>
      _$ImportStatsRejectedInnerSerializer();
}

class _$ImportStatsRejectedInnerSerializer
    implements PrimitiveSerializer<ImportStatsRejectedInner> {
  @override
  final Iterable<Type> types = const [ImportStatsRejectedInner, _$ImportStatsRejectedInner];

  @override
  final String wireName = r'ImportStatsRejectedInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ImportStatsRejectedInner object, {
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
    ImportStatsRejectedInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ImportStatsRejectedInnerBuilder result,
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
  ImportStatsRejectedInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ImportStatsRejectedInnerBuilder();
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
