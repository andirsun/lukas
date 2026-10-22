//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_recurrences_id_patch_request.g.dart';

/// V1RecurrencesIdPatchRequest
///
/// Properties:
/// * [name]
/// * [amount]
/// * [categoryId]
/// * [frequency]
/// * [dayOfMonth]
/// * [monthOfYear]
/// * [startDate]
/// * [endDate]
@BuiltValue()
abstract class V1RecurrencesIdPatchRequest
    implements Built<V1RecurrencesIdPatchRequest, V1RecurrencesIdPatchRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'amount')
  int? get amount;

  @BuiltValueField(wireName: r'categoryId')
  String? get categoryId;

  @BuiltValueField(wireName: r'frequency')
  V1RecurrencesIdPatchRequestFrequencyEnum? get frequency;
  // enum frequencyEnum {  monthly,  yearly,  };

  @BuiltValueField(wireName: r'dayOfMonth')
  int? get dayOfMonth;

  @BuiltValueField(wireName: r'monthOfYear')
  int? get monthOfYear;

  @BuiltValueField(wireName: r'startDate')
  String? get startDate;

  @BuiltValueField(wireName: r'endDate')
  String? get endDate;

  V1RecurrencesIdPatchRequest._();

  factory V1RecurrencesIdPatchRequest([void updates(V1RecurrencesIdPatchRequestBuilder b)]) =
      _$V1RecurrencesIdPatchRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1RecurrencesIdPatchRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1RecurrencesIdPatchRequest> get serializer =>
      _$V1RecurrencesIdPatchRequestSerializer();
}

class _$V1RecurrencesIdPatchRequestSerializer
    implements PrimitiveSerializer<V1RecurrencesIdPatchRequest> {
  @override
  final Iterable<Type> types = const [V1RecurrencesIdPatchRequest, _$V1RecurrencesIdPatchRequest];

  @override
  final String wireName = r'V1RecurrencesIdPatchRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1RecurrencesIdPatchRequest object, {
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
    if (object.frequency != null) {
      yield r'frequency';
      yield serializers.serialize(
        object.frequency,
        specifiedType: const FullType(V1RecurrencesIdPatchRequestFrequencyEnum),
      );
    }
    if (object.dayOfMonth != null) {
      yield r'dayOfMonth';
      yield serializers.serialize(object.dayOfMonth, specifiedType: const FullType(int));
    }
    if (object.monthOfYear != null) {
      yield r'monthOfYear';
      yield serializers.serialize(object.monthOfYear, specifiedType: const FullType.nullable(int));
    }
    if (object.startDate != null) {
      yield r'startDate';
      yield serializers.serialize(object.startDate, specifiedType: const FullType(String));
    }
    if (object.endDate != null) {
      yield r'endDate';
      yield serializers.serialize(object.endDate, specifiedType: const FullType.nullable(String));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    V1RecurrencesIdPatchRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1RecurrencesIdPatchRequestBuilder result,
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
        case r'frequency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(V1RecurrencesIdPatchRequestFrequencyEnum),
          ) as V1RecurrencesIdPatchRequestFrequencyEnum?;
          if (valueDes == null) continue;
          result.frequency = valueDes;
          break;
        case r'dayOfMonth':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.dayOfMonth = valueDes;
          break;
        case r'monthOfYear':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.monthOfYear = valueDes;
          break;
        case r'startDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.startDate = valueDes;
          break;
        case r'endDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.endDate = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  V1RecurrencesIdPatchRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1RecurrencesIdPatchRequestBuilder();
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

class V1RecurrencesIdPatchRequestFrequencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'monthly')
  static const V1RecurrencesIdPatchRequestFrequencyEnum monthly =
      _$v1RecurrencesIdPatchRequestFrequencyEnum_monthly;
  @BuiltValueEnumConst(wireName: r'yearly')
  static const V1RecurrencesIdPatchRequestFrequencyEnum yearly =
      _$v1RecurrencesIdPatchRequestFrequencyEnum_yearly;

  static Serializer<V1RecurrencesIdPatchRequestFrequencyEnum> get serializer =>
      _$v1RecurrencesIdPatchRequestFrequencyEnumSerializer;

  const V1RecurrencesIdPatchRequestFrequencyEnum._(String name) : super(name);

  static BuiltSet<V1RecurrencesIdPatchRequestFrequencyEnum> get values =>
      _$v1RecurrencesIdPatchRequestFrequencyEnumValues;
  static V1RecurrencesIdPatchRequestFrequencyEnum valueOf(String name) =>
      _$v1RecurrencesIdPatchRequestFrequencyEnumValueOf(name);
}
