//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_categories_id_budget_put_request.g.dart';

/// V1CategoriesIdBudgetPutRequest
///
/// Properties:
/// * [amount]
/// * [effectiveFrom]
@BuiltValue()
abstract class V1CategoriesIdBudgetPutRequest
    implements Built<V1CategoriesIdBudgetPutRequest, V1CategoriesIdBudgetPutRequestBuilder> {
  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'effectiveFrom')
  String get effectiveFrom;

  V1CategoriesIdBudgetPutRequest._();

  factory V1CategoriesIdBudgetPutRequest([void updates(V1CategoriesIdBudgetPutRequestBuilder b)]) =
      _$V1CategoriesIdBudgetPutRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1CategoriesIdBudgetPutRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1CategoriesIdBudgetPutRequest> get serializer =>
      _$V1CategoriesIdBudgetPutRequestSerializer();
}

class _$V1CategoriesIdBudgetPutRequestSerializer
    implements PrimitiveSerializer<V1CategoriesIdBudgetPutRequest> {
  @override
  final Iterable<Type> types = const [
    V1CategoriesIdBudgetPutRequest,
    _$V1CategoriesIdBudgetPutRequest,
  ];

  @override
  final String wireName = r'V1CategoriesIdBudgetPutRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1CategoriesIdBudgetPutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amount';
    yield serializers.serialize(object.amount, specifiedType: const FullType(int));
    yield r'effectiveFrom';
    yield serializers.serialize(object.effectiveFrom, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1CategoriesIdBudgetPutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1CategoriesIdBudgetPutRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amount':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.amount = valueDes;
          break;
        case r'effectiveFrom':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.effectiveFrom = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1CategoriesIdBudgetPutRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1CategoriesIdBudgetPutRequestBuilder();
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
