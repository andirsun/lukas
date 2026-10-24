//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_recurrence.g.dart';

/// UpdateRecurrence
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
abstract class UpdateRecurrence implements Built<UpdateRecurrence, UpdateRecurrenceBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'amount')
  int? get amount;

  @BuiltValueField(wireName: r'categoryId')
  String? get categoryId;

  @BuiltValueField(wireName: r'frequency')
  UpdateRecurrenceFrequencyEnum? get frequency;
  // enum frequencyEnum {  monthly,  yearly,  };

  @BuiltValueField(wireName: r'dayOfMonth')
  int? get dayOfMonth;

  @BuiltValueField(wireName: r'monthOfYear')
  int? get monthOfYear;

  @BuiltValueField(wireName: r'startDate')
  String? get startDate;

  @BuiltValueField(wireName: r'endDate')
  String? get endDate;

  UpdateRecurrence._();

  factory UpdateRecurrence([void updates(UpdateRecurrenceBuilder b)]) = _$UpdateRecurrence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateRecurrenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateRecurrence> get serializer => _$UpdateRecurrenceSerializer();
}

class _$UpdateRecurrenceSerializer implements PrimitiveSerializer<UpdateRecurrence> {
  @override
  final Iterable<Type> types = const [UpdateRecurrence, _$UpdateRecurrence];

  @override
  final String wireName = r'UpdateRecurrence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateRecurrence object, {
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
        specifiedType: const FullType(UpdateRecurrenceFrequencyEnum),
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
    UpdateRecurrence object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateRecurrenceBuilder result,
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
            specifiedType: const FullType.nullable(UpdateRecurrenceFrequencyEnum),
          ) as UpdateRecurrenceFrequencyEnum?;
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
  UpdateRecurrence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateRecurrenceBuilder();
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

class UpdateRecurrenceFrequencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'monthly')
  static const UpdateRecurrenceFrequencyEnum monthly = _$updateRecurrenceFrequencyEnum_monthly;
  @BuiltValueEnumConst(wireName: r'yearly')
  static const UpdateRecurrenceFrequencyEnum yearly = _$updateRecurrenceFrequencyEnum_yearly;

  static Serializer<UpdateRecurrenceFrequencyEnum> get serializer =>
      _$updateRecurrenceFrequencyEnumSerializer;

  const UpdateRecurrenceFrequencyEnum._(String name) : super(name);

  static BuiltSet<UpdateRecurrenceFrequencyEnum> get values =>
      _$updateRecurrenceFrequencyEnumValues;
  static UpdateRecurrenceFrequencyEnum valueOf(String name) =>
      _$updateRecurrenceFrequencyEnumValueOf(name);
}
