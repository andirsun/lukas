//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_imports_post201_response_stats_average_monthly_spending_inner.g.dart';

/// V1ImportsPost201ResponseStatsAverageMonthlySpendingInner
///
/// Properties:
/// * [category]
/// * [amount]
@BuiltValue()
abstract class V1ImportsPost201ResponseStatsAverageMonthlySpendingInner
    implements
        Built<
          V1ImportsPost201ResponseStatsAverageMonthlySpendingInner,
          V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder
        > {
  @BuiltValueField(wireName: r'category')
  String get category;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  V1ImportsPost201ResponseStatsAverageMonthlySpendingInner._();

  factory V1ImportsPost201ResponseStatsAverageMonthlySpendingInner([
    void updates(V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder b),
  ]) = _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1ImportsPost201ResponseStatsAverageMonthlySpendingInner> get serializer =>
      _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerSerializer();
}

class _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerSerializer
    implements PrimitiveSerializer<V1ImportsPost201ResponseStatsAverageMonthlySpendingInner> {
  @override
  final Iterable<Type> types = const [
    V1ImportsPost201ResponseStatsAverageMonthlySpendingInner,
    _$V1ImportsPost201ResponseStatsAverageMonthlySpendingInner,
  ];

  @override
  final String wireName = r'V1ImportsPost201ResponseStatsAverageMonthlySpendingInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1ImportsPost201ResponseStatsAverageMonthlySpendingInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'category';
    yield serializers.serialize(object.category, specifiedType: const FullType(String));
    yield r'amount';
    yield serializers.serialize(object.amount, specifiedType: const FullType(int));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1ImportsPost201ResponseStatsAverageMonthlySpendingInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'category':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.category = valueDes;
          break;
        case r'amount':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.amount = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1ImportsPost201ResponseStatsAverageMonthlySpendingInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1ImportsPost201ResponseStatsAverageMonthlySpendingInnerBuilder();
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
