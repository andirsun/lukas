//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_recurrence.g.dart';

/// CreateRecurrence
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
abstract class CreateRecurrence implements Built<CreateRecurrence, CreateRecurrenceBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'frequency')
  CreateRecurrenceFrequencyEnum get frequency;
  // enum frequencyEnum {  monthly,  yearly,  };

  @BuiltValueField(wireName: r'dayOfMonth')
  int get dayOfMonth;

  @BuiltValueField(wireName: r'monthOfYear')
  int? get monthOfYear;

  @BuiltValueField(wireName: r'startDate')
  String get startDate;

  @BuiltValueField(wireName: r'endDate')
  String? get endDate;

  CreateRecurrence._();

  factory CreateRecurrence([void updates(CreateRecurrenceBuilder b)]) = _$CreateRecurrence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateRecurrenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateRecurrence> get serializer => _$CreateRecurrenceSerializer();
}

class _$CreateRecurrenceSerializer implements PrimitiveSerializer<CreateRecurrence> {
  @override
  final Iterable<Type> types = const [CreateRecurrence, _$CreateRecurrence];

  @override
  final String wireName = r'CreateRecurrence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateRecurrence object, {
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
      specifiedType: const FullType(CreateRecurrenceFrequencyEnum),
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
    CreateRecurrence object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateRecurrenceBuilder result,
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
            specifiedType: const FullType(CreateRecurrenceFrequencyEnum),
          ) as CreateRecurrenceFrequencyEnum;
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
  CreateRecurrence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateRecurrenceBuilder();
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

class CreateRecurrenceFrequencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'monthly')
  static const CreateRecurrenceFrequencyEnum monthly = _$createRecurrenceFrequencyEnum_monthly;
  @BuiltValueEnumConst(wireName: r'yearly')
  static const CreateRecurrenceFrequencyEnum yearly = _$createRecurrenceFrequencyEnum_yearly;

  static Serializer<CreateRecurrenceFrequencyEnum> get serializer =>
      _$createRecurrenceFrequencyEnumSerializer;

  const CreateRecurrenceFrequencyEnum._(String name) : super(name);

  static BuiltSet<CreateRecurrenceFrequencyEnum> get values =>
      _$createRecurrenceFrequencyEnumValues;
  static CreateRecurrenceFrequencyEnum valueOf(String name) =>
      _$createRecurrenceFrequencyEnumValueOf(name);
}
