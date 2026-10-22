//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_get200_response_items_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_batch_post201_response.g.dart';

/// V1TransactionsBatchPost201Response
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class V1TransactionsBatchPost201Response
    implements
        Built<V1TransactionsBatchPost201Response, V1TransactionsBatchPost201ResponseBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<V1TransactionsGet200ResponseItemsInner> get items;

  V1TransactionsBatchPost201Response._();

  factory V1TransactionsBatchPost201Response([
    void updates(V1TransactionsBatchPost201ResponseBuilder b),
  ]) = _$V1TransactionsBatchPost201Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsBatchPost201ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsBatchPost201Response> get serializer =>
      _$V1TransactionsBatchPost201ResponseSerializer();
}

class _$V1TransactionsBatchPost201ResponseSerializer
    implements PrimitiveSerializer<V1TransactionsBatchPost201Response> {
  @override
  final Iterable<Type> types = const [
    V1TransactionsBatchPost201Response,
    _$V1TransactionsBatchPost201Response,
  ];

  @override
  final String wireName = r'V1TransactionsBatchPost201Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsBatchPost201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(V1TransactionsGet200ResponseItemsInner)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsBatchPost201Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsBatchPost201ResponseBuilder result,
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
              FullType(V1TransactionsGet200ResponseItemsInner),
            ]),
          ) as BuiltList<V1TransactionsGet200ResponseItemsInner>;
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
  V1TransactionsBatchPost201Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsBatchPost201ResponseBuilder();
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
