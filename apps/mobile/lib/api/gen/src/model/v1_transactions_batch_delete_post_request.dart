//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_batch_delete_post_request.g.dart';

/// V1TransactionsBatchDeletePostRequest
///
/// Properties:
/// * [ids]
@BuiltValue()
abstract class V1TransactionsBatchDeletePostRequest
    implements
        Built<V1TransactionsBatchDeletePostRequest, V1TransactionsBatchDeletePostRequestBuilder> {
  @BuiltValueField(wireName: r'ids')
  BuiltList<String> get ids;

  V1TransactionsBatchDeletePostRequest._();

  factory V1TransactionsBatchDeletePostRequest([
    void updates(V1TransactionsBatchDeletePostRequestBuilder b),
  ]) = _$V1TransactionsBatchDeletePostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsBatchDeletePostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsBatchDeletePostRequest> get serializer =>
      _$V1TransactionsBatchDeletePostRequestSerializer();
}

class _$V1TransactionsBatchDeletePostRequestSerializer
    implements PrimitiveSerializer<V1TransactionsBatchDeletePostRequest> {
  @override
  final Iterable<Type> types = const [
    V1TransactionsBatchDeletePostRequest,
    _$V1TransactionsBatchDeletePostRequest,
  ];

  @override
  final String wireName = r'V1TransactionsBatchDeletePostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsBatchDeletePostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'ids';
    yield serializers.serialize(
      object.ids,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsBatchDeletePostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsBatchDeletePostRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.ids.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1TransactionsBatchDeletePostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsBatchDeletePostRequestBuilder();
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
