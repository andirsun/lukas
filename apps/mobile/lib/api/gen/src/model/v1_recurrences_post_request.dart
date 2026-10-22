//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_recurrences_post_request.g.dart';

/// V1RecurrencesPostRequest
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
abstract class V1RecurrencesPostRequest
    implements Built<V1RecurrencesPostRequest, V1RecurrencesPostRequestBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'frequency')
  V1RecurrencesPostRequestFrequencyEnum get frequency;
  // enum frequencyEnum {  monthly,  yearly,  };

  @BuiltValueField(wireName: r'dayOfMonth')
  int get dayOfMonth;

  @BuiltValueField(wireName: r'monthOfYear')
  int? get monthOfYear;

  @BuiltValueField(wireName: r'startDate')
  String get startDate;

  @BuiltValueField(wireName: r'endDate')
  String? get endDate;

  V1RecurrencesPostRequest._();

  factory V1RecurrencesPostRequest([void updates(V1RecurrencesPostRequestBuilder b)]) =
      _$V1RecurrencesPostRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1RecurrencesPostRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1RecurrencesPostRequest> get serializer =>
      _$V1RecurrencesPostRequestSerializer();
}

class _$V1RecurrencesPostRequestSerializer
    implements PrimitiveSerializer<V1RecurrencesPostRequest> {
  @override
  final Iterable<Type> types = const [V1RecurrencesPostRequest, _$V1RecurrencesPostRequest];

  @override
  final String wireName = r'V1RecurrencesPostRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1RecurrencesPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'amount';
    yield serializers.serialize(object.amount, specifiedType: const FullType(int));
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'frequency';
    yield serializers.serialize(
      object.frequency,
      specifiedType: const FullType(V1RecurrencesPostRequestFrequencyEnum),
    );
    yield r'dayOfMonth';
    yield serializers.serialize(object.dayOfMonth, specifiedType: const FullType(int));
    if (object.monthOfYear != null) {
      yield r'monthOfYear';
      yield serializers.serialize(object.monthOfYear, specifiedType: const FullType.nullable(int));
    }
    yield r'startDate';
    yield serializers.serialize(object.startDate, specifiedType: const FullType(String));
    if (object.endDate != null) {
      yield r'endDate';
      yield serializers.serialize(object.endDate, specifiedType: const FullType.nullable(String));
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    V1RecurrencesPostRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1RecurrencesPostRequestBuilder result,
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
        case r'frequency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1RecurrencesPostRequestFrequencyEnum),
          ) as V1RecurrencesPostRequestFrequencyEnum;
          result.frequency = valueDes;
          break;
        case r'dayOfMonth':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(int)) as int;
          result.dayOfMonth = valueDes;
          break;
        case r'monthOfYear':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType.nullable(int)) as int?;
          if (valueDes == null) continue;
          result.monthOfYear = valueDes;
          break;
        case r'startDate':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
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
  V1RecurrencesPostRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1RecurrencesPostRequestBuilder();
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

class V1RecurrencesPostRequestFrequencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'monthly')
  static const V1RecurrencesPostRequestFrequencyEnum monthly =
      _$v1RecurrencesPostRequestFrequencyEnum_monthly;
  @BuiltValueEnumConst(wireName: r'yearly')
  static const V1RecurrencesPostRequestFrequencyEnum yearly =
      _$v1RecurrencesPostRequestFrequencyEnum_yearly;

  static Serializer<V1RecurrencesPostRequestFrequencyEnum> get serializer =>
      _$v1RecurrencesPostRequestFrequencyEnumSerializer;

  const V1RecurrencesPostRequestFrequencyEnum._(String name) : super(name);

  static BuiltSet<V1RecurrencesPostRequestFrequencyEnum> get values =>
      _$v1RecurrencesPostRequestFrequencyEnumValues;
  static V1RecurrencesPostRequestFrequencyEnum valueOf(String name) =>
      _$v1RecurrencesPostRequestFrequencyEnumValueOf(name);
}
