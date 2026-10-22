//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_get200_response_items_inner.g.dart';

/// V1TransactionsGet200ResponseItemsInner
///
/// Properties:
/// * [id]
/// * [name]
/// * [amount]
/// * [currency]
/// * [date]
/// * [status]
/// * [note]
/// * [categoryId]
/// * [recurrenceId]
/// * [importId]
/// * [source_]
/// * [createdAt]
/// * [updatedAt]
@BuiltValue()
abstract class V1TransactionsGet200ResponseItemsInner
    implements
        Built<
          V1TransactionsGet200ResponseItemsInner,
          V1TransactionsGet200ResponseItemsInnerBuilder
        > {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'date')
  String get date;

  @BuiltValueField(wireName: r'status')
  V1TransactionsGet200ResponseItemsInnerStatusEnum get status;
  // enum statusEnum {  paid,  pending,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'recurrenceId')
  String? get recurrenceId;

  @BuiltValueField(wireName: r'importId')
  String? get importId;

  @BuiltValueField(wireName: r'source')
  V1TransactionsGet200ResponseItemsInnerSource_Enum get source_;
  // enum source_Enum {  app,  web,  widget,  mcp,  import,  recurrence,  };

  @BuiltValueField(wireName: r'createdAt')
  String get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  String get updatedAt;

  V1TransactionsGet200ResponseItemsInner._();

  factory V1TransactionsGet200ResponseItemsInner([
    void updates(V1TransactionsGet200ResponseItemsInnerBuilder b),
  ]) = _$V1TransactionsGet200ResponseItemsInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsGet200ResponseItemsInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsGet200ResponseItemsInner> get serializer =>
      _$V1TransactionsGet200ResponseItemsInnerSerializer();
}

class _$V1TransactionsGet200ResponseItemsInnerSerializer
    implements PrimitiveSerializer<V1TransactionsGet200ResponseItemsInner> {
  @override
  final Iterable<Type> types = const [
    V1TransactionsGet200ResponseItemsInner,
    _$V1TransactionsGet200ResponseItemsInner,
  ];

  @override
  final String wireName = r'V1TransactionsGet200ResponseItemsInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsGet200ResponseItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(object.id, specifiedType: const FullType(String));
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'amount';
    yield serializers.serialize(object.amount, specifiedType: const FullType(int));
    yield r'currency';
    yield serializers.serialize(object.currency, specifiedType: const FullType(String));
    yield r'date';
    yield serializers.serialize(object.date, specifiedType: const FullType(String));
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(V1TransactionsGet200ResponseItemsInnerStatusEnum),
    );
    yield r'note';
    yield object.note == null
        ? null
        : serializers.serialize(object.note, specifiedType: const FullType.nullable(String));
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'recurrenceId';
    yield object.recurrenceId == null
        ? null
        : serializers.serialize(
            object.recurrenceId,
            specifiedType: const FullType.nullable(String),
          );
    yield r'importId';
    yield object.importId == null
        ? null
        : serializers.serialize(object.importId, specifiedType: const FullType.nullable(String));
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(V1TransactionsGet200ResponseItemsInnerSource_Enum),
    );
    yield r'createdAt';
    yield serializers.serialize(object.createdAt, specifiedType: const FullType(String));
    yield r'updatedAt';
    yield serializers.serialize(object.updatedAt, specifiedType: const FullType(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsGet200ResponseItemsInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsGet200ResponseItemsInnerBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.id = valueDes;
          break;
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
        case r'currency':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.currency = valueDes;
          break;
        case r'date':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.date = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1TransactionsGet200ResponseItemsInnerStatusEnum),
          ) as V1TransactionsGet200ResponseItemsInnerStatusEnum;
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
        case r'categoryId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.categoryId = valueDes;
          break;
        case r'recurrenceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.recurrenceId = valueDes;
          break;
        case r'importId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.importId = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1TransactionsGet200ResponseItemsInnerSource_Enum),
          ) as V1TransactionsGet200ResponseItemsInnerSource_Enum;
          result.source_ = valueDes;
          break;
        case r'createdAt':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1TransactionsGet200ResponseItemsInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsGet200ResponseItemsInnerBuilder();
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

class V1TransactionsGet200ResponseItemsInnerStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'paid')
  static const V1TransactionsGet200ResponseItemsInnerStatusEnum paid =
      _$v1TransactionsGet200ResponseItemsInnerStatusEnum_paid;
  @BuiltValueEnumConst(wireName: r'pending')
  static const V1TransactionsGet200ResponseItemsInnerStatusEnum pending =
      _$v1TransactionsGet200ResponseItemsInnerStatusEnum_pending;

  static Serializer<V1TransactionsGet200ResponseItemsInnerStatusEnum> get serializer =>
      _$v1TransactionsGet200ResponseItemsInnerStatusEnumSerializer;

  const V1TransactionsGet200ResponseItemsInnerStatusEnum._(String name) : super(name);

  static BuiltSet<V1TransactionsGet200ResponseItemsInnerStatusEnum> get values =>
      _$v1TransactionsGet200ResponseItemsInnerStatusEnumValues;
  static V1TransactionsGet200ResponseItemsInnerStatusEnum valueOf(String name) =>
      _$v1TransactionsGet200ResponseItemsInnerStatusEnumValueOf(name);
}

class V1TransactionsGet200ResponseItemsInnerSource_Enum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'app')
  static const V1TransactionsGet200ResponseItemsInnerSource_Enum app =
      _$v1TransactionsGet200ResponseItemsInnerSourceEnum_app;
  @BuiltValueEnumConst(wireName: r'web')
  static const V1TransactionsGet200ResponseItemsInnerSource_Enum web =
      _$v1TransactionsGet200ResponseItemsInnerSourceEnum_web;
  @BuiltValueEnumConst(wireName: r'widget')
  static const V1TransactionsGet200ResponseItemsInnerSource_Enum widget =
      _$v1TransactionsGet200ResponseItemsInnerSourceEnum_widget;
  @BuiltValueEnumConst(wireName: r'mcp')
  static const V1TransactionsGet200ResponseItemsInnerSource_Enum mcp =
      _$v1TransactionsGet200ResponseItemsInnerSourceEnum_mcp;
  @BuiltValueEnumConst(wireName: r'import')
  static const V1TransactionsGet200ResponseItemsInnerSource_Enum import_ =
      _$v1TransactionsGet200ResponseItemsInnerSourceEnum_import_;
  @BuiltValueEnumConst(wireName: r'recurrence')
  static const V1TransactionsGet200ResponseItemsInnerSource_Enum recurrence =
      _$v1TransactionsGet200ResponseItemsInnerSourceEnum_recurrence;

  static Serializer<V1TransactionsGet200ResponseItemsInnerSource_Enum> get serializer =>
      _$v1TransactionsGet200ResponseItemsInnerSourceEnumSerializer;

  const V1TransactionsGet200ResponseItemsInnerSource_Enum._(String name) : super(name);

  static BuiltSet<V1TransactionsGet200ResponseItemsInnerSource_Enum> get values =>
      _$v1TransactionsGet200ResponseItemsInnerSourceEnumValues;
  static V1TransactionsGet200ResponseItemsInnerSource_Enum valueOf(String name) =>
      _$v1TransactionsGet200ResponseItemsInnerSourceEnumValueOf(name);
}
