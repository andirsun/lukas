//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:lukitas/api/gen/src/model/v1_transactions_suggestions_get200_response_items_inner.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_suggestions_get200_response.g.dart';

/// V1TransactionsSuggestionsGet200Response
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class V1TransactionsSuggestionsGet200Response
    implements
        Built<
          V1TransactionsSuggestionsGet200Response,
          V1TransactionsSuggestionsGet200ResponseBuilder
        > {
  @BuiltValueField(wireName: r'items')
  BuiltList<V1TransactionsSuggestionsGet200ResponseItemsInner> get items;

  V1TransactionsSuggestionsGet200Response._();

  factory V1TransactionsSuggestionsGet200Response([
    void updates(V1TransactionsSuggestionsGet200ResponseBuilder b),
  ]) = _$V1TransactionsSuggestionsGet200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsSuggestionsGet200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsSuggestionsGet200Response> get serializer =>
      _$V1TransactionsSuggestionsGet200ResponseSerializer();
}

class _$V1TransactionsSuggestionsGet200ResponseSerializer
    implements PrimitiveSerializer<V1TransactionsSuggestionsGet200Response> {
  @override
  final Iterable<Type> types = const [
    V1TransactionsSuggestionsGet200Response,
    _$V1TransactionsSuggestionsGet200Response,
  ];

  @override
  final String wireName = r'V1TransactionsSuggestionsGet200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsSuggestionsGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [
        FullType(V1TransactionsSuggestionsGet200ResponseItemsInner),
      ]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsSuggestionsGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsSuggestionsGet200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(V1TransactionsSuggestionsGet200ResponseItemsInner),
            ]),
          ) as BuiltList<V1TransactionsSuggestionsGet200ResponseItemsInner>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1TransactionsSuggestionsGet200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsSuggestionsGet200ResponseBuilder();
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
