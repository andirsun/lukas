//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'import_stats_average_monthly_spending_inner.g.dart';

/// ImportStatsAverageMonthlySpendingInner
///
/// Properties:
/// * [category]
/// * [amount]
@BuiltValue()
abstract class ImportStatsAverageMonthlySpendingInner
    implements
        Built<
          ImportStatsAverageMonthlySpendingInner,
          ImportStatsAverageMonthlySpendingInnerBuilder
        > {
  @BuiltValueField(wireName: r'category')
  String get category;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  ImportStatsAverageMonthlySpendingInner._();

  factory ImportStatsAverageMonthlySpendingInner([
    void updates(ImportStatsAverageMonthlySpendingInnerBuilder b),
  ]) = _$ImportStatsAverageMonthlySpendingInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ImportStatsAverageMonthlySpendingInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ImportStatsAverageMonthlySpendingInner> get serializer =>
      _$ImportStatsAverageMonthlySpendingInnerSerializer();
}

class _$ImportStatsAverageMonthlySpendingInnerSerializer
    implements PrimitiveSerializer<ImportStatsAverageMonthlySpendingInner> {
  @override
  final Iterable<Type> types = const [
    ImportStatsAverageMonthlySpendingInner,
    _$ImportStatsAverageMonthlySpendingInner,
  ];

  @override
  final String wireName = r'ImportStatsAverageMonthlySpendingInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ImportStatsAverageMonthlySpendingInner object, {
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
    ImportStatsAverageMonthlySpendingInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ImportStatsAverageMonthlySpendingInnerBuilder result,
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
  ImportStatsAverageMonthlySpendingInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ImportStatsAverageMonthlySpendingInnerBuilder();
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
