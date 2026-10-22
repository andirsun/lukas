//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'delete_transactions_batch.g.dart';

/// DeleteTransactionsBatch
///
/// Properties:
/// * [ids]
@BuiltValue()
abstract class DeleteTransactionsBatch
    implements Built<DeleteTransactionsBatch, DeleteTransactionsBatchBuilder> {
  @BuiltValueField(wireName: r'ids')
  BuiltList<String> get ids;

  DeleteTransactionsBatch._();

  factory DeleteTransactionsBatch([void updates(DeleteTransactionsBatchBuilder b)]) =
      _$DeleteTransactionsBatch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeleteTransactionsBatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeleteTransactionsBatch> get serializer =>
      _$DeleteTransactionsBatchSerializer();
}

class _$DeleteTransactionsBatchSerializer implements PrimitiveSerializer<DeleteTransactionsBatch> {
  @override
  final Iterable<Type> types = const [DeleteTransactionsBatch, _$DeleteTransactionsBatch];

  @override
  final String wireName = r'DeleteTransactionsBatch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeleteTransactionsBatch object, {
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
    DeleteTransactionsBatch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeleteTransactionsBatchBuilder result,
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
  DeleteTransactionsBatch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeleteTransactionsBatchBuilder();
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
