//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'v1_recurrences_get200_response_inner.g.dart';

/// V1RecurrencesGet200ResponseInner
///
/// Properties:
/// * [id]
/// * [name]
/// * [amount]
/// * [categoryId]
/// * [frequency]
/// * [dayOfMonth]
/// * [monthOfYear]
/// * [startDate]
/// * [endDate]
@BuiltValue()
abstract class V1RecurrencesGet200ResponseInner
    implements Built<V1RecurrencesGet200ResponseInner, V1RecurrencesGet200ResponseInnerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'frequency')
  V1RecurrencesGet200ResponseInnerFrequencyEnum get frequency;
  // enum frequencyEnum {  monthly,  yearly,  };

  @BuiltValueField(wireName: r'dayOfMonth')
  int get dayOfMonth;

  @BuiltValueField(wireName: r'monthOfYear')
  int? get monthOfYear;

  @BuiltValueField(wireName: r'startDate')
  String get startDate;

  @BuiltValueField(wireName: r'endDate')
  String? get endDate;

  V1RecurrencesGet200ResponseInner._();

  factory V1RecurrencesGet200ResponseInner([
    void updates(V1RecurrencesGet200ResponseInnerBuilder b),
  ]) = _$V1RecurrencesGet200ResponseInner;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(V1RecurrencesGet200ResponseInnerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<V1RecurrencesGet200ResponseInner> get serializer =>
      _$V1RecurrencesGet200ResponseInnerSerializer();
}

class _$V1RecurrencesGet200ResponseInnerSerializer
    implements PrimitiveSerializer<V1RecurrencesGet200ResponseInner> {
  @override
  final Iterable<Type> types = const [
    V1RecurrencesGet200ResponseInner,
    _$V1RecurrencesGet200ResponseInner,
  ];

  @override
  final String wireName = r'V1RecurrencesGet200ResponseInner';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    V1RecurrencesGet200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(object.id, specifiedType: const FullType(String));
    yield r'name';
    yield serializers.serialize(object.name, specifiedType: const FullType(String));
    yield r'amount';
    yield serializers.serialize(object.amount, specifiedType: const FullType(int));
    yield r'categoryId';
    yield serializers.serialize(object.categoryId, specifiedType: const FullType(String));
    yield r'frequency';
    yield serializers.serialize(
      object.frequency,
      specifiedType: const FullType(V1RecurrencesGet200ResponseInnerFrequencyEnum),
    );
    yield r'dayOfMonth';
    yield serializers.serialize(object.dayOfMonth, specifiedType: const FullType(int));
    yield r'monthOfYear';
    yield object.monthOfYear == null
        ? null
        : serializers.serialize(object.monthOfYear, specifiedType: const FullType.nullable(int));
    yield r'startDate';
    yield serializers.serialize(object.startDate, specifiedType: const FullType(String));
    yield r'endDate';
    yield object.endDate == null
        ? null
        : serializers.serialize(object.endDate, specifiedType: const FullType.nullable(String));
  }

  @override
  Object serialize(
    Serializers serializers,
    V1RecurrencesGet200ResponseInner object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required V1RecurrencesGet200ResponseInnerBuilder result,
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
        case r'categoryId':
          final valueDes =
              serializers.deserialize(value, specifiedType: const FullType(String)) as String;
          result.categoryId = valueDes;
          break;
        case r'frequency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(V1RecurrencesGet200ResponseInnerFrequencyEnum),
          ) as V1RecurrencesGet200ResponseInnerFrequencyEnum;
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
  V1RecurrencesGet200ResponseInner deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = V1RecurrencesGet200ResponseInnerBuilder();
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

class V1RecurrencesGet200ResponseInnerFrequencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'monthly')
  static const V1RecurrencesGet200ResponseInnerFrequencyEnum monthly =
      _$v1RecurrencesGet200ResponseInnerFrequencyEnum_monthly;
  @BuiltValueEnumConst(wireName: r'yearly')
  static const V1RecurrencesGet200ResponseInnerFrequencyEnum yearly =
      _$v1RecurrencesGet200ResponseInnerFrequencyEnum_yearly;

  static Serializer<V1RecurrencesGet200ResponseInnerFrequencyEnum> get serializer =>
      _$v1RecurrencesGet200ResponseInnerFrequencyEnumSerializer;

  const V1RecurrencesGet200ResponseInnerFrequencyEnum._(String name) : super(name);

  static BuiltSet<V1RecurrencesGet200ResponseInnerFrequencyEnum> get values =>
      _$v1RecurrencesGet200ResponseInnerFrequencyEnumValues;
  static V1RecurrencesGet200ResponseInnerFrequencyEnum valueOf(String name) =>
      _$v1RecurrencesGet200ResponseInnerFrequencyEnumValueOf(name);
}
