//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_post_request.g.dart';

/// V1TransactionsPostRequest
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
abstract class V1TransactionsPostRequest
    implements Built<V1TransactionsPostRequest, V1TransactionsPostRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'date')
  String get date;

  @BuiltValueField(wireName: r'status')
  V1TransactionsPostRequestStatusEnum? get status;
  // enum statusEnum {  paid,  pending,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'source')
  V1TransactionsPostRequestSource_Enum? get source_;
  // enum source_Enum {  app,  web,  widget,  mcp,  };

  V1TransactionsPostRequest._();

  factory V1TransactionsPostRequest([void updates(V1TransactionsPostRequestBuilder b)]) =
      _$V1TransactionsPostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsPostRequestBuilder b) => b
    ..status = V1TransactionsPostRequestStatusEnum.valueOf('paid')
    ..source_ = V1TransactionsPostRequestSource_Enum.valueOf('app');

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsPostRequest> get serializer =>
      _$V1TransactionsPostRequestSerializer();
}

class _$V1TransactionsPostRequestSerializer
    implements PrimitiveSerializer<V1TransactionsPostRequest> {
  @override
  final Iterable<Type> types = const [V1TransactionsPostRequest, _$V1TransactionsPostRequest];

  @override
  final String wireName = r'V1TransactionsPostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsPostRequest object, {
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
        specifiedType: const FullType(V1TransactionsPostRequestStatusEnum),
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
        specifiedType: const FullType(V1TransactionsPostRequestSource_Enum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    V1TransactionsPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsPostRequestBuilder result,
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
            specifiedType: const FullType.nullable(V1TransactionsPostRequestStatusEnum),
          ) as V1TransactionsPostRequestStatusEnum?;
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
            specifiedType: const FullType.nullable(V1TransactionsPostRequestSource_Enum),
          ) as V1TransactionsPostRequestSource_Enum?;
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
  V1TransactionsPostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsPostRequestBuilder();
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

class V1TransactionsPostRequestStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'paid')
  static const V1TransactionsPostRequestStatusEnum paid =
      _$v1TransactionsPostRequestStatusEnum_paid;
  @BuiltValueEnumConst(wireName: r'pending')
  static const V1TransactionsPostRequestStatusEnum pending =
      _$v1TransactionsPostRequestStatusEnum_pending;

  static Serializer<V1TransactionsPostRequestStatusEnum> get serializer =>
      _$v1TransactionsPostRequestStatusEnumSerializer;

  const V1TransactionsPostRequestStatusEnum._(String name) : super(name);

  static BuiltSet<V1TransactionsPostRequestStatusEnum> get values =>
      _$v1TransactionsPostRequestStatusEnumValues;
  static V1TransactionsPostRequestStatusEnum valueOf(String name) =>
      _$v1TransactionsPostRequestStatusEnumValueOf(name);
}

class V1TransactionsPostRequestSource_Enum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'app')
  static const V1TransactionsPostRequestSource_Enum app = _$v1TransactionsPostRequestSourceEnum_app;
  @BuiltValueEnumConst(wireName: r'web')
  static const V1TransactionsPostRequestSource_Enum web = _$v1TransactionsPostRequestSourceEnum_web;
  @BuiltValueEnumConst(wireName: r'widget')
  static const V1TransactionsPostRequestSource_Enum widget =
      _$v1TransactionsPostRequestSourceEnum_widget;
  @BuiltValueEnumConst(wireName: r'mcp')
  static const V1TransactionsPostRequestSource_Enum mcp = _$v1TransactionsPostRequestSourceEnum_mcp;

  static Serializer<V1TransactionsPostRequestSource_Enum> get serializer =>
      _$v1TransactionsPostRequestSourceEnumSerializer;

  const V1TransactionsPostRequestSource_Enum._(String name) : super(name);

  static BuiltSet<V1TransactionsPostRequestSource_Enum> get values =>
      _$v1TransactionsPostRequestSourceEnumValues;
  static V1TransactionsPostRequestSource_Enum valueOf(String name) =>
      _$v1TransactionsPostRequestSourceEnumValueOf(name);
}
