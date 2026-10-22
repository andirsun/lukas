//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_transactions_batch_items_inner.g.dart';

/// CreateTransactionsBatchItemsInner
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
abstract class CreateTransactionsBatchItemsInner
    implements Built<CreateTransactionsBatchItemsInner, CreateTransactionsBatchItemsInnerBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'date')
  String get date;

  @BuiltValueField(wireName: r'status')
  CreateTransactionsBatchItemsInnerStatusEnum? get status;
  // enum statusEnum {  paid,  pending,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'source')
  CreateTransactionsBatchItemsInnerSource_Enum? get source_;
  // enum source_Enum {  app,  web,  widget,  mcp,  };

  CreateTransactionsBatchItemsInner._();

  factory CreateTransactionsBatchItemsInner([
    void updates(CreateTransactionsBatchItemsInnerBuilder b),
  ]) = _$CreateTransactionsBatchItemsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateTransactionsBatchItemsInnerBuilder b) => b
    ..status = CreateTransactionsBatchItemsInnerStatusEnum.valueOf('paid')
    ..source_ = CreateTransactionsBatchItemsInnerSource_Enum.valueOf('app');

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateTransactionsBatchItemsInner> get serializer =>
      _$CreateTransactionsBatchItemsInnerSerializer();
}

class _$CreateTransactionsBatchItemsInnerSerializer
    implements PrimitiveSerializer<CreateTransactionsBatchItemsInner> {
  @override
  final Iterable<Type> types = const [
    CreateTransactionsBatchItemsInner,
    _$CreateTransactionsBatchItemsInner,
  ];

  @override
  final String wireName = r'CreateTransactionsBatchItemsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateTransactionsBatchItemsInner object, {
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
        specifiedType: const FullType(CreateTransactionsBatchItemsInnerStatusEnum),
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
        specifiedType: const FullType(CreateTransactionsBatchItemsInnerSource_Enum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateTransactionsBatchItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateTransactionsBatchItemsInnerBuilder result,
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
            specifiedType: const FullType.nullable(CreateTransactionsBatchItemsInnerStatusEnum),
          ) as CreateTransactionsBatchItemsInnerStatusEnum?;
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
            specifiedType: const FullType.nullable(CreateTransactionsBatchItemsInnerSource_Enum),
          ) as CreateTransactionsBatchItemsInnerSource_Enum?;
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
  CreateTransactionsBatchItemsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateTransactionsBatchItemsInnerBuilder();
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

class CreateTransactionsBatchItemsInnerStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'paid')
  static const CreateTransactionsBatchItemsInnerStatusEnum paid =
      _$createTransactionsBatchItemsInnerStatusEnum_paid;
  @BuiltValueEnumConst(wireName: r'pending')
  static const CreateTransactionsBatchItemsInnerStatusEnum pending =
      _$createTransactionsBatchItemsInnerStatusEnum_pending;

  static Serializer<CreateTransactionsBatchItemsInnerStatusEnum> get serializer =>
      _$createTransactionsBatchItemsInnerStatusEnumSerializer;

  const CreateTransactionsBatchItemsInnerStatusEnum._(String name) : super(name);

  static BuiltSet<CreateTransactionsBatchItemsInnerStatusEnum> get values =>
      _$createTransactionsBatchItemsInnerStatusEnumValues;
  static CreateTransactionsBatchItemsInnerStatusEnum valueOf(String name) =>
      _$createTransactionsBatchItemsInnerStatusEnumValueOf(name);
}

class CreateTransactionsBatchItemsInnerSource_Enum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'app')
  static const CreateTransactionsBatchItemsInnerSource_Enum app =
      _$createTransactionsBatchItemsInnerSourceEnum_app;
  @BuiltValueEnumConst(wireName: r'web')
  static const CreateTransactionsBatchItemsInnerSource_Enum web =
      _$createTransactionsBatchItemsInnerSourceEnum_web;
  @BuiltValueEnumConst(wireName: r'widget')
  static const CreateTransactionsBatchItemsInnerSource_Enum widget =
      _$createTransactionsBatchItemsInnerSourceEnum_widget;
  @BuiltValueEnumConst(wireName: r'mcp')
  static const CreateTransactionsBatchItemsInnerSource_Enum mcp =
      _$createTransactionsBatchItemsInnerSourceEnum_mcp;

  static Serializer<CreateTransactionsBatchItemsInnerSource_Enum> get serializer =>
      _$createTransactionsBatchItemsInnerSourceEnumSerializer;

  const CreateTransactionsBatchItemsInnerSource_Enum._(String name) : super(name);

  static BuiltSet<CreateTransactionsBatchItemsInnerSource_Enum> get values =>
      _$createTransactionsBatchItemsInnerSourceEnumValues;
  static CreateTransactionsBatchItemsInnerSource_Enum valueOf(String name) =>
      _$createTransactionsBatchItemsInnerSourceEnumValueOf(name);
}
