//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_suggestions_get200_response_items_inner.g.dart';

/// V1TransactionsSuggestionsGet200ResponseItemsInner
///
/// Properties:
/// * [name]
/// * [categoryId]
@BuiltValue()
abstract class V1TransactionsSuggestionsGet200ResponseItemsInner
    implements
        Built<
          V1TransactionsSuggestionsGet200ResponseItemsInner,
          V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder
        > {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  V1TransactionsSuggestionsGet200ResponseItemsInner._();

  factory V1TransactionsSuggestionsGet200ResponseItemsInner([
    void updates(V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder b),
  ]) = _$V1TransactionsSuggestionsGet200ResponseItemsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsSuggestionsGet200ResponseItemsInner> get serializer =>
      _$V1TransactionsSuggestionsGet200ResponseItemsInnerSerializer();
}

class _$V1TransactionsSuggestionsGet200ResponseItemsInnerSerializer
    implements PrimitiveSerializer<V1TransactionsSuggestionsGet200ResponseItemsInner> {
  @override
  final Iterable<Type> types = const [
    V1TransactionsSuggestionsGet200ResponseItemsInner,
    _$V1TransactionsSuggestionsGet200ResponseItemsInner,
  ];

  @override
  final String wireName = r'V1TransactionsSuggestionsGet200ResponseItemsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsSuggestionsGet200ResponseItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsSuggestionsGet200ResponseItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.name = valueDes;
          break;
        case r'categoryId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.categoryId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1TransactionsSuggestionsGet200ResponseItemsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsSuggestionsGet200ResponseItemsInnerBuilder();
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
