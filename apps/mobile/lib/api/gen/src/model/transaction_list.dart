//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:lukitas/api/gen/src/model/transaction.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transaction_list.g.dart';

/// TransactionList
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class TransactionList implements Built<TransactionList, TransactionListBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<Transaction> get items;

  TransactionList._();

  factory TransactionList([void updates(TransactionListBuilder b)]) = _$TransactionList;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransactionListBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TransactionList> get serializer => _$TransactionListSerializer();
}

class _$TransactionListSerializer implements PrimitiveSerializer<TransactionList> {
  @override
  final Iterable<Type> types = const [TransactionList, _$TransactionList];

  @override
  final String wireName = r'TransactionList';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TransactionList object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(Transaction)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TransactionList object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TransactionListBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Transaction)]),
          ) as BuiltList<Transaction>;
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
  TransactionList deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransactionListBuilder();
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
