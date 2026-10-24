//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'recurrence.g.dart';

/// Recurrence
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
abstract class Recurrence implements Built<Recurrence, RecurrenceBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'amount')
  int get amount;

  @BuiltValueField(wireName: r'categoryId')
  String get categoryId;

  @BuiltValueField(wireName: r'frequency')
  RecurrenceFrequencyEnum get frequency;
  // enum frequencyEnum {  monthly,  yearly,  };

  @BuiltValueField(wireName: r'dayOfMonth')
  int get dayOfMonth;

  @BuiltValueField(wireName: r'monthOfYear')
  int? get monthOfYear;

  @BuiltValueField(wireName: r'startDate')
  String get startDate;

  @BuiltValueField(wireName: r'endDate')
  String? get endDate;

  Recurrence._();

  factory Recurrence([void updates(RecurrenceBuilder b)]) = _$Recurrence;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RecurrenceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Recurrence> get serializer => _$RecurrenceSerializer();
}

class _$RecurrenceSerializer implements PrimitiveSerializer<Recurrence> {
  @override
  final Iterable<Type> types = const [Recurrence, _$Recurrence];

  @override
  final String wireName = r'Recurrence';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Recurrence object, {
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
      specifiedType: const FullType(RecurrenceFrequencyEnum),
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
    Recurrence object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RecurrenceBuilder result,
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
            specifiedType: const FullType(RecurrenceFrequencyEnum),
          ) as RecurrenceFrequencyEnum;
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
  Recurrence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RecurrenceBuilder();
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

class RecurrenceFrequencyEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'monthly')
  static const RecurrenceFrequencyEnum monthly = _$recurrenceFrequencyEnum_monthly;
  @BuiltValueEnumConst(wireName: r'yearly')
  static const RecurrenceFrequencyEnum yearly = _$recurrenceFrequencyEnum_yearly;

  static Serializer<RecurrenceFrequencyEnum> get serializer => _$recurrenceFrequencyEnumSerializer;

  const RecurrenceFrequencyEnum._(String name) : super(name);

  static BuiltSet<RecurrenceFrequencyEnum> get values => _$recurrenceFrequencyEnumValues;
  static RecurrenceFrequencyEnum valueOf(String name) => _$recurrenceFrequencyEnumValueOf(name);
}
