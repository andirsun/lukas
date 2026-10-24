//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_transaction.g.dart';

/// UpdateTransaction
///
/// Properties:
/// * [name]
/// * [amount]
/// * [categoryId]
/// * [date]
/// * [status]
/// * [note]
@BuiltValue()
abstract class UpdateTransaction implements Built<UpdateTransaction, UpdateTransactionBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'amount')
  int? get amount;

  @BuiltValueField(wireName: r'categoryId')
  String? get categoryId;

  @BuiltValueField(wireName: r'date')
  String? get date;

  @BuiltValueField(wireName: r'status')
  UpdateTransactionStatusEnum? get status;
  // enum statusEnum {  paid,  pending,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  UpdateTransaction._();

  factory UpdateTransaction([void updates(UpdateTransactionBuilder b)]) = _$UpdateTransaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateTransactionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateTransaction> get serializer => _$UpdateTransactionSerializer();
}

class _$UpdateTransactionSerializer implements PrimitiveSerializer<UpdateTransaction> {
  @override
  final Iterable<Type> types = const [UpdateTransaction, _$UpdateTransaction];

  @override
  final String wireName = r'UpdateTransaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(object.name, specifiedType: const FullType(String));
    }
    if (object.amount != null) {
      yield r'amount';
      yield serializers.serialize(object.amount, specifiedType: const FullType(int));
    }
    if (object.categoryId != null) {
      yield r'categoryId';
      yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    }
    if (object.date != null) {
      yield r'date';
      yield serializers.serialize(object.date, specifiedType: const FullType(String));
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(UpdateTransactionStatusEnum),
      );
    }
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(object.note, specifiedType: const FullType.nullable(String));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateTransactionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'amount':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.amount = valueDes;
          break;
        case r'categoryId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.categoryId = valueDes;
          break;
        case r'date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.date = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(UpdateTransactionStatusEnum),
          ) as UpdateTransactionStatusEnum?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateTransaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateTransactionBuilder();
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

class UpdateTransactionStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'paid')
  static const UpdateTransactionStatusEnum paid = _$updateTransactionStatusEnum_paid;
  @BuiltValueEnumConst(wireName: r'pending')
  static const UpdateTransactionStatusEnum pending = _$updateTransactionStatusEnum_pending;

  static Serializer<UpdateTransactionStatusEnum> get serializer =>
      _$updateTransactionStatusEnumSerializer;

  const UpdateTransactionStatusEnum._(String name) : super(name);

  static BuiltSet<UpdateTransactionStatusEnum> get values => _$updateTransactionStatusEnumValues;
  static UpdateTransactionStatusEnum valueOf(String name) =>
      _$updateTransactionStatusEnumValueOf(name);
}
