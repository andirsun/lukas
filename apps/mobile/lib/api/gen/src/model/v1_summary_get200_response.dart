//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:lukitas/api/gen/src/model/v1_summary_get200_response_categories_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_summary_get200_response.g.dart';

/// V1SummaryGet200Response
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
abstract class V1SummaryGet200Response
    implements Built<V1SummaryGet200Response, V1SummaryGet200ResponseBuilder> {
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
  BuiltList<V1SummaryGet200ResponseCategoriesInner> get categories;

  V1SummaryGet200Response._();

  factory V1SummaryGet200Response([void updates(V1SummaryGet200ResponseBuilder b)]) =
      _$V1SummaryGet200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1SummaryGet200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1SummaryGet200Response> get serializer =>
      _$V1SummaryGet200ResponseSerializer();
}

class _$V1SummaryGet200ResponseSerializer implements PrimitiveSerializer<V1SummaryGet200Response> {
  @override
  final Iterable<Type> types = const [V1SummaryGet200Response, _$V1SummaryGet200Response];

  @override
  final String wireName = r'V1SummaryGet200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1SummaryGet200Response object, {
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
      specifiedType: const FullType(BuiltList, [FullType(V1SummaryGet200ResponseCategoriesInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1SummaryGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1SummaryGet200ResponseBuilder result,
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
            specifiedType: const FullType(BuiltList, [
              FullType(V1SummaryGet200ResponseCategoriesInner),
            ]),
          ) as BuiltList<V1SummaryGet200ResponseCategoriesInner>;
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
  V1SummaryGet200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1SummaryGet200ResponseBuilder();
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
