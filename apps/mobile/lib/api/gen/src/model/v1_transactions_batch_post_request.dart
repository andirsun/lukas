//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_post_request.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_batch_post_request.g.dart';

/// V1TransactionsBatchPostRequest
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class V1TransactionsBatchPostRequest
    implements Built<V1TransactionsBatchPostRequest, V1TransactionsBatchPostRequestBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<V1TransactionsPostRequest> get items;

  V1TransactionsBatchPostRequest._();

  factory V1TransactionsBatchPostRequest([void updates(V1TransactionsBatchPostRequestBuilder b)]) =
      _$V1TransactionsBatchPostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsBatchPostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsBatchPostRequest> get serializer =>
      _$V1TransactionsBatchPostRequestSerializer();
}

class _$V1TransactionsBatchPostRequestSerializer
    implements PrimitiveSerializer<V1TransactionsBatchPostRequest> {
  @override
  final Iterable<Type> types = const [
    V1TransactionsBatchPostRequest,
    _$V1TransactionsBatchPostRequest,
  ];

  @override
  final String wireName = r'V1TransactionsBatchPostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsBatchPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(V1TransactionsPostRequest)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsBatchPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsBatchPostRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(V1TransactionsPostRequest)]),
          ) as BuiltList<V1TransactionsPostRequest>;
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
  V1TransactionsBatchPostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsBatchPostRequestBuilder();
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
