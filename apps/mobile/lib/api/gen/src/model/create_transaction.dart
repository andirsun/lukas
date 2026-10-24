//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_transaction.g.dart';

/// CreateTransaction
///
/// Properties:
/// * [name]
/// * [amount]
/// * [categoryId]
/// * [date]
/// * [status]
/// * [note]
/// * [source_]
@BuiltValue()
abstract class CreateTransaction implements Built<CreateTransaction, CreateTransactionBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'date')
  String get date;

  @BuiltValueField(wireName: r'status')
  CreateTransactionStatusEnum? get status;
  // enum statusEnum {  paid,  pending,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'source')
  CreateTransactionSource_Enum? get source_;
  // enum source_Enum {  app,  web,  widget,  mcp,  };

  CreateTransaction._();

  factory CreateTransaction([void updates(CreateTransactionBuilder b)]) = _$CreateTransaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTransactionBuilder b) => b
    ..status = CreateTransactionStatusEnum.valueOf('paid')
    ..source_ = CreateTransactionSource_Enum.valueOf('app');

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTransaction> get serializer => _$CreateTransactionSerializer();
}

class _$CreateTransactionSerializer implements PrimitiveSerializer<CreateTransaction> {
  @override
  final Iterable<Type> types = const [CreateTransaction, _$CreateTransaction];

  @override
  final String wireName = r'CreateTransaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'amount';
    yield serializers.serialize(object.amount, specifiedType: const FullType(int));
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'date';
    yield serializers.serialize(object.date, specifiedType: const FullType(String));
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(CreateTransactionStatusEnum),
      );
    }
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(object.note, specifiedType: const FullType.nullable(String));
    }
    if (object.source_ != null) {
      yield r'source';
      yield serializers.serialize(
        object.source_,
        specifiedType: const FullType(CreateTransactionSource_Enum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTransactionBuilder result,
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
        case r'amount':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.amount = valueDes;
          break;
        case r'categoryId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.categoryId = valueDes;
          break;
        case r'date':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.date = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(CreateTransactionStatusEnum),
          ) as CreateTransactionStatusEnum?;
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
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(CreateTransactionSource_Enum),
          ) as CreateTransactionSource_Enum?;
          if (valueDes == null) continue;
          result.source_ = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateTransaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTransactionBuilder();
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

class CreateTransactionStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'paid')
  static const CreateTransactionStatusEnum paid = _$createTransactionStatusEnum_paid;
  @BuiltValueEnumConst(wireName: r'pending')
  static const CreateTransactionStatusEnum pending = _$createTransactionStatusEnum_pending;

  static Serializer<CreateTransactionStatusEnum> get serializer =>
      _$createTransactionStatusEnumSerializer;

  const CreateTransactionStatusEnum._(String name) : super(name);

  static BuiltSet<CreateTransactionStatusEnum> get values => _$createTransactionStatusEnumValues;
  static CreateTransactionStatusEnum valueOf(String name) =>
      _$createTransactionStatusEnumValueOf(name);
}

class CreateTransactionSource_Enum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'app')
  static const CreateTransactionSource_Enum app = _$createTransactionSourceEnum_app;
  @BuiltValueEnumConst(wireName: r'web')
  static const CreateTransactionSource_Enum web = _$createTransactionSourceEnum_web;
  @BuiltValueEnumConst(wireName: r'widget')
  static const CreateTransactionSource_Enum widget = _$createTransactionSourceEnum_widget;
  @BuiltValueEnumConst(wireName: r'mcp')
  static const CreateTransactionSource_Enum mcp = _$createTransactionSourceEnum_mcp;

  static Serializer<CreateTransactionSource_Enum> get serializer =>
      _$createTransactionSourceEnumSerializer;

  const CreateTransactionSource_Enum._(String name) : super(name);

  static BuiltSet<CreateTransactionSource_Enum> get values => _$createTransactionSourceEnumValues;
  static CreateTransactionSource_Enum valueOf(String name) =>
      _$createTransactionSourceEnumValueOf(name);
}
