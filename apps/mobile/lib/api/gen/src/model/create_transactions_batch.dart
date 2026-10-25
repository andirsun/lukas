//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/create_transaction.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_transactions_batch.g.dart';

/// CreateTransactionsBatch
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class CreateTransactionsBatch
    implements Built<CreateTransactionsBatch, CreateTransactionsBatchBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<CreateTransaction> get items;

  CreateTransactionsBatch._();

  factory CreateTransactionsBatch([void updates(CreateTransactionsBatchBuilder b)]) =
      _$CreateTransactionsBatch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTransactionsBatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTransactionsBatch> get serializer =>
      _$CreateTransactionsBatchSerializer();
}

class _$CreateTransactionsBatchSerializer implements PrimitiveSerializer<CreateTransactionsBatch> {
  @override
  final Iterable<Type> types = const [CreateTransactionsBatch, _$CreateTransactionsBatch];

  @override
  final String wireName = r'CreateTransactionsBatch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTransactionsBatch object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(CreateTransaction)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionsBatch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTransactionsBatchBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CreateTransaction)]),
          ) as BuiltList<CreateTransaction>;
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
  CreateTransactionsBatch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTransactionsBatchBuilder();
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
