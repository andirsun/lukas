//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/v1_transactions_get200_response_items_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_get200_response.g.dart';

/// V1TransactionsGet200Response
///
/// Properties:
/// * [items]
/// * [nextCursor]
@BuiltValue()
abstract class V1TransactionsGet200Response
    implements Built<V1TransactionsGet200Response, V1TransactionsGet200ResponseBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<V1TransactionsGet200ResponseItemsInner> get items;

  @BuiltValueField(wireName: r'nextCursor')
  String? get nextCursor;

  V1TransactionsGet200Response._();

  factory V1TransactionsGet200Response([void updates(V1TransactionsGet200ResponseBuilder b)]) =
      _$V1TransactionsGet200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsGet200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsGet200Response> get serializer =>
      _$V1TransactionsGet200ResponseSerializer();
}

class _$V1TransactionsGet200ResponseSerializer
    implements PrimitiveSerializer<V1TransactionsGet200Response> {
  @override
  final Iterable<Type> types = const [V1TransactionsGet200Response, _$V1TransactionsGet200Response];

  @override
  final String wireName = r'V1TransactionsGet200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(V1TransactionsGet200ResponseItemsInner)]),
    );
    yield r'nextCursor';
    yield object.nextCursor == null
        ? null
        : serializers.serialize(object.nextCursor, specifiedType: const FullType.nullable(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsGet200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsGet200ResponseBuilder result,
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
        case r'nextCursor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextCursor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1TransactionsGet200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsGet200ResponseBuilder();
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
