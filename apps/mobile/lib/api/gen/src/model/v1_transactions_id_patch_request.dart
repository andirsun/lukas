//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_transactions_id_patch_request.g.dart';

/// V1TransactionsIdPatchRequest
///
/// Properties:
/// * [name]
/// * [amount]
/// * [categoryId]
/// * [date]
/// * [status]
/// * [note]
@BuiltValue()
abstract class V1TransactionsIdPatchRequest
    implements Built<V1TransactionsIdPatchRequest, V1TransactionsIdPatchRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'amount')
  int? get amount;

  @BuiltValueField(wireName: r'categoryId')
  String? get categoryId;

  @BuiltValueField(wireName: r'date')
  String? get date;

  @BuiltValueField(wireName: r'status')
  V1TransactionsIdPatchRequestStatusEnum? get status;
  // enum statusEnum {  paid,  pending,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  V1TransactionsIdPatchRequest._();

  factory V1TransactionsIdPatchRequest([void updates(V1TransactionsIdPatchRequestBuilder b)]) =
      _$V1TransactionsIdPatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1TransactionsIdPatchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1TransactionsIdPatchRequest> get serializer =>
      _$V1TransactionsIdPatchRequestSerializer();
}

class _$V1TransactionsIdPatchRequestSerializer
    implements PrimitiveSerializer<V1TransactionsIdPatchRequest> {
  @override
  final Iterable<Type> types = const [V1TransactionsIdPatchRequest, _$V1TransactionsIdPatchRequest];

  @override
  final String wireName = r'V1TransactionsIdPatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1TransactionsIdPatchRequest object, {
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
        specifiedType: const FullType(V1TransactionsIdPatchRequestStatusEnum),
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
    V1TransactionsIdPatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1TransactionsIdPatchRequestBuilder result,
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
            specifiedType: const FullType.nullable(V1TransactionsIdPatchRequestStatusEnum),
          ) as V1TransactionsIdPatchRequestStatusEnum?;
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
  V1TransactionsIdPatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1TransactionsIdPatchRequestBuilder();
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

class V1TransactionsIdPatchRequestStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'paid')
  static const V1TransactionsIdPatchRequestStatusEnum paid =
      _$v1TransactionsIdPatchRequestStatusEnum_paid;
  @BuiltValueEnumConst(wireName: r'pending')
  static const V1TransactionsIdPatchRequestStatusEnum pending =
      _$v1TransactionsIdPatchRequestStatusEnum_pending;

  static Serializer<V1TransactionsIdPatchRequestStatusEnum> get serializer =>
      _$v1TransactionsIdPatchRequestStatusEnumSerializer;

  const V1TransactionsIdPatchRequestStatusEnum._(String name) : super(name);

  static BuiltSet<V1TransactionsIdPatchRequestStatusEnum> get values =>
      _$v1TransactionsIdPatchRequestStatusEnumValues;
  static V1TransactionsIdPatchRequestStatusEnum valueOf(String name) =>
      _$v1TransactionsIdPatchRequestStatusEnumValueOf(name);
}
