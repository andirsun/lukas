//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/summary_categories_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'summary.g.dart';

/// Summary
///
/// Properties:
/// * [month]
/// * [budgetTotal]
/// * [spent]
/// * [remaining]
/// * [income]
/// * [balance]
/// * [categories]
@BuiltValue()
abstract class Summary implements Built<Summary, SummaryBuilder> {
  @BuiltValueField(wireName: r'month')
  String get month;

  @BuiltValueField(wireName: r'budgetTotal')
  int get budgetTotal;

  @BuiltValueField(wireName: r'spent')
  int get spent;

  @BuiltValueField(wireName: r'remaining')
  int get remaining;

  @BuiltValueField(wireName: r'income')
  int get income;

  @BuiltValueField(wireName: r'balance')
  int get balance;

  @BuiltValueField(wireName: r'categories')
  BuiltList<SummaryCategoriesInner> get categories;

  Summary._();

  factory Summary([void updates(SummaryBuilder b)]) = _$Summary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Summary> get serializer => _$SummarySerializer();
}

class _$SummarySerializer implements PrimitiveSerializer<Summary> {
  @override
  final Iterable<Type> types = const [Summary, _$Summary];

  @override
  final String wireName = r'Summary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Summary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'month';
    yield serializers.serialize(object.month, specifiedType: const FullType(String));
    yield r'budgetTotal';
    yield serializers.serialize(object.budgetTotal, specifiedType: const FullType(int));
    yield r'spent';
    yield serializers.serialize(object.spent, specifiedType: const FullType(int));
    yield r'remaining';
    yield serializers.serialize(object.remaining, specifiedType: const FullType(int));
    yield r'income';
    yield serializers.serialize(object.income, specifiedType: const FullType(int));
    yield r'balance';
    yield serializers.serialize(object.balance, specifiedType: const FullType(int));
    yield r'categories';
    yield serializers.serialize(
      object.categories,
      specifiedType: const FullType(BuiltList, [FullType(SummaryCategoriesInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Summary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'month':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.month = valueDes;
          break;
        case r'budgetTotal':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.budgetTotal = valueDes;
          break;
        case r'spent':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.spent = valueDes;
          break;
        case r'remaining':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.remaining = valueDes;
          break;
        case r'income':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.income = valueDes;
          break;
        case r'balance':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.balance = valueDes;
          break;
        case r'categories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SummaryCategoriesInner)]),
          ) as BuiltList<SummaryCategoriesInner>;
          result.categories.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Summary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SummaryBuilder();
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
